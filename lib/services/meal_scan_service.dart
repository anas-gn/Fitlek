import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'connection_recovery.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/urls.dart';

class MealScanLimitException implements Exception {
  final int dailyLimit, bonus, used;
  const MealScanLimitException(
      {required this.dailyLimit, required this.used, this.bonus = 0});
  factory MealScanLimitException.fromJson(Map<String, dynamic> data) =>
      MealScanLimitException(
          dailyLimit: (data['dailyLimit'] as num).toInt(),
          bonus: (data['bonus'] as num? ?? 0).toInt(),
          used: (data['used'] as num).toInt());
}

class MealIngredient {
  final String name;
  final String imageKey, imageUrl, preparation, quantity;
  final double grams, calories, protein, carbs, fat;
  const MealIngredient(
      {required this.name,
      this.imageKey = 'generic',
      this.imageUrl = '',
      this.preparation = 'unknown',
      this.quantity = '',
      required this.grams,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat});
  factory MealIngredient.fromJson(Map<String, dynamic> j) => MealIngredient(
      name: j['name'] as String,
      imageKey: j['image_key'] as String? ?? 'generic',
      imageUrl: j['image_url'] as String? ?? '',
      preparation: j['preparation'] as String? ?? 'unknown',
      quantity: j['quantity'] as String? ?? '',
      grams: (j['grams'] as num).toDouble(),
      calories: (j['calories'] as num).toDouble(),
      protein: (j['protein'] as num).toDouble(),
      carbs: (j['carbs'] as num).toDouble(),
      fat: (j['fat'] as num).toDouble());
  Map<String, dynamic> toJson() => {
        'name': name,
        'image_key': imageKey,
        'image_url': imageUrl,
        'preparation': preparation,
        'quantity': quantity,
        'grams': grams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat
      };
  MealIngredient withGrams(double value) => MealIngredient(
      name: name,
      imageKey: imageKey,
      imageUrl: imageUrl,
      preparation: preparation,
      quantity: '${value.round()} g',
      grams: value,
      calories: calories * value / grams,
      protein: protein * value / grams,
      carbs: carbs * value / grams,
      fat: fat * value / grams);
}

class ScannedMeal {
  final String id, name, notes, confidence;
  final DateTime createdAt;
  String mealDate, mealType;
  final double portion;
  final List<MealIngredient> ingredients;
  String photoPath;
  Uint8List? photoBytes;
  ScannedMeal(
      {required this.id,
      required this.name,
      required this.notes,
      required this.confidence,
      required this.createdAt,
      required this.portion,
      required this.ingredients,
      required this.photoPath,
      this.photoBytes,
      String? mealDate,
      this.mealType = 'lunch'})
      : mealDate = mealDate ?? dayKey(createdAt.toLocal());
  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  double total(String key) =>
      ingredients.fold(0, (sum, i) => sum + (i.toJson()[key] as num));
  Map<String, dynamic> nutritionJson() => {
        'id': id,
        'name': name,
        'notes': notes,
        'confidence': confidence,
        'createdAt': createdAt.toIso8601String(),
        'mealDate': mealDate,
        'mealType': mealType,
        'portion': portion,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
      };
  Map<String, dynamic> toJson() => {
        ...nutritionJson(),
        'photoPath': photoPath,
        if (kIsWeb && photoBytes != null)
          'photoData': base64Encode(photoBytes!),
      };
  factory ScannedMeal.fromJson(Map<String, dynamic> j) => ScannedMeal(
      id: j['id'],
      name: j['name'],
      notes: j['notes'],
      confidence: j['confidence'],
      createdAt: DateTime.parse(j['createdAt']),
      mealDate: j['mealDate'],
      mealType: j['mealType'] ?? 'lunch',
      portion: (j['portion'] as num).toDouble(),
      ingredients: (j['ingredients'] as List)
          .map((i) => MealIngredient.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      photoPath: j['photoPath'] ?? '',
      photoBytes:
          j['photoData'] is String ? base64Decode(j['photoData']) : null);
}

class MealScanService {
  static Future<ScannedMeal> analyze(
      XFile photo, String token, double portion, String notes) async {
    final bytes = await photo.readAsBytes();
    if (bytes.length > 6 * 1024 * 1024) {
      throw Exception('Choose a photo under 6 MB.');
    }
    final client = http.Client();
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/meals/analyze'))
            ..headers['Authorization'] = 'Bearer $token'
            ..fields['portion'] = '$portion'
            ..fields['notes'] = notes
            ..files.add(http.MultipartFile.fromBytes('photo', bytes,
                filename: photo.name,
                contentType: MediaType('application', 'octet-stream')));
      final response = await (() async =>
              http.Response.fromStream(await client.send(request)))()
          .timeout(const Duration(seconds: 60));
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Meal scanner is unavailable. Please try later.');
      }
      if (response.statusCode != 200) {
        if (response.statusCode == 429 &&
            data['code'] == 'MEAL_SCAN_DAILY_LIMIT' &&
            data['allowance'] is Map) {
          throw MealScanLimitException.fromJson(
              Map<String, dynamic>.from(data['allowance']));
        }
        throw Exception(response.statusCode == 401
            ? 'Your session expired. Please sign in again.'
            : data['message'] ?? 'Could not analyze this meal.');
      }
      return ScannedMeal(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: data['name'],
          notes: data['notes'],
          confidence: data['confidence'],
          createdAt: DateTime.now(),
          portion: portion,
          ingredients: (data['ingredients'] as List)
              .map((i) => MealIngredient.fromJson(Map<String, dynamic>.from(i)))
              .toList(),
          photoPath: photo.path,
          photoBytes: bytes);
    } catch (error) {
      ConnectionRecovery.report(error);
      rethrow;
    } finally {
      client.close();
    }
  }

  static String _key(int userId) => 'meal_history_v1_$userId';
  static Future<List<ScannedMeal>> history(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return [];
    final meals = (jsonDecode(raw) as List)
        .map((m) => ScannedMeal.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    await restorePhotos(userId, meals);
    return meals;
  }

  /// Reconnect photos after older logout versions lost the preference index,
  /// or after the OS changes the application's absolute documents path.
  static Future<void> restorePhotos(int userId, List<ScannedMeal> meals) async {
    if (kIsWeb || meals.isEmpty) return;
    final directory = await getApplicationDocumentsDirectory();
    for (final meal in meals) {
      if (!RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(meal.id)) continue;
      final file = File('${directory.path}/meals/$userId/${meal.id}.jpg');
      if (await file.exists()) meal.photoPath = file.path;
    }
  }

  static Future<void> save(int userId, ScannedMeal meal) async {
    if (kIsWeb) {
      final meals = await history(userId);
      meals.removeWhere((m) => m.id == meal.id);
      meals.insert(0, meal);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
          _key(userId), jsonEncode(meals.map((m) => m.toJson()).toList()))) {
        throw Exception(
            'Browser storage is full. Remove an older meal and retry.');
      }
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/meals/$userId');
    await folder.create(recursive: true);
    final savedPath = '${folder.path}/${meal.id}.jpg';
    final previousPath = meal.photoPath;
    if (previousPath.isNotEmpty && previousPath != savedPath) {
      final source = File(previousPath);
      if (await source.exists()) {
        await source.copy(savedPath);
      } else if (meal.photoBytes != null) {
        await File(savedPath).writeAsBytes(meal.photoBytes!, flush: true);
      } else {
        throw Exception(
            'Could not save the meal photo. Please choose it again.');
      }
      meal.photoPath = savedPath;
    } else if (meal.photoBytes != null && !await File(savedPath).exists()) {
      await File(savedPath).writeAsBytes(meal.photoBytes!, flush: true);
      meal.photoPath = savedPath;
    }
    final meals = await history(userId);
    meals.removeWhere((m) => m.id == meal.id);
    meals.insert(0, meal);
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(
        _key(userId), jsonEncode(meals.map((m) => m.toJson()).toList()));
    if (!success) throw Exception('Could not save the meal. Please retry.');
  }

  static Future<void> delete(int userId, ScannedMeal meal) async {
    final meals = await history(userId);
    meals.removeWhere((m) => m.id == meal.id);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
        _key(userId), jsonEncode(meals.map((m) => m.toJson()).toList()))) {
      throw Exception('Could not delete this meal.');
    }
    if (!kIsWeb) {
      final file = File(meal.photoPath);
      if (await file.exists()) await file.delete();
    }
  }
}
