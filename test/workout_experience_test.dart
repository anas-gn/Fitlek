import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/services/workout_recovery.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/services/apiService.dart';
import 'package:fitlek1/screens/ENG/workout/active_workout.dart';
import 'package:fitlek1/screens/ENG/workout/workout_progress.dart';
import 'package:fitlek1/theme/app_theme.dart';
import 'workout_test.dart' show sessionFixture;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42, 'role': 'client'});
    WorkoutService.preferences = {};
  });
  test(
      'offline outbox survives reopening and logout, uses set identity, and stays account scoped',
      () async {
    final fixture = sessionFixture();
    bool offline = true;
    final saved = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      if (offline) throw http.ClientException('Fixture offline');
      if (request.method == 'PUT') {
        final row = Map<String, dynamic>.from(jsonDecode(request.body));
        saved.add(row);
        fixture['sets'] = [row];
        return http.Response('{"saved":true}', 200);
      }
      return http.Response(jsonEncode(fixture), 200);
    });
    await http.runWithClient(() async {
      await WorkoutRecovery.cache(7, fixture);
      await WorkoutRecovery.save(7,
          {'workoutExerciseID': 10, 'setNumber': 1, 'weight': 60, 'reps': 9});
      await WorkoutRecovery.save(7,
          {'workoutExerciseID': 10, 'setNumber': 1, 'weight': 60, 'reps': 10});
      await WorkoutRecovery.draft(
          7, {'notes': 'Remembered', 'restPausedSeconds': 30});
      expect(await WorkoutRecovery.pending(7), 1);
      expect((await WorkoutRecovery.session(7))['offline'], true);
      expect((await WorkoutRecovery.read(7))['draft']['notes'], 'Remembered');
      await ApiService.clearToken();
      await ApiService.saveUserData(99, 'Other');
      expect(await WorkoutRecovery.read(7), isEmpty);
      await ApiService.saveUserData(42, 'Client');
      await ApiService.saveToken('fixture-token');
      expect(await WorkoutRecovery.pending(7), 1);
      offline = false;
      final synced = await WorkoutRecovery.session(7);
      expect(saved.length, 1);
      expect(saved.single['reps'], 10);
      expect(synced['sets'].length, 1);
      expect(await WorkoutRecovery.pending(7), 0);
    }, () => client);
  });
  test('invalid sets are rejected and cannot poison the outbox', () async {
    final client = MockClient(
        (_) async => http.Response('{"message":"invalid_set"}', 400));
    await http.runWithClient(() async {
      await expectLater(
          WorkoutRecovery.save(7, {
            'workoutExerciseID': 10,
            'setNumber': 1,
            'weight': -1,
            'reps': 10
          }),
          throwsA(isA<WorkoutApiException>()));
      expect(await WorkoutRecovery.pending(7), 0);
    }, () => client);
  });
  testWidgets(
      'compact rows save actual performance and undo on a narrow native screen',
      (tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WorkoutService.preferences = {'view': 'compact', 'automaticRest': false};
    final fixture = sessionFixture();
    final requests = <http.Request>[];
    final client = MockClient((req) async {
      requests.add(req);
      if (req.method == 'PUT') {
        final body = Map<String, dynamic>.from(jsonDecode(req.body));
        fixture['sets'] = [
          {...body, 'id': 1}
        ];
        return http.Response('{"saved":true}', 200);
      }
      if (req.method == 'DELETE') {
        fixture['sets'] = [];
        return http.Response('{"removed":true}', 200);
      }
      return http.Response(jsonEncode(fixture), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark, home: const ActiveWorkoutScreen(sessionID: 7)));
      await tester.pumpAndSettle();
      expect(find.text('SET'), findsOneWidget);
      expect(find.text('REPS'), findsWidgets);
      await tester.tap(find.byTooltip('Complete set').first);
      await tester.pumpAndSettle();
      final save = requests.firstWhere((r) => r.method == 'PUT');
      expect(jsonDecode(save.body)['weight'], 60);
      expect(jsonDecode(save.body)['reps'], 10);
      expect(find.byTooltip('Undo set'), findsOneWidget);
      await tester.tap(find.byTooltip('Undo set'));
      await tester.pumpAndSettle();
      expect(requests.any((r) => r.method == 'DELETE'), true);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
  testWidgets('progress and activity charts adapt to a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stats = {
      'workoutCount': 2,
      'setCount': 4,
      'volume': 2400,
      'totalReps': 40,
      'totalDurationSeconds': 3600,
      'hardSets': 4,
      'frequency': [],
      'records': [],
      'activity': [],
      'bodyweight': [],
      'muscles': []
    };
    final client =
        MockClient((_) async => http.Response(jsonEncode(stats), 200));
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light, home: const WorkoutProgressScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Activity — last 12 months · by time trained'),
          findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
}
