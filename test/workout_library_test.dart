import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/screens/ENG/workout/exercise_library.dart';
import 'package:fitlek1/screens/ENG/workout/workout_builder.dart';
import 'package:fitlek1/screens/ENG/workout/workout_charts.dart';
import 'package:fitlek1/screens/ENG/workout/workout_ui.dart';
import 'package:fitlek1/services/apiService.dart';
import 'package:fitlek1/services/workout_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42, 'role': 'client'});
    WorkoutService.preferences = {};
  });

  testWidgets(
      'year activity includes training older than twelve weeks at phone width',
      (tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final date = DateTime.now().subtract(const Duration(days: 300));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(20),
                child:
                    WorkoutActivityGrid(days: 365, metric: 'volume', activity: [
                  {
                    'date': date.toIso8601String().substring(0, 10),
                    'volume': 500
                  }
                ])))));
    expect(find.byTooltip('${workoutDate(date)} · 500 kg'), findsOneWidget);
    expect(find.text('More volume'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
      'read caches are bounded and never returned after authorization or account changes',
      () async {
    var status = 200;
    var switchAccount = false;
    final client = MockClient((request) async {
      if (switchAccount) {
        await ApiService.saveUserData(99, 'Other account');
        throw http.ClientException('Offline');
      }
      return http.Response(
          jsonEncode({'data': [], 'value': request.url.path}), status);
    });
    await http.runWithClient(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sirvya_workout_42_7_draft', '{"notes":"kept"}');
      for (var i = 0; i < 40; i++) {
        await WorkoutService.get('/exercises/$i');
      }
      expect(
          prefs
              .getKeys()
              .where((k) => k.startsWith('sirvya_workout_42_cache_'))
              .length,
          32);
      expect(prefs.getString('sirvya_workout_42_7_draft'), contains('kept'));
      status = 401;
      await expectLater(
          WorkoutService.get('/exercises/39'),
          throwsA(isA<WorkoutApiException>()
              .having((e) => e.status, 'status', 401)));
      switchAccount = true;
      await expectLater(
          WorkoutService.get('/exercises/39'),
          throwsA(isA<WorkoutApiException>()
              .having((e) => e.status, 'status', 401)));
    }, () => client);
  });

  testWidgets(
      'exercise details expose older history and add directly to a native routine',
      (tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final exercise = {
      'id': 1,
      'name': 'Fixture press',
      'muscleGroup': 'chest',
      'equipment': 'barbell',
      'exerciseType': 'reps',
      'isBodyweight': 0,
      'instructions': ['Press steadily.'],
      'secondaryMuscles': []
    };
    final pages = <int>[];
    final client = MockClient((request) async {
      final path = request.url.path;
      Object result = {};
      if (path.endsWith('/exercises/1')) {
        result = exercise;
      }
      if (path.endsWith('/media')) {
        result = {'data': [], 'canUpload': false};
      }
      if (path.endsWith('/history')) {
        final page = int.parse(request.url.queryParameters['page'] ?? '1');
        pages.add(page);
        result = {
          'data': List.generate(
              page == 1 ? 60 : 10,
              (i) => {
                    'workoutSessionID': 100 - i - (page - 1) * 60,
                    'setNumber': 1,
                    'weight': 40 + i,
                    'reps': 10,
                    'details': {'phase': 'work'},
                    'startedAt': '2026-09-01T10:00:00Z'
                  }),
          'hasMore': page == 1
        };
      }
      if (path.endsWith('/plans')) {
        result = {
          'data': [
            {
              'id': 2,
              'clientID': 42,
              'coachID': null,
              'name': 'Fixture routine',
              'status': 'assigned',
              'revision': 1,
              'days': [
                {'id': 3, 'name': 'Push', 'exercises': []}
              ]
            }
          ]
        };
      }
      return http.Response(jsonEncode(result), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: WorkoutExerciseDetail(exercise: Exercise.fromJson(exercise))));
      await tester.pumpAndSettle();
      expect(pages, [1]);
      await tester.scrollUntilVisible(find.text('Load more'), 700,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(pages, [1, 2]);
      expect(find.text('Load more'), findsNothing);
      await tester.scrollUntilVisible(find.text('Add to routine'), -700,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Add to routine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutBuilderScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Fixture Press'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }, () => client);
  });
}
