import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/screens/ENG/workout/workout_progress.dart';
import 'package:fitlek1/services/workout_service.dart';

void main() {
  testWidgets(
      'history and copied summary preserve bodyweight, timed load, cardio and fractional effort',
      (tester) async {
    tester.view.physicalSize = const Size(396, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture', 'userId': 42, 'role': 'client'});
    WorkoutService.preferences = {'unit': 'lb'};
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = call.arguments['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final types = ['reps', 'timed', 'cardio'];
    final names = ['Push-up', 'Loaded carry', 'Treadmill'];
    final exercises = [
      for (var i = 0; i < 3; i++)
        {
          'id': 10 + i,
          'exerciseID': i + 1,
          'name': names[i],
          'exerciseType': types[i],
          'isBodyweight': i == 0,
          'targetSets': 1,
          'targetReps': 12,
          'targetDurationSeconds': 60,
          'targetWeight': 10,
          'configuration': {'speedKmh': 6}
        }
    ];
    final sets = [
      {
        'id': 1,
        'workoutExerciseID': 10,
        'setNumber': 1,
        'exerciseType': 'reps',
        'reps': 12,
        'weight': 0,
        'rir': 1.5
      },
      {
        'id': 2,
        'workoutExerciseID': 11,
        'setNumber': 1,
        'exerciseType': 'timed',
        'durationSeconds': 60,
        'weight': 10
      },
      {
        'id': 3,
        'workoutExerciseID': 12,
        'setNumber': 1,
        'exerciseType': 'cardio',
        'durationSeconds': 600,
        'details': {'distanceMeters': 1000}
      },
    ];
    final client = MockClient((request) async => http.Response(
        jsonEncode(request.url.path.endsWith('/media')
            ? {'data': [], 'canUpload': false}
            : {
                'id': 7,
                'status': 'completed',
                'planName': 'Personal',
                'dayName': 'Mixed modes',
                'startedAt': '2026-10-01T10:00:00Z',
                'durationSeconds': 720,
                'summary': {'setCount': 3, 'volume': 0},
                'prescription': {'exercises': exercises},
                'sets': sets
              }),
        200));
    await http.runWithClient(() async {
      await tester.pumpWidget(
          const MaterialApp(home: WorkoutHistoryDetail(sessionID: 7)));
      await tester.pumpAndSettle();
      expect(find.text('12 reps · RIR 1.5'), findsOneWidget);
      expect(find.text('60 sec · 22.0 lb'), findsOneWidget);
      expect(find.text('600 sec · 1 km · 6 km/h'), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy workout summary'));
      await tester.pumpAndSettle();
      expect(copied, contains('Loaded carry\nSet 1: 60 sec · 22.0 lb'));
      expect(copied, contains('Treadmill\nSet 1: 600 sec · 1 km · 6 km/h'));
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
