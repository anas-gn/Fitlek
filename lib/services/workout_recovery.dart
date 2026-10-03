import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'apiService.dart';
import 'workout_service.dart';

// Account-scoped cache and serialized idempotent outbox; no login credentials.
class WorkoutRecovery {
  static final Map<String, Future<void>> _tails = {};
  static Future<String> _key(int sessionID) async {
    final user = await ApiService.getUserData();
    if (user == null) {
      throw const WorkoutApiException('authentication_expired', 401);
    }
    return 'sirvya_workout_${user['id']}_$sessionID';
  }

  static Future<T> _locked<T>(
      int id, Future<T> Function(String key) action) async {
    final key = await _key(id), previous = _tails[key] ?? Future<void>.value();
    final done = Completer<void>();
    _tails[key] = done.future;
    await previous;
    try {
      await _verify(key, id);
      return await action(key);
    } finally {
      done.complete();
      if (identical(_tails[key], done.future)) _tails.remove(key);
    }
  }

  static Future<void> _verify(String key, int id) async {
    if (await _key(id) != key) {
      throw const WorkoutApiException('authentication_expired', 401);
    }
  }

  static Future<Map<String, dynamic>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final field in ['session', 'outbox', 'draft'])
        if (prefs.getString('${key}_$field') != null)
          field: jsonDecode(prefs.getString('${key}_$field')!)
    };
  }

  static Future<void> _write(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in data.entries) {
      await prefs.setString('${key}_${entry.key}', jsonEncode(entry.value));
    }
  }

  static Future<Map<String, dynamic>> read(int id) => _locked(id, _read);
  static Future<void> write(int id, Map<String, dynamic> data) =>
      _locked(id, (key) => _write(key, data));
  static Future<void> cache(int id, Map<String, dynamic> session) =>
      write(id, {'session': session});
  static Future<void> draft(int id, Map<String, dynamic> draft) =>
      write(id, {'draft': draft});
  static Future<void> save(int id, Map<String, dynamic> set) =>
      _locked(id, (key) async {
        final data = await _read(key),
            outbox = Map<String, dynamic>.from(data['outbox'] ?? {});
        outbox['${set['workoutExerciseID']}:${set['setNumber']}'] = set;
        await _write(key, {'outbox': outbox});
        try {
          await _sync(key, id);
        } on WorkoutApiException catch (e) {
          if (e.status != 0) rethrow;
        }
      });
  static Future<void> _sync(String key, int id) async {
    final data = await _read(key),
        outbox = Map<String, dynamic>.from(data['outbox'] ?? {});
    for (final entry in outbox.entries.toList()) {
      await _verify(key, id);
      final body = Map<String, dynamic>.from(entry.value);
      try {
        await WorkoutService.put('/sessions/$id/sets', body);
      } on WorkoutApiException catch (e) {
        if (e.status == 400 || e.status == 404) {
          outbox.remove(entry.key);
          await _write(key, {'outbox': outbox});
        }
        rethrow;
      }
      await _verify(key, id);
      final latest = await _read(key),
          raw = Map<String, dynamic>.from(latest['session'] ?? {});
      if (raw.isNotEmpty) {
        final sets = List<dynamic>.from(raw['sets'] ?? []);
        sets.removeWhere((s) =>
            s['workoutExerciseID'] == body['workoutExerciseID'] &&
            s['setNumber'] == body['setNumber']);
        sets.add({
          ...body,
          'workoutSessionID': id,
          'completedAt': DateTime.now().toUtc().toIso8601String()
        });
        raw['sets'] = sets;
        await _write(key, {'session': raw});
      }
      outbox.remove(entry.key);
      await _write(key, {'outbox': outbox});
    }
  }

  static Future<void> sync(int id) => _locked(id, (key) => _sync(key, id));
  static Future<Map<String, dynamic>> session(int id) =>
      _locked(id, (key) async {
        try {
          await _sync(key, id);
          final current = WorkoutService.checked(
              await ApiService.get('/workout/sessions/$id'));
          await _verify(key, id);
          await _write(key, {'session': current});
          return current;
        } on WorkoutApiException catch (e) {
          final saved = await _read(key);
          if ((e.status != 0 && e.status < 500) || saved['session'] == null) {
            rethrow;
          }
          return {
            ...Map<String, dynamic>.from(saved['session']),
            'offline': true
          };
        }
      });
  static Future<int> pending(int id) async =>
      ((await read(id))['outbox'] as Map? ?? {}).length;
}
