import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/screens/ENG/workout/active_workout.dart';
import 'package:fitlek1/screens/ENG/workout/exercise_library.dart';
import 'package:fitlek1/screens/ENG/workout/workout_builder.dart';
import 'package:fitlek1/theme/app_theme.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/screens/ENG/workout/workout_set_row.dart';

const catalogExercise = <String, dynamic>{
  'id': 1,
  'name': 'Bench Press',
  'muscleGroup': 'chest',
  'equipment': 'barbell',
  'exerciseType': 'reps',
  'isBodyweight': 0,
  'instructions': ['Press with control.']
};
Map<String, dynamic> sessionFixture({bool timed = false}) => {
      'id': 7,
      'status': 'active',
      'startedAt': '2026-10-02T10:00:00Z',
      'prescription': {
        'planName': 'My plan',
        'dayName': 'Push day',
        'exercises': [
          {
            ...catalogExercise,
            'id': 10,
            'exerciseID': 1,
            'targetSets': timed ? 1 : 2,
            'targetReps': timed ? null : 10,
            'targetWeight': 60,
            'targetDurationSeconds': timed ? 30 : null,
            'restSeconds': 90,
            'exerciseType': timed ? 'timed' : 'reps'
          }
        ]
      },
      'sets': <Map<String, dynamic>>[],
      'previous': <String, dynamic>{}
    };

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'token': 'workout-widget-test-token-long-enough'});
    WorkoutService.preferences = {'view': 'guided', 'viewVersion': 2};
  });

  test(
      'supersets alternate by round and only rest after eligible group members',
      () {
    const e = Exercise(
        id: 1,
        name: 'Exercise',
        muscleGroup: 'back',
        equipment: 'barbell',
        type: 'reps',
        isBodyweight: false);
    final a = WorkoutExercise(id: 10, exercise: e, sets: 3, supersetGroup: 'A');
    final b = WorkoutExercise(id: 11, exercise: e, sets: 2, supersetGroup: 'A');
    final c = WorkoutExercise(id: 12, exercise: e, sets: 1);
    expect(
        workoutSequence([a, b, c]).map((v) => (v.$1.id, v.$2, v.$3)).toList(), [
      (10, 1, false),
      (11, 1, true),
      (10, 2, false),
      (11, 2, true),
      (10, 3, true),
      (12, 1, true)
    ]);
  });

  testWidgets(
      'set errors retain input; retry persists once; rest timer can pause, extend and skip',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = sessionFixture();
    int attempts = 0;
    final client = MockClient((req) async {
      expect(req.headers['authorization'],
          'Bearer workout-widget-test-token-long-enough');
      if (req.method == 'PUT') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        attempts++;
        if (attempts == 1) {
          return http.Response('{"message":"workout_error"}', 500);
        }
        session['sets'] = [
          <String, dynamic>{...body, 'id': 90}
        ];
        return http.Response('{"saved":true}', 200);
      }
      return http.Response(jsonEncode(session), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: ActiveWorkoutScreen(
              sessionID: 7, clock: () => DateTime.utc(2026, 10, 10, 12))));
      await tester.pumpAndSettle();
      final weight = find.widgetWithText(TextFormField, 'Weight (kg)');
      await tester.enterText(weight, '65');
      await tester.ensureVisible(find.text('Save set'));
      await tester.tap(find.text('Save set'));
      await tester.pumpAndSettle();
      expect(attempts, 1);
      expect(find.textContaining('Unable to save or load'), findsOneWidget);
      expect(tester.widget<TextFormField>(weight).controller!.text, '65');
      await tester.tap(find.text('Save set'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(attempts, 2);
      expect(find.text('1 / 2 sets saved'), findsOneWidget);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(find.byTooltip('Resume'), findsOneWidget);
      await tester.tap(find.widgetWithIcon(TextButton, Icons.add).last);
      await tester.pump();
      await tester.tap(find.widgetWithIcon(TextButton, Icons.add).last);
      await tester.pump();
      expect(find.text('02:00'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(find.text('Rest'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });

  testWidgets(
      'timed work records actual elapsed time without a repetition field',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = sessionFixture(timed: true);
    Map<String, dynamic>? recorded;
    var now = DateTime.utc(2026, 10, 4, 10);
    final client = MockClient((req) async {
      if (req.method == 'PUT') {
        recorded = jsonDecode(req.body);
        session['sets'] = [
          {...recorded!, 'id': 1}
        ];
        return http.Response('{"saved":true}', 200);
      }
      return http.Response(jsonEncode(session), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: ActiveWorkoutScreen(sessionID: 7, clock: () => now)));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Repetitions'), findsNothing);
      await tester.tap(find.text('Start set'));
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(recorded?['durationSeconds'], 2);
      expect(recorded?['reps'], isNull);
      expect(find.text('That’s the whole workout!'), findsOneWidget);
      expect(find.text('Rest'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });

  testWidgets(
      'library search and filtering use native detail instructions on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final searches = <Uri>[];
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/exercises/1')) {
        return http.Response(jsonEncode(catalogExercise), 200);
      }
      searches.add(req.url);
      return http.Response(
          jsonEncode({
            'data': [catalogExercise],
            'hasMore': false,
            'filters': {
              'muscleGroup': ['chest'],
              'equipment': ['barbell'],
              'exerciseType': ['reps']
            }
          }),
          200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark, home: const WorkoutExerciseLibrary()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'bench');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(searches.last.queryParameters['search'], 'bench');
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();
      expect(find.text('Press with control.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });

  testWidgets(
      'coach creates a native day, selects an exercise and assigns the prescription',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? assigned;
    final client = MockClient((req) async {
      if (req.method == 'POST') {
        assigned = jsonDecode(req.body);
        return http.Response('{"id":1}', 201);
      }
      return http.Response(
          jsonEncode({
            'data': [catalogExercise],
            'hasMore': false,
            'filters': {
              'muscleGroup': ['chest'],
              'equipment': ['barbell'],
              'exerciseType': ['reps']
            }
          }),
          200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: const WorkoutBuilderScreen(clientID: 15)));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plan name'), 'Client plan');
      await tester.tap(find.text('Add workout day'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Day name'), 'Push');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add exercise'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byWidgetPredicate((w) =>
                  w is WorkoutNumberStepper && w.label == 'Target weight (kg)'),
              matching: find.byType(TextField)),
          '60');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutExerciseLibrary), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save and assign to client'));
      await tester.tap(find.text('Save and assign to client'));
      await tester.pumpAndSettle();
      expect(assigned?['clientID'], 15);
      expect(assigned?['status'], 'assigned');
      final prescribed = assigned!['days'][0]['exercises'][0];
      expect(prescribed['exerciseID'], 1);
      expect(prescribed['targetWeight'], 60);
      expect(prescribed['targetSets'], 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
}
