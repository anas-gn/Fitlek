import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/screens/ENG/mealScanner.dart';
import 'package:fitlek1/services/meal_scan_service.dart';
import 'nutrition_tracker_test.dart' show TestDiary;
import 'meal_result_test.dart' show sampleMeal;

class ActionsDiary extends TestDiary {
  int saves = 0, deletions = 0;
  @override
  Future<void> save(ScannedMeal meal) async {
    saves++;
    await super.save(meal);
  }

  @override
  Future<void> delete(ScannedMeal meal) async {
    deletions++;
    await super.delete(meal);
  }
}

void main() {
  testWidgets(
      'save asks for category; moving updates the same meal; deletion requires confirmation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = ActionsDiary()..meals.clear();
    addTearDown(service.close);
    final meal = sampleMeal();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MealResultScreen(
                                meal: meal, clientID: 7, service: service))),
                    child: const Text('Open meal'))))));
    await tester.tap(find.text('Open meal'));
    await tester.pumpAndSettle();
    expect(service.saves, 0);
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    for (final type in ['Breakfast', 'Lunch', 'Dinner', 'Snack']) {
      expect(find.text(type), findsOneWidget);
    }
    expect(service.saves, 0);
    await tester.tap(find.byKey(const ValueKey('choose-meal-breakfast')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to Breakfast'));
    await tester.pumpAndSettle();
    expect(service.meals.single.mealType, 'breakfast');
    expect(service.saves, 1);
    await tester.scrollUntilVisible(find.text('Move meal'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Move meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-meal-lunch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Lunch'));
    await tester.pumpAndSettle();
    expect(service.meals.single.id, meal.id);
    expect(service.meals.single.mealType, 'lunch');
    expect(service.saves, 2);
    await tester.ensureVisible(find.text('Delete meal'));
    await tester.tap(find.text('Delete meal'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this meal?'), findsOneWidget);
    await tester.tap(find.text('Keep meal'));
    await tester.pumpAndSettle();
    expect(service.deletions, 0);
    expect(service.meals.length, 1);
    await tester.tap(find.text('Delete meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete meal'));
    await tester.pumpAndSettle();
    expect(service.deletions, 1);
    expect(service.meals, isEmpty);
    expect(find.text('Open meal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dismissing category choice leaves a new meal unsaved',
      (tester) async {
    final service = ActionsDiary()..meals.clear();
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: MealResultScreen(
            meal: sampleMeal(), clientID: 7, service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(service.saves, 0);
    expect(service.meals, isEmpty);
    expect(find.text('Save meal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
