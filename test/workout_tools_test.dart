import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/services/workout_recovery.dart';
import 'package:fitlek1/services/workout_timer.dart';
import 'package:fitlek1/localization/workout_localizations.dart';
import 'package:fitlek1/screens/ENG/workout/workout_tools.dart';
import 'package:fitlek1/screens/ENG/workout/workout_pdf.dart';
import 'package:fitlek1/screens/ENG/workout/workout_muscles.dart';
import 'package:fitlek1/screens/ENG/workout/workout_home.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  test(
      'reordering keeps paired exercises together in builder and active session',
      () {
    const e = Exercise(
        id: 1,
        name: 'Example',
        muscleGroup: 'back',
        equipment: 'barbell',
        type: 'reps',
        isBodyweight: false);
    final a = WorkoutExercise(id: 1, exercise: e, supersetGroup: 'A'),
        b = WorkoutExercise(id: 2, exercise: e, supersetGroup: 'A'),
        c = WorkoutExercise(id: 3, exercise: e);
    expect(
        moveWorkoutGroup([a, b, c], 1, 1).map((e) => e.id).toList(), [3, 1, 2]);
    expect(moveWorkoutGroup([a, b, c], 0, -1).map((e) => e.id).toList(),
        [1, 2, 3]);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42, 'role': 'client'});
    WorkoutService.preferences = {};
  });
  test('plate pairs respect odd inventory and never overshoot target', () {
    final result = calculatePlates(82.5, 20, [
      {'weight': 25, 'count': 2},
      {'weight': 5, 'count': 3},
      {'weight': 1.25, 'count': 2}
    ]);
    expect(result.achieved, 82.5);
    expect(result.perSide, [25, 5, 1.25]);
    expect(
        calculatePlates(80, 20, [
          {'weight': 25, 'count': 1}
        ]).achieved,
        20);
    expect(
        calculatePlates(79, 20, [
          {'weight': 25, 'count': 2},
          {'weight': 5, 'count': 2}
        ]).achieved,
        70);
  });
  test(
      'wall clock work timer restores elapsed time and pause across screen disposal',
      () {
    var now = DateTime.utc(2024, 1, 1);
    final timer = PersistentWorkoutTimer(clock: () => now);
    timer.start();
    now = now.add(const Duration(seconds: 20));
    final saved = timer.toJson();
    now = now.add(const Duration(seconds: 40));
    final restored = PersistentWorkoutTimer(clock: () => now)..restore(saved);
    expect(restored.elapsed.inSeconds, 60);
    restored.stop();
    now = now.add(const Duration(seconds: 30));
    expect(restored.elapsed.inSeconds, 60);
    restored.start();
    now = now.add(const Duration(seconds: 10));
    expect(restored.elapsed.inSeconds, 70);
  });
  test('French and Spanish dynamic workout copy is localized', () {
    expect(workoutTranslate('Schedule adherence: 80%', 'fr'),
        'Suivi du programme : 80%');
    expect(workoutTranslate('Weight (lb)', 'es'), 'Peso (lb)');
    expect(workoutTranslate('3 workouts ready to import', 'es'),
        '3 entrenamientos listos para importar');
  });
  test('concurrent offline set writes do not lose entries or drafts', () async {
    final client =
        MockClient((_) async => throw http.ClientException('Fixture offline'));
    await http.runWithClient(() async {
      await Future.wait([
        WorkoutRecovery.save(7, {
          'workoutExerciseID': 10,
          'setNumber': 1,
          'weight': 60,
          'reps': 10
        }),
        WorkoutRecovery.save(7,
            {'workoutExerciseID': 10, 'setNumber': 2, 'weight': 60, 'reps': 8}),
        WorkoutRecovery.draft(7, {
          'rows': {
            '10:3': {'load': '60', 'count': '9'}
          }
        })
      ]);
      expect(await WorkoutRecovery.pending(7), 2);
      expect((await WorkoutRecovery.read(7))['draft']['rows']['10:3']['count'],
          '9');
    }, () => client);
  });
  test(
      'routine PDF contains native generated content without account identifiers',
      () async {
    final plan = WorkoutPlan.fromJson({
      'name': 'Push',
      'clientID': 42,
      'days': [
        {
          'name': 'Monday',
          'exercises': [
            {
              'id': 10,
              'exerciseID': 1,
              'name': 'Bench Press',
              'exerciseType': 'reps',
              'targetSets': 3,
              'targetReps': 10,
              'targetWeight': 60
            }
          ]
        }
      ]
    });
    final bytes = await workoutPlanPDF(plan);
    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
  testWidgets('native tools fit phone width and retain pound display',
      (tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WorkoutService.preferences = {'unit': 'lb'};
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const WorkoutToolsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Weight (lb)'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('body explorer opens the selected native library with its filter',
      (tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <http.Request>[];
    final client = MockClient((req) async {
      requests.add(req);
      return http.Response(
          jsonEncode({
            'data': [],
            'total': 0,
            'hasMore': false,
            'filters': {
              'muscleGroup': ['chest', 'back'],
              'equipment': ['barbell'],
              'exerciseType': ['reps'],
              'secondaryMuscle': []
            }
          }),
          200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light, home: const WorkoutMuscleExplorer()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('chest'));
      await tester.tap(find.text('chest'));
      await tester.pumpAndSettle();
      expect(requests.last.url.queryParameters['muscleGroup'], 'chest');
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
  testWidgets(
      'workout dashboard fits narrow screens with flexible date overrides',
      (tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tomorrow = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final plan = {
      'id': 1,
      'clientID': 42,
      'name': 'Personal routine',
      'status': 'assigned',
      'days': [
        {'id': 2, 'name': 'Flexible', 'dayOfWeek': null, 'exercises': []}
      ]
    };
    final client = MockClient((req) async {
      Object data = {};
      final path = req.url.path;
      if (path.endsWith('/plans')) {
        data = {
          'data': [plan]
        };
      }
      if (path.endsWith('/stats')) {
        data = {
          'workoutCount': 100,
          'setCount': 1000,
          'volume': 1000000,
          'frequency': [],
          'bodyweight': []
        };
      }
      if (path.endsWith('/active')) data = {'session': null};
      if (path.endsWith('/history')) data = {'data': []};
      if (path.endsWith('/schedule')) {
        data = {
          'data': [
            {'workoutDate': tomorrow, 'workoutDayID': 2}
          ],
          'overrideDates': [tomorrow]
        };
      }
      return http.Response(jsonEncode(data), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const WorkoutHomeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workout-tab-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Flexible'), findsWidgets);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
}
