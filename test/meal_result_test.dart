import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/screens/ENG/mealScanner.dart';
import 'package:fitlek1/services/meal_scan_service.dart';

ScannedMeal sampleMeal() => ScannedMeal(
        id: 'test',
        name: 'Moroccan chicken tagine with vegetables',
        notes: 'Olive oil and portions are estimated.',
        confidence: 'medium',
        createdAt: DateTime(2026, 10, 14),
        portion: 1,
        photoPath: '/missing-meal-photo.jpg',
        ingredients: [
          const MealIngredient(
              name: 'Chicken',
              grams: 120,
              calories: 200,
              protein: 30,
              carbs: 0,
              fat: 8),
          const MealIngredient(
              name: 'Vegetables with olive oil',
              grams: 150,
              calories: 120,
              protein: 2,
              carbs: 20,
              fat: 4),
        ]);

void main() {
  testWidgets(
      'manual meals edit nutrition directly without dividing by a zero weight',
      (tester) async {
    final json = sampleMeal().toJson();
    json['confidence'] = 'manual';
    (json['ingredients'] as List).first['grams'] = 0;
    final meal = ScannedMeal.fromJson(json);
    await tester.pumpWidget(
        MaterialApp(home: MealResultScreen(meal: meal, clientID: 1)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Edit Chicken'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Chicken'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(meal.total('calories'), 620);
    expect(meal.total('protein').isFinite, true);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('meal result fits $width and portion edits update nutrition',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final meal = sampleMeal();
      await tester.pumpWidget(
          MaterialApp(home: MealResultScreen(meal: meal, clientID: 1)));
      await tester.pumpAndSettle();
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('32 g'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byTooltip('Edit Chicken'), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit Chicken'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '60');
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(meal.total('calories'), 220);
      expect(meal.total('protein'), 17);
      await tester.scrollUntilVisible(find.text('17 g'), -150,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('17 g'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
