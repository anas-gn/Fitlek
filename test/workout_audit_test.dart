import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/services/locale_service.dart';
import 'package:fitlek1/services/notification_service.dart';
import 'package:fitlek1/screens/ENG/workout/workout_home.dart';
import 'package:fitlek1/screens/ENG/workout/active_workout.dart';
import 'package:fitlek1/screens/ENG/workout/workout_builder.dart';
import 'package:fitlek1/screens/ENG/workout/exercise_library.dart';
import 'package:fitlek1/screens/ENG/workout/workout_progress.dart';
import 'package:fitlek1/screens/ENG/workout/workout_muscles.dart';
import 'workout_test.dart' show sessionFixture, catalogExercise;

void main() {
  test('muscle coverage separates prescribed sets from performed working sets',
      () {
    final session = WorkoutSession.fromJson(sessionFixture());
    final exercise = session.exercises.first;
    final sets = [
      WorkoutSet.fromJson({
        'workoutExerciseID': exercise.id,
        'setNumber': 1,
        'reps': 9,
        'weight': 57.5
      }),
      WorkoutSet.fromJson({
        'workoutExerciseID': exercise.id,
        'setNumber': 1001,
        'details': {'phase': 'warmup'}
      })
    ];
    expect(workoutMuscleCoverage([exercise]),
        {exercise.exercise.muscleGroup: exercise.sets.toDouble()});
    expect(workoutMuscleCoverage([exercise], performed: sets),
        {exercise.exercise.muscleGroup: 1.0});
  });
  testWidgets('rest notification reuses the mounted workout route and timer',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42, 'role': 'client'});
    WorkoutService.preferences = {'automaticRest': false};
    final client = MockClient(
        (_) async => http.Response(jsonEncode(sessionFixture()), 200));
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          navigatorKey: appNavigatorKey,
          home: const ActiveWorkoutScreen(sessionID: 7)));
      await tester.pumpAndSettle();
      NotificationService.instance.handleNotificationClick(jsonEncode(
          {'type': 'workout_rest', 'userID': 42, 'relatedEntityID': 7}));
      await tester.pumpAndSettle();
      expect(find.byType(ActiveWorkoutScreen, skipOffstage: false),
          findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390)
  ]) {
    for (final language in ['en', 'fr', 'es']) {
      testWidgets(
          'Workout layouts $size $language with long names and enlarged text',
          (tester) async {
        SharedPreferences.setMockInitialValues(
            {'token': 'fixture-token', 'userId': 42, 'role': 'client'});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = sessionFixture();
        final exercise =
            session['prescription']['exercises'][0] as Map<String, dynamic>;
        exercise['name'] =
            'Very long exercise name with controlled movement and detailed unilateral resistance training';
        final plan = {
          'id': 1,
          'name':
              'A long training plan for controlled strength and conditioning',
          'status': 'assigned',
          'clientID': 42,
          'days': [
            {
              'id': 1,
              'name': 'Upper strength and conditioning',
              'dayOfWeek': DateTime.now().weekday,
              'exercises': [exercise]
            }
          ]
        };
        final prefs = {
          'view': 'compact',
          'effort': 'rpe',
          'automaticRest': false
        };
        WorkoutService.preferences = prefs;
        final client = MockClient((req) async {
          final path = req.url.path;
          final Object value = path.endsWith('/plans')
              ? {
                  'data': [plan]
                }
              : path.endsWith('/preferences')
                  ? prefs
                  : path.endsWith('/clients')
                      ? {
                          'data': [
                            {
                              'id': 42,
                              'firstName': 'A long client name',
                              'lastName': 'With a long surname'
                            }
                          ]
                        }
                      : path.endsWith('/schedule')
                          ? {'data': [], 'overrideDates': []}
                          : path.endsWith('/active')
                              ? {'session': null}
                              : path.endsWith('/sessions/7')
                                  ? session
                                  : path.endsWith('/history')
                                      ? {'data': []}
                                      : path.endsWith('/exercises')
                                          ? {
                                              'data': [
                                                {
                                                  ...catalogExercise,
                                                  'name': exercise['name']
                                                }
                                              ],
                                              'filters': {
                                                'muscleGroup': ['chest'],
                                                'equipment': ['barbell'],
                                                'exerciseType': ['reps']
                                              }
                                            }
                                          : path.endsWith('/stats')
                                              ? {
                                                  'workoutCount': 12,
                                                  'volume': 32400,
                                                  'setCount': 100,
                                                  'totalReps': 1200,
                                                  'totalDurationSeconds': 22000,
                                                  'frequency': [],
                                                  'activity': [],
                                                  'records': [],
                                                  'muscles': [],
                                                  'bodyweight': []
                                                }
                                              : {};
          return http.Response(jsonEncode(value), 200);
        });
        await http.runWithClient(() async {
          final views = <String, Widget>{
            'client dashboard': const WorkoutHomeScreen(),
            'coach dashboard': const WorkoutHomeScreen(coach: true),
            'active compact': const ActiveWorkoutScreen(sessionID: 7),
            'library': const WorkoutExerciseLibrary(),
            'builder': WorkoutBuilderScreen(
                clientID: 42, plan: WorkoutPlan.fromJson(plan)),
            'history': const WorkoutHistoryScreen(),
            'statistics': const WorkoutProgressScreen(),
            'completion': WorkoutCompletionScreen(
                summary: const {
                  'durationSeconds': 600,
                  'exerciseCount': 1,
                  'setCount': 1,
                  'volume': 517.5,
                  'newPRs': 1
                },
                session: WorkoutSession.fromJson({
                  ...session,
                  'sets': [
                    {
                      'workoutExerciseID': exercise['id'],
                      'setNumber': 1,
                      'reps': 9,
                      'weight': 57.5
                    }
                  ]
                }))
          };
          for (final entry in views.entries) {
            await tester.pumpWidget(MaterialApp(
                locale: Locale(language),
                supportedLocales: LocaleService.supported,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.4)),
                    child: child!),
                home: entry.value));
            await tester.pumpAndSettle();
            expect(tester.takeException(), null, reason: entry.key);
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }, () => client);
      });
    }
  }
}
