import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'workout.dart';

class WorkoutDemonstration {
  final String name, license, licenseUrl;
  final List<Map<String, dynamic>> frames;
  WorkoutDemonstration(Map<String, dynamic> value)
      : name = value['name'] as String,
        license = value['license'] as String,
        licenseUrl = value['licenseUrl'] as String,
        frames = List.unmodifiable(workoutRows(value['frames']));
}

class WorkoutDemonstrationCatalog {
  static Future<Map<String, WorkoutDemonstration>>? _catalog;
  static Map<String, WorkoutDemonstration>? _ready;
  static bool _licensesRegistered = false;
  static Future<Map<String, WorkoutDemonstration>> _load() async {
    final manifest = jsonDecode(await rootBundle.loadString(
        'assets/workout/demonstrations/catalog.json')) as Map<String, dynamic>;
    final catalog = <String, WorkoutDemonstration>{};
    for (final value in workoutRows(manifest['demonstrations'])) {
      final demonstration = WorkoutDemonstration(value);
      for (final identity in value['targets'] as List) {
        catalog['${identity[0]}:${identity[1]}'] = demonstration;
      }
    }
    if (!_licensesRegistered) {
      _licensesRegistered = true;
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks(
            ['Everkinetic exercise illustrations (via wger)'],
            await rootBundle
                .loadString('assets/workout/demonstrations/LICENSE.txt'));
      });
    }
    return _ready = Map.unmodifiable(catalog);
  }

  static Future<WorkoutDemonstration?> forExercise(Exercise exercise) async {
    if (exercise.externalSource == null || exercise.externalId == null) {
      return null;
    }
    final identity = '${exercise.externalSource}:${exercise.externalId}';
    if (_ready != null) return _ready![identity];
    try {
      final catalog = await (_catalog ??= _load());
      return catalog[identity];
    } catch (_) {
      rethrow;
    } finally {
      _catalog = null;
    }
  }
}
