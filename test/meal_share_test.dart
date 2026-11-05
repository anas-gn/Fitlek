import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/meal_share_card.dart';
import 'package:fitlek1/components/meal_share_modal.dart';
import 'package:fitlek1/components/meal_visuals.dart';
import 'package:fitlek1/services/meal_scan_service.dart';
import 'package:fitlek1/services/meal_share_service.dart';

ScannedMeal testMeal() => ScannedMeal(
      id: 'meal_share_test',
      name: 'Avocado Toast with Poached Eggs',
      notes: 'Delicious high-protein breakfast',
      confidence: 'high',
      createdAt: DateTime(2026, 11, 5, 8, 30),
      portion: 1,
      photoPath: '',
      mealType: 'breakfast',
      ingredients: const [
        MealIngredient(
          name: 'Poached Eggs',
          grams: 100,
          calories: 140,
          protein: 12,
          carbs: 1,
          fat: 10,
        ),
        MealIngredient(
          name: 'Avocado',
          grams: 80,
          calories: 130,
          protein: 2,
          carbs: 7,
          fat: 12,
        ),
        MealIngredient(
          name: 'Whole Wheat Toast',
          grams: 60,
          calories: 150,
          protein: 6,
          carbs: 26,
          fat: 2,
        ),
      ],
    );

void main() {
  group('MealShareService', () {
    test('generateMarketingCaption generates branded marketing caption', () {
      final meal = testMeal();
      final caption = MealShareService.generateMarketingCaption(meal);

      expect(caption, contains('Avocado Toast with Poached Eggs'));
      expect(caption, contains('420 kcal'));
      expect(caption, contains('20g Protein'));
      expect(caption, contains('34g Carbs'));
      expect(caption, contains('24g Fat'));
      expect(caption, contains('SIRVYA'));
      expect(caption, contains('https://sirvya.com'));
      expect(caption, contains('#SIRVYA'));
    });
  });

  group('MealShareCard', () {
    testWidgets('renders story format with branding and nutrition',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final meal = testMeal();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MealShareCard(
                meal: meal,
                format: MealShareFormat.story,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI MEAL SCAN'), findsOneWidget);
      expect(find.text('Avocado Toast with Poached Eggs'), findsOneWidget);
      expect(find.text('420'), findsOneWidget);
      expect(find.text('20g'), findsOneWidget);
      expect(find.text('34g'), findsOneWidget);
      expect(find.text('24g'), findsOneWidget);
      expect(find.text('GET SIRVYA'), findsOneWidget);
      expect(find.text('BREAKFAST'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders post format with branding and nutrition',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final meal = testMeal();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MealShareCard(
                meal: meal,
                format: MealShareFormat.post,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI MEAL SCAN'), findsOneWidget);
      expect(find.text('Avocado Toast with Poached Eggs'), findsOneWidget);
      expect(find.text('420'), findsOneWidget);
      expect(find.text('GET SIRVYA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MealShareSheet', () {
    testWidgets('opens sheet and toggles formats', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final meal = testMeal();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showMealShareModal(context, meal),
                child: const Text('Open Share'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share'));
      await tester.pumpAndSettle();

      expect(find.text('Share Your Meal'), findsOneWidget);
      expect(find.text('Story (9:16)'), findsOneWidget);
      expect(find.text('Post Card'), findsOneWidget);
      expect(find.text('Share Story / Post'), findsOneWidget);
      expect(find.text('Copy Caption & Link'), findsOneWidget);

      // Switch to Post Card
      await tester.tap(find.text('Post Card'));
      await tester.pumpAndSettle();

      expect(find.text('Share Story / Post'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MealResultView share banner & action', () {
    testWidgets('shows share button in app bar and share banner in body',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final meal = testMeal();
      await tester.pumpWidget(
        MaterialApp(
          home: MealResultView(
            meal: meal,
            saving: false,
            onSave: () {},
            onEdit: (_) {},
            onRemove: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Share meal'), findsOneWidget);
      expect(find.text('Share meal card'), findsOneWidget);

      // Tap share banner
      await tester.tap(find.text('Share meal card'));
      await tester.pumpAndSettle();

      expect(find.text('Share Your Meal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
