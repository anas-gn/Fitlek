import 'locale_service.dart';
import '../models/workout.dart';
import 'apiService.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutApiException implements Exception {
  final String code;
  final int status;
  const WorkoutApiException(this.code, this.status);
}

// All requests go through the existing SIRVYA token, timeout and response handling.
class WorkoutService {
  static Map<String, dynamic> preferences = {};
  static String get unit => preferences['unit'] == 'lb' ? 'lb' : 'kg';
  static double displayWeight(num value) =>
      unit == 'lb' ? value / 0.45359237 : value.toDouble();
  static double storedWeight(num value) =>
      unit == 'lb' ? value * 0.45359237 : value.toDouble();
  static const root = '/workout';
  static Future<void>? _cacheTail;

  // Bounded read cache; active workout drafts/outbox have separate durable storage.
  static Future<void> _cache(SharedPreferences prefs, String prefix, String key,
      Map<String, dynamic> result) {
    final task = (_cacheTail ?? Future<void>.value()).then((_) async {
      final encoded = jsonEncode(result);
      final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
      await prefs.remove(key);
      keys.remove(key);
      while (keys.length >= 32) {
        await prefs.remove(keys.removeAt(0));
      }
      if (utf8.encode(encoded).length <= 65536) {
        await prefs.setString(key, encoded);
      }
    });
    late final Future<void> tail;
    tail = task.catchError((_) {}).whenComplete(() {
      if (identical(_cacheTail, tail)) _cacheTail = null;
    });
    _cacheTail = tail;
    return tail;
  }

  static Map<String, dynamic> checked(Map<String, dynamic> result) {
    if (result['ok'] != true) {
      throw WorkoutApiException('${result['message'] ?? 'workout_error'}',
          workoutInt(result['status']));
    }
    return result;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    if (RegExp(r'^/exercises/\d+$').hasMatch(path)) {
      path += '?language=${LocaleService.instance.locale.languageCode}';
    }
    final user = await ApiService.getUserData();
    final token = await ApiService.getToken();
    final prefix = 'sirvya_workout_${user?['id']}_cache_';
    final key =
        user == null || path.endsWith('/ticket') ? null : '$prefix$path';
    final prefs = key == null ? null : await SharedPreferences.getInstance();
    Future<void> verifyAccount() async {
      if ((await ApiService.getUserData())?['id'] != user?['id'] ||
          await ApiService.getToken() != token ||
          key != null && (token == null || token.isEmpty)) {
        throw const WorkoutApiException('authentication_expired', 401);
      }
    }

    try {
      final result = checked(await ApiService.get('$root$path'));
      await verifyAccount();
      if (key != null) await _cache(prefs!, prefix, key, result);
      await verifyAccount();
      return result;
    } on WorkoutApiException catch (e) {
      await verifyAccount();
      final saved = key == null ? null : prefs?.getString(key);
      if ((e.status == 0 || e.status >= 500) && saved != null) {
        try {
          return {
            ...Map<String, dynamic>.from(jsonDecode(saved)),
            'offline': true
          };
        } on FormatException {
          await prefs?.remove(key!);
        }
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> post(
          String path, Map<String, dynamic> body) async =>
      checked(await ApiService.post('$root$path', body));
  static Future<Map<String, dynamic>> put(
          String path, Map<String, dynamic> body) async =>
      checked(await ApiService.put('$root$path', body));
  static Future<void> archive(int id) async =>
      checked(await ApiService.delete('$root/plans/$id'));
  static Future<List<WorkoutPlan>> plans({int? clientID}) async => workoutRows(
          (await get('/plans${clientID == null ? '' : '?clientID=$clientID'}'))[
              'data'])
      .map(WorkoutPlan.fromJson)
      .toList();
  static Future<WorkoutSession> session(int id) async =>
      WorkoutSession.fromJson(await get('/sessions/$id'));
}
