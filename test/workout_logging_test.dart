import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/screens/ENG/workout/workout_set_row.dart';
import 'package:fitlek1/services/workout_service.dart';

void main() {
  setUp(() => WorkoutService.preferences = {'effort': 'off'});

  testWidgets('editing reps preserves the effort scale originally recorded',
      (tester) async {
    const exercise = Exercise(
        id: 1,
        name: 'Press',
        muscleGroup: 'chest',
        equipment: 'barbell',
        type: 'reps',
        isBodyweight: false);
    for (final current in ['rpe', 'rir']) {
      WorkoutService.preferences = {'effort': current};
      Map<String, dynamic>? submitted;
      final oldScale = current == 'rpe' ? 'rir' : 'rpe';
      final rating = oldScale == 'rir' ? 2 : 8;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: WorkoutSetRow(
                  key: ValueKey(current),
                  exercise: WorkoutExercise(
                      id: 10, exercise: exercise, reps: 10, weight: 60),
                  number: 1,
                  busy: false,
                  saved: WorkoutSet.fromJson({
                    'id': 90,
                    'workoutExerciseID': 10,
                    'setNumber': 1,
                    'reps': 10,
                    'weight': 60,
                    oldScale: rating
                  }),
                  onSave: (value) async {
                    submitted = value;
                    return true;
                  },
                  onUndo: () {},
                  onDetails: () {}))));
      await tester.enterText(find.byType(TextField).at(1), '9');
      await tester.pump();
      await tester.tap(find.byTooltip('Complete set'));
      await tester.pump();
      expect(submitted?[oldScale], rating);
      expect(submitted?[current], null);
    }
  });

  testWidgets('bodyweight sets log reps with optional added load',
      (tester) async {
    const exercise = Exercise(
        id: 1,
        name: 'Push-up',
        muscleGroup: 'chest',
        equipment: 'body weight',
        type: 'reps',
        isBodyweight: true);
    final saved = <Map<String, dynamic>>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WorkoutSetRow(
      exercise:
          WorkoutExercise(id: 10, exercise: exercise, reps: 12, weight: 0),
      number: 1,
      busy: false,
      onSave: (set) async {
        saved.add(set);
        return true;
      },
      onUndo: () {},
      onDetails: () {},
    ))));
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byTooltip('Complete set'));
    await tester.pump();
    expect(saved.single['weight'], 0);
    expect(saved.single['reps'], 12);
    await tester.tap(find.byTooltip('Add external load'));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.tap(find.byTooltip('Complete set'));
    await tester.pump();
    expect(saved.last['weight'], 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timed carries retain external load and duration without reps',
      (tester) async {
    const exercise = Exercise(
        id: 2,
        name: 'Loaded carry',
        muscleGroup: 'back',
        equipment: 'dumbbell',
        type: 'timed',
        isBodyweight: false);
    Map<String, dynamic>? saved;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WorkoutSetRow(
      exercise: WorkoutExercise(
          id: 11, exercise: exercise, durationSeconds: 60, weight: 20),
      number: 1,
      busy: false,
      onSave: (set) async {
        saved = set;
        return true;
      },
      onUndo: () {},
      onDetails: () {},
    ))));
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, '25');
    await tester.tap(find.byTooltip('Complete set'));
    await tester.pump();
    expect(saved?['weight'], 25);
    expect(saved?['durationSeconds'], 60);
    expect(saved?['reps'], isNull);
  });

  testWidgets('editing saved set data refreshes values with a stable set ID',
      (tester) async {
    WorkoutService.preferences = {'effort': 'rpe'};
    const exercise = Exercise(
        id: 1,
        name: 'Press',
        muscleGroup: 'chest',
        equipment: 'barbell',
        type: 'reps',
        isBodyweight: false);
    final prescribed =
        WorkoutExercise(id: 10, exercise: exercise, reps: 10, weight: 60);
    Widget row(int reps, int weight, int rpe) => MaterialApp(
            home: Scaffold(
                body: WorkoutSetRow(
          exercise: prescribed,
          number: 1,
          busy: false,
          saved: WorkoutSet.fromJson({
            'id': 90,
            'setNumber': 1,
            'reps': reps,
            'weight': weight,
            'rpe': rpe
          }),
          onSave: (_) async => true,
          onUndo: () {},
          onDetails: () {},
        )));
    await tester.pumpWidget(row(10, 60, 8));
    await tester.pumpWidget(row(9, 55, 7));
    expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .map((field) => field.controller!.text),
        ['55', '9', '7']);
  });
}
