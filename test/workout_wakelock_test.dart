import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:fitlek1/screens/ENG/workout/active_workout.dart';
import 'package:fitlek1/services/workout_service.dart';

class RecordingWakeLock extends WakelockPlusWindowsPlugin {
  final calls = <bool>[];
  @override
  bool get isMock => true;
  @override
  Future<void> toggle({required bool enable}) async => calls.add(enable);
  @override
  Future<bool> get enabled async => calls.isNotEmpty && calls.last;
}

void main() {
  final original = wakelockPlusPlatformInstance;
  late RecordingWakeLock wake;
  final instant = DateTime.utc(2024, 1, 1, 12);
  setUp(() {
    wake = RecordingWakeLock();
    wakelockPlusPlatformInstance = wake;
    SharedPreferences.setMockInitialValues({'token': 'wake-test-fixture'});
    WorkoutService.preferences = {'view': 'cards', 'keepAwake': true};
  });
  tearDown(() {
    wakelockPlusPlatformInstance = original;
    WorkoutService.preferences = {};
  });

  final session = {
    'id': 7,
    'status': 'active',
    'startedAt':
        instant.subtract(const Duration(minutes: 15)).toIso8601String(),
    'prescription': {
      'dayName': 'Wake test',
      'exercises': [
        {
          'id': 10,
          'exerciseID': 1,
          'name': 'Bench',
          'exerciseType': 'reps',
          'targetSets': 1,
          'targetReps': 10,
          'targetWeight': 60,
          'restSeconds': 0
        }
      ]
    },
    'sets': [
      {
        'workoutExerciseID': 10,
        'exerciseID': 1,
        'setNumber': 1,
        'reps': 10,
        'weight': 60
      }
    ],
    'previous': {},
  };
  final client = MockClient((request) async => http.Response(
      jsonEncode(request.method == 'GET'
          ? session
          : {
              'durationSeconds': 900,
              'volume': 600,
              'setCount': 1,
              'newPRs': 0
            }),
      200));

  testWidgets(
      'screen awake is released before the completion summary is dismissed',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: ActiveWorkoutScreen(sessionID: 7, clock: () => instant)));
      await tester.pumpAndSettle();
      expect(wake.calls, [true]);
      await tester.ensureVisible(find.text('Finish workout').last);
      await tester.tap(find.text('Finish workout').last);
      await tester.pumpAndSettle();
      expect(find.text('Workout complete!'), findsOneWidget);
      expect(wake.calls, [true, false]);
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });

  testWidgets(
      'leaving releases an owned wake lock even after the preference changes',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: ActiveWorkoutScreen(sessionID: 7, clock: () => instant)));
      await tester.pumpAndSettle();
      WorkoutService.preferences = {'keepAwake': false};
      await tester.pumpWidget(const SizedBox());
      expect(wake.calls, [true, false]);
    }, () => client);
  });
}
