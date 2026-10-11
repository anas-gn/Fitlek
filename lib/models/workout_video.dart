import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/apiService.dart';
import '../services/workout_service.dart';
import 'workout.dart';

String? workoutMediaLocation(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final location = value.trim();
  if (location.startsWith('assets/workout/')) return location;
  final uri = Uri.tryParse(location);
  if (uri == null) return null;
  if (uri.hasScheme) {
    return ['http', 'https'].contains(uri.scheme) && uri.host.isNotEmpty
        ? location
        : null;
  }
  if (location.startsWith('/') && !location.startsWith('//')) {
    return Uri.parse(ApiService.baseUrl).resolve(location).toString();
  }
  return null;
}

bool workoutPlayableMedia(String? value) {
  final location = workoutMediaLocation(value);
  return location != null &&
      RegExp(r'\.(mp4|webm|mov|gif)$', caseSensitive: false)
          .hasMatch(Uri.parse(location).path);
}

class WorkoutVideo {
  final String name, asset, poster, author, license, licenseUrl, sourceUrl;
  final String modifications;
  bool get isNetwork => Uri.parse(asset).hasScheme;
  bool get isGif => Uri.parse(asset).path.toLowerCase().endsWith('.gif');
  bool get hasCredits => author.isNotEmpty && license.isNotEmpty;
  WorkoutVideo(Map<String, dynamic> value)
      : name = value['name'] as String,
        asset = value['asset'] as String,
        poster = value['poster'] as String,
        author = value['author'] as String,
        license = value['license'] as String,
        licenseUrl = value['licenseUrl'] as String,
        sourceUrl = value['sourceUrl'] as String,
        modifications = value['modifications'] as String;

  static WorkoutVideo? fromExercise(Exercise exercise) {
    if (!workoutPlayableMedia(exercise.videoUrl)) return null;
    final media = workoutMediaLocation(exercise.videoUrl)!;
    return WorkoutVideo({
      'name': exercise.name,
      'asset': media,
      'poster': workoutMediaLocation(exercise.imageUrl) ??
          (Uri.parse(media).path.toLowerCase().endsWith('.gif') ? media : ''),
      'author': '',
      'license': '',
      'licenseUrl': '',
      'sourceUrl': media,
      'modifications': '',
    });
  }
}

class WorkoutVideoCatalog {
  static Future<Map<String, WorkoutVideo>>? _catalog;
  static bool _registered = false;
  static final Map<String, Future<WorkoutVideo?>> _pending = {};
  static Future<Map<String, WorkoutVideo>> _load() async {
    try {
      final value = jsonDecode(
              await rootBundle.loadString('assets/workout/videos/catalog.json'))
          as Map<String, dynamic>;
      final entries = <String, WorkoutVideo>{};
      final additional = jsonDecode(await rootBundle
              .loadString('assets/workout/exercise_media/catalog.json'))
          as Map<String, dynamic>;
      for (final row in [
        ...workoutRows(value['videos']),
        ...workoutRows(additional['videos']),
      ]) {
        final video = WorkoutVideo(row);
        for (final identity in row['targets'] as List) {
          entries['${identity[0]}:${identity[1]}'] = video;
        }
      }
      if (!_registered) {
        _registered = true;
        LicenseRegistry.addLicense(() async* {
          yield LicenseEntryWithLineBreaks(
              ['Goulart exercise videos (via wger)'],
              await rootBundle.loadString('assets/workout/videos/LICENSE.txt'));
          for (final entry in workoutRows(additional['licenses'])) {
            yield LicenseEntryWithLineBreaks(['${entry['name']}'],
                await rootBundle.loadString('${entry['asset']}'));
          }
        });
      }
      return Map.unmodifiable(entries);
    } catch (_) {
      _catalog = null;
      rethrow;
    }
  }

  static Future<WorkoutVideo?> localForExercise(Exercise exercise) async {
    final supplied = WorkoutVideo.fromExercise(exercise);
    if (supplied != null) return supplied;
    if (exercise.externalSource == null || exercise.externalId == null) {
      return null;
    }
    return (await (_catalog ??=
        _load()))['${exercise.externalSource}:${exercise.externalId}'];
  }

  static Future<WorkoutVideo?> forExercise(Exercise exercise,
      {bool preview = false}) async {
    final bundled = await localForExercise(exercise);
    if (bundled != null) {
      return bundled;
    }
    if (!['exercises-dataset', 'sirvya'].contains(exercise.externalSource) ||
        exercise.hasHostedMedia == false ||
        exercise.id <= 0) {
      return null;
    }
    final user = await ApiService.getUserData();
    final token = await ApiService.getToken();
    if (user == null || token == null || token.isEmpty) return null;
    final key = '${user['id']}:$token:${exercise.id}:$preview';
    final active = _pending[key];
    if (active != null) return active;
    final request = () async {
      final result = await WorkoutService.get(
          '/exercises/${exercise.id}/demonstration${preview ? '?priority=preview' : ''}',
          cache: false);
      final value = result['video'];
      if (value is! Map) return null;
      final video = WorkoutVideo(Map<String, dynamic>.from(value));
      return workoutPlayableMedia(video.asset) ? video : null;
    }();
    _pending[key] = request;
    try {
      return await request;
    } finally {
      if (identical(_pending[key], request)) _pending.remove(key);
    }
  }
}
