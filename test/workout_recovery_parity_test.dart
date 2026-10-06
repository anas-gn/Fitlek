import 'dart:convert';
import 'package:fitlek1/screens/ENG/workout/workout_anatomy.dart';
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
import 'package:fitlek1/screens/ENG/workout/exercise_library.dart';
import 'package:fitlek1/screens/ENG/workout/workout_builder.dart';
import 'package:fitlek1/screens/ENG/workout/workout_set_row.dart';

const exercise = Exercise(
    id: 1,
    name: 'Unilateral press',
    muscleGroup: 'chest',
    equipment: 'dumbbell',
    type: 'reps',
    isBodyweight: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadWorkoutAnatomy();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture', 'userId': 42, 'role': 'client'});
    WorkoutService.preferences = {'unit': 'kg', 'effort': 'rir'};
  });

  testWidgets(
      'RIR distinguishes blank and zero, steps by half, and survives model decoding',
      (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WorkoutSetRow(
                exercise: WorkoutExercise(
                    id: 10, exercise: exercise, reps: 10, weight: 60),
                number: 1,
                busy: false,
                onSave: (data) async {
                  saved = data;
                  return true;
                },
                onUndo: () {},
                onDetails: () {}))));
    final effort = tester
        .widgetList<WorkoutNumberStepper>(find.byType(WorkoutNumberStepper))
        .firstWhere((s) => s.label == 'RIR');
    await tester.tap(find.byTooltip('Decrease RIR'));
    expect(effort.controller.text, '');
    await tester.tap(find.byTooltip('Increase RIR'));
    expect(effort.controller.text, '0');
    await tester.tap(find.byTooltip('Increase RIR'));
    expect(effort.controller.text, '0.5');
    await tester.tap(find.byTooltip('Complete set'));
    await tester.pumpAndSettle();
    expect(saved!['rir'], .5);
    expect(WorkoutSet.fromJson({...saved!, 'rir': '0.50'}).rir, .5);
    await tester.tap(find.byTooltip('Decrease RIR'));
    await tester.tap(find.byTooltip('Decrease RIR'));
    expect(effort.controller.text, '');
    await tester.tap(find.byTooltip('Complete set'));
    await tester.pumpAndSettle();
    expect(saved!['rir'], isNull);
  });

  testWidgets(
      'per-side config rounds typed targets, steps by two and clears on Time',
      (tester) async {
    WorkoutExercise? result;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await workoutConfigureExercise(context,
                          exercise: exercise,
                          existing: WorkoutExercise(
                              exercise: exercise, reps: 15, weight: 60));
                    },
                    child: const Text('Configure'))))));
    await tester.tap(find.text('Configure'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Repetitions per side'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Repetitions per side'));
    await tester.pumpAndSettle();
    final reps = tester
        .widgetList<WorkoutNumberStepper>(find.byType(WorkoutNumberStepper))
        .firstWhere((s) => s.label == 'Target repetitions');
    expect(reps.controller.text, '16');
    expect(reps.step, 2);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result!.reps, 16);
    expect(result!.configuration['perSide'], true);
    await tester.tap(find.text('Configure'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Repetitions per side'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Repetitions per side'));
    await tester.scrollUntilVisible(find.text('Time'), -300,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result!.exercise.type, 'timed');
    expect(result!.reps, isNull);
    expect(result!.configuration['perSide'], false);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 396.0, 1100.0]) {
    testWidgets('routine editor and Chosen sheet remain usable at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final frame = GlobalKey();
      for (final family in ['SirvyaWorkout', 'Roboto']) {
        final font = FontLoader(family)
          ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'));
        await font.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      var chosenRequested = false;
      final plan = WorkoutPlan.fromJson({
        'id': 2,
        'name': 'Push',
        'clientID': 42,
        'revision': 1,
        'status': 'assigned',
        'days': [
          {
            'id': 3,
            'name': 'Push',
            'configuration': {'progression': 'linear'},
            'exercises': List.generate(
                2,
                (i) => {
                      'id': 10 + i,
                      'exerciseID': 1 + i,
                      'name': i == 0 ? 'Unilateral press' : 'Dumbbell row',
                      'muscleGroup': i == 0 ? 'chest' : 'back',
                      'equipment': 'dumbbell',
                      'exerciseType': 'reps',
                      'isBodyweight': 0,
                      'targetSets': 3,
                      'targetReps': 10,
                      'targetWeight': 60,
                      'restSeconds': 90
                    })
          }
        ]
      });
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/exercises')) {
          chosenRequested = request.url.queryParameters['chosen'] == 'true';
          return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 7,
                    'name': 'Previously trained row',
                    'muscleGroup': 'back',
                    'bodyPart': 'back',
                    'equipment': 'dumbbell',
                    'exerciseType': 'reps',
                    'isBodyweight': 0,
                    'usageCount': 3
                  }
                ],
                'total': 1,
                'chosenCount': 1,
                'hasMore': false,
                'filters': {
                  'bodyPart': ['back', 'chest'],
                  'equipment': ['dumbbell']
                }
              }),
              200);
        }
        return http.Response(
            jsonEncode({
              'id': 2,
              'revision': 2,
              'days': plan.days.map((d) => d.toJson()).toList()
            }),
            200);
      });
      Future<void> capture(String screen) async {
        expect(tester.takeException(), isNull);
        if (Platform.environment['WORKOUT_CAPTURE'] != '1' || width == 320) {
          return;
        }
        await tester.runAsync(() async {
          final boundary =
              frame.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final picture = await boundary.toImage();
          final bytes =
              await picture.toByteData(format: ui.ImageByteFormat.png);
          await File(
                  'docs/verification/parity/sirvya-recovery-$screen-${width.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
      }

      await http.runWithClient(() async {
        WorkoutService.preferences = {'unit': 'lb'};
        await tester.pumpWidget(RepaintBoundary(
            key: frame,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: WorkoutBuilderScreen(plan: plan, personal: true))));
        await tester.pumpAndSettle();
        expect(find.textContaining('132.3 lb'), findsWidgets);
        await capture('editor');
        await tester.scrollUntilVisible(find.text('Add exercise'), 300,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('Add exercise'));
        await tester.pumpAndSettle();
        expect(find.byType(WorkoutExerciseLibrary), findsOneWidget);
        expect(find.byType(ModalBarrier), findsWidgets);
        await tester.tap(find.text('Chosen (1)'));
        await tester.pumpAndSettle();
        expect(chosenRequested, true);
        expect(find.text('Create your own exercise'), findsNothing);
        await capture('picker');
        await tester.tap(find.text('Previously Trained Row'));
        await tester.pumpAndSettle();
        expect(find.byType(WorkoutExerciseLibrary, skipOffstage: false),
            findsOneWidget);
        expect(find.text('Previously Trained Row'), findsNWidgets(2));
        await capture('configuration');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Chosen (1)'), findsOneWidget);
        expect(find.text('Previously Trained Row'), findsOneWidget);
        await tester.tap(find.text('Previously Trained Row'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Save'), 300,
            scrollable: find.byType(Scrollable).last);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.byType(WorkoutExerciseLibrary), findsOneWidget);
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(WorkoutExerciseLibrary), findsNothing);
        expect(find.text('Previously Trained Row'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => client);
    });
  }
}
