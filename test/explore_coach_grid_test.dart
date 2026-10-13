import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/ENG/exploreCoachGrid.dart';
import 'package:fitlek1/models/anas/coach.dart';
import 'package:fitlek1/theme/fitlek_theme_extension.dart';

void main() {
  for (final entry in {320.0: 1, 390.0: 2, 800.0: 3, 1200.0: 4}.entries) {
    testWidgets('grid fits ${entry.key}px and preserves coach actions',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(entry.key, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      int? opened, favorited;
      final coaches = List.generate(
          8,
          (i) => CoachModel.fromJson({
                'id': i + 1,
                'firstName': 'A long coach first name',
                'lastName': 'Long last name',
                'ville': 'A long city name',
                'specialties': ['Strength', 'Yoga'],
                'isApproved': i == 0 ? 1 : 0,
              }));
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(extensions: const [FitlekColors.dark]),
          home: Scaffold(
              body: ExploreCoachGrid(
                  coaches: coaches,
                  favorites: const {1},
                  ratings: const {1: 4.5},
                  reviewCounts: const {1: 10},
                  onOpen: (coach) => opened = coach.id,
                  onFavorite: (id) => favorited = id))));
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          entry.value);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Remove from favorites').first);
      expect(favorited, 1);
      expect(opened, isNull);
      await tester.tap(find.text('View & Book').first);
      expect(opened, 1);
      await tester.drag(find.byType(GridView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
