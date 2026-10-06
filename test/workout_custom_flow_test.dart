import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/screens/ENG/workout/exercise_library.dart';

void main() {
  testWidgets(
      'minimal custom cardio returns a selectable time-and-speed exercise',
      (tester) async {
    SharedPreferences.setMockInitialValues({'token': 'fixture', 'userId': 42});
    WorkoutService.preferences = {};
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Exercise? selected;
    Map<String, dynamic>? submitted;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        submitted = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'id': 123}), 201);
      }
      return http.Response(
          jsonEncode({
            'data': [],
            'total': 0,
            'chosenCount': 0,
            'hasMore': false,
            'filters': {
              'bodyPart': ['cardio', 'chest'],
              'equipment': []
            }
          }),
          200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () async {
                        selected = await workoutPickExercise(context);
                      },
                      child: const Text('Pick'))))));
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create your own exercise'));
      await tester.pumpAndSettle();
      expect(find.text('Secondary muscles (comma separated)'), findsNothing);
      expect(find.text('Type'), findsNothing);
      await tester.enterText(
          find.byType(TextFormField).first, 'Hill intervals');
      await tester.tap(find.descendant(
          of: find.byType(Form),
          matching: find.widgetWithText(ChoiceChip, 'cardio')));
      await tester.pumpAndSettle();
      expect(find.text('Cardio logs time and speed.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Save exercise'), 200,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('Save exercise'));
      await tester.pumpAndSettle();
      expect(submitted!['exerciseType'], 'cardio');
      expect(submitted!['bodyPart'], 'cardio');
      expect(selected!.id, 123);
      expect(selected!.type, 'cardio');
      expect(selected!.equipment, 'custom');
      expect(find.byType(WorkoutExerciseLibrary), findsNothing);
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
