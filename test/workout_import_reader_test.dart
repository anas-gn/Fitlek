import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/workout_import_reader.dart';
import 'package:fitlek1/services/workout_service.dart';

void main() {
  test(
      'large Health exports retain body mass across every byte boundary and ignore unrelated records',
      () async {
    const mass =
        '<Record type="HKQuantityTypeIdentifierBodyMass" unit="kg" value="75" startDate="2025-10-01 10:00:00 +0000"/>';
    const header =
        '<?xml version="1.0"?><!DOCTYPE HealthData [<!ELEMENT HealthData ANY>]><HealthData locale="en_GB">';
    final bytes = utf8
        .encode('$header<Record type="Steps" value="300"/>$mass</HealthData>');
    for (final split in [1, 2, 7, 16, 64, 1024]) {
      final result = await readWorkoutImport(
          Stream.fromIterable([
            for (var i = 0; i < bytes.length; i += split)
              bytes.sublist(i, (i + split).clamp(0, bytes.length)),
          ]),
          healthXML: true);
      expect(result, '<HealthData>$mass</HealthData>');
    }
    final huge = Stream<List<int>>.fromIterable([
      utf8.encode('<HealthData>'),
      for (var i = 0; i < 10; i++)
        utf8.encode('<Record type="Steps" value="1"/>' * 30000),
      utf8.encode('$mass</HealthData>'),
    ]);
    expect(await readWorkoutImport(huge, healthXML: true),
        '<HealthData>$mass</HealthData>');
  });
  test(
      'entities, truncated roots and oversize non-Health files fail before upload',
      () async {
    for (final xml in [
      '<HealthData><!ENTITY x SYSTEM "https://example.invalid"> </HealthData>',
      '<HealthData><Record',
      '<HealthData>'
    ]) {
      await expectLater(
          readWorkoutImport(
              Stream.fromIterable(utf8.encode(xml).map((v) => [v])),
              healthXML: true),
          throwsA(isA<WorkoutApiException>()));
    }
    await expectLater(
        readWorkoutImport(
            Stream.value(List.filled(workoutImportByteLimit + 1, 32))),
        throwsA(isA<WorkoutApiException>()
            .having((e) => e.code, 'code', 'import_too_large')));
    expect(await readWorkoutImport(Stream.value(utf8.encode('{"version":1}'))),
        '{"version":1}');
  });
}
