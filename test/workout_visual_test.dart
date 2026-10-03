import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/screens/ENG/workout/workout_home.dart';
import 'package:fitlek1/screens/ENG/workout/active_workout.dart';
import 'package:fitlek1/screens/ENG/workout/workout_builder.dart';
import 'package:fitlek1/screens/ENG/workout/exercise_library.dart';
import 'package:fitlek1/screens/ENG/workout/workout_progress.dart';
import 'package:fitlek1/theme/app_theme.dart';
import 'workout_test.dart' show sessionFixture, catalogExercise;

// Optional native Flutter rendering artifacts. These are fixture views, not
// screenshots of a signed-in browser or proof of physical-device behavior.
void main() {
  testWidgets('native workout parity captures at phone width', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42, 'role': 'client'});
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'));
    await font.load();
    final workoutFont = FontLoader('SirvyaWorkout')
      ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Bold.ttf'));
    await workoutFont.load();
    final iconFont = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await iconFont.load();
    final plan = {
      'id': 1,
      'coachID': 12,
      'clientID': 42,
      'name': 'Strength foundation',
      'description': 'Three sessions each week',
      'status': 'assigned',
      'revision': 1,
      'days': [
        {
          'id': 2,
          'name': 'Upper body',
          'dayOfWeek': DateTime.now().weekday,
          'exercises': sessionFixture()['prescription']['exercises']
        }
      ]
    };
    final stats = {
      'workoutCount': 12,
      'setCount': 144,
      'volume': 32400,
      'totalReps': 1440,
      'hardSets': 90,
      'totalDurationSeconds': 21600,
      'currentStreak': 2,
      'longestStreak': 4,
      'prCount': 8,
      'adherence': {'performed': 10, 'expected': 12, 'percent': 83},
      'workload': {'recentSets': 36, 'previousSets': 32},
      'frequency': [],
      'activity': [],
      'muscles': [],
      'bodyweight': [],
      'records': []
    };
    WorkoutService.preferences = {'view': 'compact', 'automaticRest': false};
    final client = MockClient((req) async {
      final path = req.url.path;
      Object result = {};
      if (path.endsWith('/plans')) {
        result = {
          'data': [plan]
        };
      }
      if (path.endsWith('/stats')) result = stats;
      if (path.endsWith('/active')) result = {'session': null};
      if (path.endsWith('/history')) result = {'data': []};
      if (path.endsWith('/schedule')) {
        result = {'data': [], 'overrideDates': []};
      }
      if (path.endsWith('/preferences')) result = WorkoutService.preferences;
      if (path.endsWith('/sessions/7')) result = sessionFixture();
      if (path.endsWith('/exercises')) {
        result = {
          'data': [
            catalogExercise,
            {
              ...catalogExercise,
              'id': 2,
              'name': 'Incline dumbbell press',
              'equipment': 'dumbbell'
            },
            {
              ...catalogExercise,
              'id': 3,
              'name': 'Push-up',
              'equipment': 'body weight',
              'isBodyweight': 1
            }
          ],
          'total': 1348,
          'hasMore': false,
          'filters': {
            'muscleGroup': ['chest', 'back', 'legs'],
            'equipment': ['barbell', 'dumbbell', 'body weight'],
            'exerciseType': ['reps', 'timed'],
            'secondaryMuscle': ['triceps']
          }
        };
      }
      return http.Response(jsonEncode(result), 200);
    });
    await http.runWithClient(() async {
      for (final entry in <String, Widget>{
        'dashboard': const WorkoutHomeScreen(),
        'active': const ActiveWorkoutScreen(sessionID: 7),
        'library': const WorkoutExerciseLibrary(),
        'coach-builder': WorkoutBuilderScreen(
            clientID: 42, plan: WorkoutPlan.fromJson(plan)),
        'progress': const WorkoutProgressScreen()
      }.entries) {
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark,
                home: entry.value)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          await Directory('docs/verification').create(recursive: true);
          await File('docs/verification/native-${entry.key}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }, () => client);
  }, skip: Platform.environment['WORKOUT_CAPTURE_SCREENSHOTS'] != '1');
}
