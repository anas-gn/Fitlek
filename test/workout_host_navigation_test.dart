import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/screens/ENG/clientHome.dart';
import 'package:fitlek1/screens/ENG/workout/workout_home.dart';
import 'package:fitlek1/theme/app_theme.dart';
import 'package:fitlek1/components/theme_selector.dart';
import 'package:fitlek1/services/theme_service.dart';

void main() {
  testWidgets('SIRVYA opens Workout full screen and returns to the client home',
      (tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'token': 'host-fixture-only',
      'userId': 42,
      'firstName': 'QA',
      'role': 'client'
    });
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'));
    await font.load();
    final workoutFont = FontLoader('SirvyaWorkout')
      ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'));
    await workoutFont.load();
    final controller = ThemeController();
    await controller.load();
    addTearDown(controller.dispose);
    final fixture = jsonDecode(File('test/fixtures/workout-product-parity.json')
        .readAsStringSync()) as Map<String, dynamic>;
    var workoutReads = 0;
    final client = MockClient((request) async {
      final path = request.url.path;
      Object data = [];
      if (path.contains('/clients/me')) {
        data = {
          'id': 42,
          'firstName': 'Workout',
          'lastName': 'Fixture',
          'role': 'client',
          'ville': null
        };
      }
      if (path.contains('unread') || path.endsWith('/count')) {
        data = {'count': 0, 'total': 0};
      }
      if (path.contains('/workout/')) {
        workoutReads++;
        data = {'data': []};
        if (path.endsWith('/plans')) {
          data = {
            'data': [fixture['plan']]
          };
        }
        if (path.endsWith('/stats')) data = fixture['stats'];
        if (path.endsWith('/history')) data = {'data': fixture['history']};
        if (path.endsWith('/schedule')) data = fixture['schedule'];
        if (path.endsWith('/sessions/active')) data = {'session': null};
        if (path.endsWith('/preferences')) {
          data = {'unit': 'kg', 'bodyweightCheckIn': false};
        }
      }
      return http.Response(jsonEncode(data), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(ThemeControllerScope(
          controller: controller,
          child: MaterialApp(
              theme: AppTheme.light,
              home: const HomeScreen(
                  clientID: 42, token: 'host-fixture-only', firstName: 'QA'))));
      await tester.pumpAndSettle();
      expect(workoutReads, 0, reason: 'Workout should load only when opened');
      await tester.tap(find.text('Workout').last);
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutHomeScreen), findsOneWidget);
      for (var tab = 0; tab < 5; tab++) {
        expect(find.byKey(ValueKey('workout-tab-$tab')), findsOneWidget);
      }
      expect(find.text('Explore'), findsNothing,
          reason: 'Host navigation must not occupy Workout space');
      await tester.tap(find.byTooltip('Back to SIRVYA'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutHomeScreen), findsNothing);
      expect(find.text('Explore'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
}
