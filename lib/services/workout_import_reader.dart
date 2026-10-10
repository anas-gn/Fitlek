import 'dart:convert';
import 'workout_service.dart';

const workoutImportByteLimit = 8 * 1024 * 1024;
const workoutHealthByteLimit = 256 * 1024 * 1024;

/// Scan Health exports in bounded chunks, retaining only body-mass records.
/// DTDs are never interpreted, entities never expanded and URLs never fetched.
Future<String> readWorkoutImport(Stream<List<int>> stream,
    {bool healthXML = false}) async {
  var received = 0;
  Stream<List<int>> chunks() async* {
    await for (final chunk in stream) {
      received += chunk.length;
      if (received >
          (healthXML ? workoutHealthByteLimit : workoutImportByteLimit)) {
        throw const WorkoutApiException('import_too_large', 413);
      }
      for (var start = 0; start < chunk.length; start += 32768) {
        yield chunk.sublist(start, (start + 32768).clamp(0, chunk.length));
      }
    }
  }

  final bounded = chunks();
  if (!healthXML) return utf8.decoder.bind(bounded).join();
  final retained = StringBuffer('<HealthData>');
  var pending = '', safetyTail = '', outputBytes = 0;
  var opened = false, closed = false;
  final massType = RegExp(
      r'''\btype\s*=\s*(?:"HKQuantityTypeIdentifierBodyMass"|'HKQuantityTypeIdentifierBodyMass')''');
  await for (final chunk in utf8.decoder.bind(bounded)) {
    final safety = safetyTail + chunk;
    if (safety.toUpperCase().contains('<!ENTITY')) {
      throw const WorkoutApiException('invalid_import', 400);
    }
    safetyTail = safety.substring(safety.length > 16 ? safety.length - 16 : 0);
    pending += chunk;
    while (true) {
      final start = pending.indexOf('<');
      if (start < 0) {
        pending = '';
        break;
      }
      final end = pending.indexOf('>', start);
      if (end < 0) {
        pending = pending.substring(start);
        if (pending.length > 64 * 1024) {
          throw const WorkoutApiException('invalid_import', 400);
        }
        break;
      }
      final tag = pending.substring(start, end + 1);
      pending = pending.substring(end + 1);
      if (RegExp(r'^<HealthData\b').hasMatch(tag)) opened = true;
      if (RegExp(r'^</HealthData\s*>$').hasMatch(tag)) closed = true;
      if (RegExp(r'^<Record\b').hasMatch(tag) && massType.hasMatch(tag)) {
        if (!opened || closed) {
          throw const WorkoutApiException('invalid_import', 400);
        }
        outputBytes += utf8.encode(tag).length;
        if (outputBytes > workoutImportByteLimit - 32) {
          throw const WorkoutApiException('import_too_large', 413);
        }
        retained.write(
            tag.endsWith('/>') ? tag : '${tag.substring(0, tag.length - 1)}/>');
      }
    }
  }
  if (!opened || !closed || pending.trim().isNotEmpty) {
    throw const WorkoutApiException('invalid_import', 400);
  }
  retained.write('</HealthData>');
  return retained.toString();
}
