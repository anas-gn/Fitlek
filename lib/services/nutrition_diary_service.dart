import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/urls.dart';
import 'meal_scan_service.dart';
import 'connection_recovery.dart';

const nutritionKeys = ['calories', 'protein', 'carbs', 'fat'];
const mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
String mealTypeLabel(String value) =>
    '${value[0].toUpperCase()}${value.substring(1)}';

class NutritionDay {
  final List<ScannedMeal> meals;
  const NutritionDay(this.meals);
  double total(String key) =>
      meals.fold(0, (value, meal) => value + meal.total(key));
}

class NutritionDiaryService {
  static final _changes = StreamController<int>.broadcast();
  static Stream<int> get changes => _changes.stream;
  final int clientID;
  final String token;
  final http.Client _client;
  NutritionDiaryService(this.clientID, this.token, {http.Client? client})
      : _client = client ?? http.Client();
  void close() => _client.close();
  Map<String, String> get _headers =>
      {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  String get _syncKey => 'nutrition_synced_v1_$clientID';
  Map<String, dynamic> remoteMeal(ScannedMeal meal) {
    return meal.nutritionJson();
  }

  Future<dynamic> _request(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$baseUrl/meals/diary$path'))
      ..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await (() async =>
            http.Response.fromStream(await _client.send(request)))()
        .timeout(const Duration(seconds: 20))
        .catchError((Object error) {
      ConnectionRecovery.report(error);
      throw error;
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Could not sync your nutrition diary. Please try again.';
      try {
        message = jsonDecode(response.body)['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<void> _upload(ScannedMeal meal) async {
    await _request('PUT', '/${Uri.encodeComponent(meal.id)}', remoteMeal(meal));
    final prefs = await SharedPreferences.getInstance();
    final synced = Map<String, dynamic>.from(
        jsonDecode(prefs.getString(_syncKey) ?? '{}'));
    synced[meal.id] = jsonEncode(remoteMeal(meal));
    if (!await prefs.setString(_syncKey, jsonEncode(synced))) {
      throw Exception('Could not confirm saved meal. Please retry.');
    }
  }

  Future<void> save(ScannedMeal meal) async {
    if (meal.ingredients.isEmpty) {
      throw Exception('Add at least one ingredient before saving this meal.');
    }
    await MealScanService.save(clientID, meal);
    await _upload(meal);
    _changes.add(clientID);
  }

  Future<NutritionDay> day(DateTime date) async {
    // Also migrates old device-only meals. Stable IDs make retries idempotent.
    final local = await MealScanService.history(clientID);
    final prefs = await SharedPreferences.getInstance();
    final synced = Map<String, dynamic>.from(
        jsonDecode(prefs.getString(_syncKey) ?? '{}'));
    for (final meal in local) {
      if (synced[meal.id] != jsonEncode(remoteMeal(meal))) await _upload(meal);
    }
    final data = await _request('GET', '?date=${ScannedMeal.dayKey(date)}');
    final photos = {for (final meal in local) meal.id: meal};
    final meals = (data['meals'] as List).map((value) {
      final meal = ScannedMeal.fromJson(Map<String, dynamic>.from(value));
      meal.photoPath = photos[meal.id]?.photoPath ?? '';
      meal.photoBytes = photos[meal.id]?.photoBytes;
      return meal;
    }).toList();
    await MealScanService.restorePhotos(clientID, meals);
    return NutritionDay(meals);
  }

  Future<Map<String, double?>> goals() async {
    final data = await _request('GET', '/goals') as Map<String, dynamic>;
    return {
      for (final key in nutritionKeys) key: (data[key] as num?)?.toDouble()
    };
  }

  Future<void> saveGoals(Map<String, double?> goals) async {
    await _request('PUT', '/goals', goals);
    _changes.add(clientID);
  }

  Future<Map<String, dynamic>> goalPlan() async =>
      Map<String, dynamic>.from(await _request('GET', '/plan'));
  Future<void> savePlan(Map<String, dynamic> plan) async {
    await _request('PUT', '/plan', plan);
    _changes.add(clientID);
  }

  Future<Map<String, dynamic>> review(DateTime from, DateTime to) async =>
      Map<String, dynamic>.from(await _request('GET',
          '/plan/summary?from=${ScannedMeal.dayKey(from)}&to=${ScannedMeal.dayKey(to)}'));

  Future<void> delete(ScannedMeal meal) async {
    await _request('DELETE', '/${Uri.encodeComponent(meal.id)}');
    await MealScanService.delete(clientID, meal);
    final prefs = await SharedPreferences.getInstance();
    final synced =
        Map<String, dynamic>.from(jsonDecode(prefs.getString(_syncKey) ?? '{}'))
          ..remove(meal.id);
    await prefs.setString(_syncKey, jsonEncode(synced));
    _changes.add(clientID);
  }
}
