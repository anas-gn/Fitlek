import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/screens/ENG/workout/workout_anatomy.dart';
import 'package:fitlek1/screens/ENG/workout/workout_muscles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'all four anatomy views retain named muscle contours and precise hit targets',
      () async {
    final views = await loadWorkoutAnatomy();
    expect(
        views.keys,
        containsAll(
            ['male-front', 'male-back', 'female-front', 'female-back']));
    final names = <String>{};
    for (final view in views.values) {
      expect(view.silhouette, isNotEmpty);
      expect(view.muscles, isNotEmpty);
      for (final shape in view.muscles) {
        names.add(shape.$1);
        final bounds = shape.$2.getBounds();
        expect(bounds.overlaps(Offset.zero & workoutAnatomySize), true);
        // Find an interior point rather than using a bounding box: the outline
        // can be concave, and a rectangle would select a neighbouring muscle.
        Offset? inside;
        for (var y = 1; y < 12 && inside == null; y++) {
          for (var x = 1; x < 12; x++) {
            final point = Offset(bounds.left + bounds.width * x / 12,
                bounds.top + bounds.height * y / 12);
            if (shape.$2.contains(point) && view.muscleAt(point) == shape.$1) {
              inside = point;
              break;
            }
          }
        }
        // Shared boundaries can be covered by a later-painted contour, as in SVG.
        if (inside != null) expect(view.muscleAt(inside), shape.$1);
      }
      expect(view.muscleAt(Offset.zero), isNull);
    }
    expect(names, containsAll(workoutMuscleNames));
  });
  testWidgets(
      'muscle selection works on both figures with no rendering exceptions',
      (tester) async {
    for (final body in ['male', 'female']) {
      String? selected;
      final views = await tester.runAsync(loadWorkoutAnatomy);
      final view = views!['$body-front']!;
      final chest =
          view.muscles.firstWhere((s) => s.$1 == 'chest').$2.getBounds().center;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                      width: 216,
                      height: 380,
                      child: WorkoutAnatomyView(
                          body: body,
                          load: const {'chest': 3},
                          onMuscle: (muscle) => selected = muscle))))));
      await tester.pumpAndSettle();
      await tester
          .tapAt(tester.getTopLeft(find.byType(WorkoutAnatomyView)) + chest);
      expect(selected, 'chest');
      expect(tester.takeException(), isNull);
    }
  });
}
