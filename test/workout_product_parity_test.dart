import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/screens/ENG/workout/active_workout.dart';
import 'package:fitlek1/screens/ENG/workout/workout_bodyweight.dart';
import 'package:fitlek1/screens/ENG/workout/workout_charts.dart';
import 'package:fitlek1/screens/ENG/workout/workout_builder.dart';
import 'package:fitlek1/screens/ENG/workout/workout_check_in.dart';

WorkoutExercise prescription(
        {int id = 10, int sets = 3, bool timed = false, String group = ''}) =>
    WorkoutExercise.fromJson({
      'id': id,
      'exerciseID': id,
      'name': timed ? 'Plank' : 'Bench press',
      'muscleGroup': 'chest',
      'equipment': 'barbell',
      'exerciseType': timed ? 'timed' : 'reps',
      'isBodyweight': timed,
      'targetSets': sets,
      'targetWeight': timed ? 0 : 60,
      'targetReps': timed ? null : 10,
      'targetDurationSeconds': timed ? 2 : null,
      'restSeconds': 90,
      'supersetGroup': group
    });

void main() {
  test(
      'personal reorder swaps one exercise and repairs separated superset links',
      () {
    final slots = [
      prescription(id: 1, group: 'a'),
      prescription(id: 2, group: 'a'),
      prescription(id: 3, group: 'b'),
      prescription(id: 4, group: 'b'),
    ];
    moveWorkoutExercise(slots, 1, -1);
    expect(slots.map((e) => e.id), [2, 1, 3, 4]);
    expect(slots.map((e) => e.supersetGroup), ['a', 'a', 'b', 'b']);
    moveWorkoutExercise(slots, 1, 1);
    expect(slots.map((e) => e.id), [2, 3, 1, 4]);
    expect(slots.every((e) => e.supersetGroup.isEmpty), true);
    moveWorkoutExercise(slots, 0, -1);
    expect(slots.map((e) => e.id), [2, 3, 1, 4]);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'token': 'workout-parity-fixture-token-long-enough'});
    WorkoutService.preferences = {'view': 'cards', 'automaticRest': true};
  });
  testWidgets('legacy saved guided default opens the focused set grid',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WorkoutService.preferences = {
      'view': 'guided',
      'unit': 'lb',
      'keepAwake': false
    };
    expect(WorkoutService.preferences['unit'], 'lb');
    expect(WorkoutService.preferences['keepAwake'], false);
    final session = {
      'id': 7,
      'status': 'active',
      'startedAt': DateTime.now().toIso8601String(),
      'prescription': {
        'dayName': 'Legacy routine',
        'exercises': [
          {...prescription().toJson(), 'name': 'Bench', 'exerciseType': 'reps'}
        ]
      },
      'sets': [],
      'previous': {},
    };
    final client =
        MockClient((req) async => http.Response(jsonEncode(session), 200));
    await http.runWithClient(() async {
      await tester.pumpWidget(
          const MaterialApp(home: ActiveWorkoutScreen(sessionID: 7)));
      await tester.pumpAndSettle();
      for (final number in [1, 2, 3]) {
        expect(find.byKey(ValueKey('10:$number')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
    WorkoutService.preferences = {'view': 'guided', 'viewVersion': 2};
    expect(WorkoutService.preferences['view'], 'guided');
    WorkoutService.preferences = {};
    expect(WorkoutService.preferences, isEmpty);
  });
  testWidgets(
      'personal routine autosave keeps IDs and revisions, and a failed save remains retryable',
      (tester) async {
    final writes = <Map<String, dynamic>>[];
    var failNext = true;
    final plan = WorkoutPlan.fromJson({
      'id': 2,
      'revision': 1,
      'name': 'Routine',
      'status': 'assigned',
      'clientID': 42,
      'days': [
        {
          'id': 3,
          'name': 'Routine',
          'exercises': [
            {
              ...prescription(id: 11).toJson(),
              'exerciseType': 'reps',
              'name': 'Press'
            },
            {
              ...prescription(id: 12).toJson(),
              'exerciseType': 'reps',
              'name': 'Row'
            }
          ]
        }
      ]
    });
    final client = MockClient((req) async {
      expect(req.method, 'PUT');
      expect(req.url.path.endsWith('/plans/2'), true);
      final body = Map<String, dynamic>.from(jsonDecode(req.body));
      writes.add(body);
      if (failNext) {
        failNext = false;
        return http.Response('{"message":"plan_changed"}', 409);
      }
      return http.Response(
          jsonEncode({
            'id': 2,
            'revision': body['revision'] + 1,
            'dayIDs': [3],
            'exerciseIDs': (body['days'][0]['exercises'] as List)
                .map((e) => e['id'])
                .toList()
          }),
          200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: WorkoutBuilderScreen(
              personal: true, plan: plan, initialDayID: 3)));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextFormField).first, 'Edited routine');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(writes.length, 1);
      expect(writes.first['revision'], 1);
      await tester.scrollUntilVisible(find.text('Retry'), 400,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(writes.length, 2);
      expect(writes.last['revision'], 1);
      expect(writes.last['days'][0]['id'], 3);
      expect(writes.last['days'][0]['name'], 'Edited routine');
      expect(find.text('All changes saved'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Press'), -400,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Press'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove exercise'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(writes.last['revision'], 2);
      expect(writes.last['days'][0]['exercises'].length, 1);
      expect(writes.last['days'][0]['exercises'][0]['id'], 12);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
  test(
      'previous positional set falls back to the last actual set, and confirmed load overrides it',
      () {
    final e = prescription();
    final previous = [
      WorkoutSet.fromJson(
          {'workoutExerciseID': 99, 'setNumber': 1, 'weight': 65, 'reps': 11}),
      WorkoutSet.fromJson(
          {'workoutExerciseID': 99, 'setNumber': 2, 'weight': 62.5, 'reps': 9})
    ];
    final last = workoutPreviousSet(e, previous, 3);
    expect(last!.setNumber, 2);
    expect(WorkoutSetPrefill(e, previous: last).weight, 62.5);
    expect(WorkoutSetPrefill(e, previous: last).reps, 9);
    final confirmed = WorkoutExercise(
        exercise: e.exercise, workingWeight: 70, weight: 60, reps: 10);
    expect(WorkoutSetPrefill(confirmed, previous: last).weight, 70);
    expect(workoutPreviousSet(prescription(timed: true), previous, 1), isNull);
    expect(
        workoutPreviousSet(
            prescription(timed: true),
            [
              WorkoutSet.fromJson({
                'workoutExerciseID': 99,
                'setNumber': 1,
                'durationSeconds': 600,
                'exerciseType': 'cardio'
              })
            ],
            1),
        isNull);
  });
  test(
      'bodyweight readings are chronological and goal movement works in either direction',
      () {
    final rows = workoutWeightReadings([
      {'weight': 80, 'recordedAt': '2026-10-04'},
      {'weight': 82, 'recordedAt': '2026-09-01'},
      {'weight': 79, 'recordedAt': 'invalid'}
    ]);
    expect(rows.map((r) => r['weight']).toList(), [82, 80]);
    expect(
        workoutWeightReadings([
          {'id': 1, 'weight': 82, 'recordedAt': '2026-10-04'},
          {'id': 2, 'weight': 80, 'recordedAt': '2026-10-04'}
        ]).single['weight'],
        80);
    expect(workoutWeightMovesTowardGoal(82, 80, 75), true);
    expect(workoutWeightMovesTowardGoal(82, 80, 85), false);
    expect(workoutWeightMovesTowardGoal(82, 80, null), isNull);
    expect(workoutWeightMovesTowardGoal(82, 82, 75), isNull);
  });
  testWidgets(
      'check-in updates today in place and distinguishes cancel from explicit skip',
      (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final writes = <http.Request>[];
    final results = <bool?>[];
    final client = MockClient((req) async {
      writes.add(req);
      return http.Response('{"message":"Weight updated"}', 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        results.add(await workoutBodyweightCheckIn(context,
                            current: 80,
                            starting: true,
                            readings: [
                              {
                                'id': 8,
                                'recordedAt': DateTime.now()
                                    .toIso8601String()
                                    .substring(0, 10),
                                'weight': 80
                              }
                            ]));
                      },
                      child: const Text('Check in'))))));
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, '+0.5'));
      await tester.pump();
      await tester.ensureVisible(find.text('Save & start workout'));
      await tester.tap(find.text('Save & start workout'));
      await tester.pumpAndSettle();
      expect(writes.single.method, 'PUT');
      expect(writes.single.url.path.endsWith('/weight-history/8'), true);
      expect(jsonDecode(writes.single.body)['weight'], 80.5);
      expect(results, [true]);
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choose a different workout'));
      await tester.tap(find.text('Choose a different workout'));
      await tester.pumpAndSettle();
      expect(results, [true, null]);
      expect(writes.length, 1);
      await tester.tap(find.text('Check in'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start without weighing in'));
      await tester.tap(find.text('Start without weighing in'));
      await tester.pumpAndSettle();
      expect(results, [true, null, false]);
      expect(writes.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
  testWidgets(
      'dated chart sorts points, inspects a single record and handles empty data',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WorkoutLineChart(
                values: const [176],
                dates: [DateTime(2026, 10, 4)],
                goal: 170,
                unit: 'lb',
                label: 'Body weight'))));
    await tester.tap(find.byType(CustomPaint).last);
    await tester.pump();
    expect(find.textContaining('176 lb'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: WorkoutLineChart(values: [], label: 'Empty'))));
    expect(find.text('No data for this period.'), findsOneWidget);
  });
  testWidgets(
      'timed deadline automatically records the target, stops rest and offers completion',
      (tester) async {
    var now = DateTime.utc(2026, 10, 4, 12);
    final e = prescription(timed: true, sets: 1);
    final session = <String, dynamic>{
      'id': 7,
      'status': 'active',
      'startedAt': now.toIso8601String(),
      'prescription': {
        'dayName': 'Core',
        'planName': 'Training',
        'exercises': [
          {
            ...e.toJson(),
            'name': 'Plank',
            'exerciseType': 'timed',
            'isBodyweight': true
          }
        ]
      },
      'sets': <Map<String, dynamic>>[],
      'previous': {}
    };
    final writes = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      if (req.method == 'PUT') {
        final body = Map<String, dynamic>.from(jsonDecode(req.body));
        writes.add(body);
        session['sets'] = [
          {...body, 'id': 1}
        ];
        return http.Response('{"saved":true}', 200);
      }
      return http.Response(jsonEncode(session), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: ActiveWorkoutScreen(sessionID: 7, clock: () => now)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Start set'));
      await tester.tap(find.byTooltip('Start set'));
      await tester.pump();
      expect(find.text('00:02'), findsOneWidget);
      now = now.add(const Duration(seconds: 20));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(writes.length, 1);
      expect(writes.single['durationSeconds'], 2);
      expect(writes.single['reps'], isNull);
      expect(find.text('That’s the whole workout!'), findsOneWidget);
      expect(find.text('Rest'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
  testWidgets('timed Done before the deadline records real elapsed seconds',
      (tester) async {
    var now = DateTime.utc(2026, 10, 4, 12);
    final e = prescription(timed: true, sets: 1);
    e.durationSeconds = 45;
    final session = {
      'id': 7,
      'status': 'active',
      'startedAt': now.toIso8601String(),
      'prescription': {
        'dayName': 'Hold',
        'exercises': [
          {
            ...e.toJson(),
            'name': 'Plank',
            'exerciseType': 'timed',
            'isBodyweight': true
          }
        ]
      },
      'sets': <Map<String, dynamic>>[],
      'previous': {}
    };
    final writes = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      if (req.method == 'PUT') {
        final row = Map<String, dynamic>.from(jsonDecode(req.body));
        writes.add(row);
        session['sets'] = [
          {...row, 'id': 1}
        ];
        return http.Response('{"saved":true}', 200);
      }
      return http.Response(jsonEncode(session), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: ActiveWorkoutScreen(sessionID: 7, clock: () => now)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Start set'));
      await tester.tap(find.byTooltip('Start set'));
      await tester.pump();
      now = now.add(const Duration(seconds: 17));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(writes.single['durationSeconds'], 17);
      expect(writes.single['reps'], isNull);
      expect(find.text('Rest'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
  testWidgets(
      'focused supersets rest after the last partner, and stop rest at the unit boundary',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final slots = [
      for (final id in [10, 11, 12])
        {
          ...prescription(id: id, sets: 2, group: id == 12 ? '' : 'pair')
              .toJson(),
          'name': 'Bodyweight $id',
          'exerciseType': 'reps',
          'isBodyweight': true,
          'targetWeight': 0
        }
    ];
    final sets = <Map<String, dynamic>>[];
    final session = {
      'id': 7,
      'status': 'active',
      'startedAt': DateTime.now().toIso8601String(),
      'prescription': {'dayName': 'Pairs', 'exercises': slots},
      'sets': sets,
      'previous': {}
    };
    final client = MockClient((req) async {
      if (req.method == 'PUT' && req.url.path.endsWith('/sets')) {
        sets.add({
          ...Map<String, dynamic>.from(jsonDecode(req.body)),
          'id': sets.length + 1
        });
        return http.Response('{"saved":true}', 200);
      }
      return http.Response(jsonEncode(session), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(
          const MaterialApp(home: ActiveWorkoutScreen(sessionID: 7)));
      await tester.pumpAndSettle();
      Future<void> complete(String key) async {
        final row = find.byKey(ValueKey(key));
        var done =
            find.descendant(of: row, matching: find.byTooltip('Complete set'));
        if (done.evaluate().isEmpty) {
          await tester.scrollUntilVisible(row, 180,
              scrollable: find.byType(Scrollable).first);
          done = find.descendant(
              of: row, matching: find.byTooltip('Complete set'));
        }
        await tester.ensureVisible(done);
        await tester.tap(done);
        await tester.pumpAndSettle();
      }

      await complete('10:1');
      expect(find.text('Rest'), findsNothing);
      await complete('11:1');
      expect(find.text('Rest'), findsOneWidget);
      await complete('10:2');
      await complete('11:2');
      expect(find.text('Rest'), findsNothing);
      expect(sets.length, 4);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
  testWidgets('canceling a timed set records no performance', (tester) async {
    final e = prescription(timed: true, sets: 1);
    final session = {
      'id': 7,
      'status': 'active',
      'startedAt': DateTime.now().toIso8601String(),
      'prescription': {
        'dayName': 'Core',
        'exercises': [
          {
            ...e.toJson(),
            'name': 'Hold',
            'exerciseType': 'timed',
            'isBodyweight': true
          }
        ]
      },
      'sets': [],
      'previous': {}
    };
    var writes = 0;
    final client = MockClient((req) async {
      if (req.method == 'PUT') writes++;
      return http.Response(jsonEncode(session), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(
          const MaterialApp(home: ActiveWorkoutScreen(sessionID: 7)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Start set'));
      await tester.tap(find.byTooltip('Start set'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.text('00:02'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
}
