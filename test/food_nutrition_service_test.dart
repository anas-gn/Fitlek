import 'package:fitlek1/services/food_nutrition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FoodItem calculations', () {
    test('calculates correct calories and macros for grams', () {
      const food = FoodItem(
        id: 'chicken-breast',
        name: 'Chicken Breast (cooked)',
        category: 'meat',
        calories: 165.0,
        protein: 31.0,
        carbs: 0.0,
        fat: 3.6,
        localImage: 'chicken-breast.webp',
      );

      // 150 grams
      final ingredient = food.toIngredient(grams: 150.0);
      expect(ingredient.name, 'Chicken Breast (cooked)');
      expect(ingredient.grams, 150.0);
      expect(ingredient.quantity, '150 g');
      expect(ingredient.calories, closeTo(247.5, 0.1));
      expect(ingredient.protein, closeTo(46.5, 0.1));
      expect(ingredient.carbs, 0.0);
      expect(ingredient.fat, closeTo(5.4, 0.1));
      expect(ingredient.imageKey, 'chicken-breast');
    });

    test('handles fallback when no local image exists', () {
      const food = FoodItem(
        id: 'quinoa-flour',
        name: 'Quinoa Flour',
        category: 'grains',
        calories: 368.0,
        protein: 14.0,
        carbs: 64.0,
        fat: 6.0,
        localImage: null,
      );

      final ingredient = food.toIngredient(grams: 50.0);
      expect(ingredient.imageKey, 'generic');
      expect(ingredient.calories, closeTo(184.0, 0.1));
      expect(ingredient.protein, closeTo(7.0, 0.1));
    });
  });

  group('Open Food Facts parser', () {
    test('parses Search-a-licious hit with brand as list and standard nutriments', () {
      final hit = {
        'code': '57045399',
        'product_name': 'Coca-Cola',
        'brands': ['coca cola', 'The Coca-Cola Company'],
        'image_front_small_url': 'https://images.openfoodfacts.org/front.jpg',
        'nutriments': {
          'energy-kcal_100g': 42.0,
          'proteins_100g': 0.0,
          'carbohydrates_100g': 10.6,
          'fat_100g': 0.0,
        }
      };

      final item = FoodItem.fromOpenFoodFacts(hit);
      expect(item.id, '57045399');
      expect(item.name.toLowerCase().contains('coca-cola'), isTrue);
      expect(item.calories, 42.0);
      expect(item.carbs, 10.6);
      expect(item.remoteImageUrl, 'https://images.openfoodfacts.org/front.jpg');
      expect(item.isOnline, isTrue);
    });

    test('parses v2 product with brand as string and kJ energy fallback', () {
      final p = {
        'code': '7622210449283',
        'product_name': 'Oreo Original',
        'brands': 'Mondelez',
        'nutriments': {
          'energy_100g': 2010.0, // kJ
          'proteins_100g': 5.2,
          'carbohydrates_100g': 68.0,
          'fat_100g': 20.0,
        }
      };

      final item = FoodItem.fromOpenFoodFacts(p);
      expect(item.name, 'Oreo Original (Mondelez)');
      expect(item.calories, closeTo(480.4, 0.5));
      expect(item.protein, 5.2);
      expect(item.carbs, 68.0);
      expect(item.fat, 20.0);
    });

    test('preserves zero-calorie products like Diet Coke', () {
      final p = {
        'code': '5449000000996',
        'product_name': 'Coca-Cola Zero Sugar',
        'brands': 'Coca-Cola',
        'nutriments': {
          'energy-kcal_100g': 0.3,
          'proteins_100g': 0.0,
          'carbohydrates_100g': 0.0,
          'fat_100g': 0.0,
        }
      };

      final item = FoodItem.fromOpenFoodFacts(p);
      expect(item.calories, 0.3);
      expect(item.name.contains('Coca-Cola Zero Sugar'), isTrue);
    });
  });

  group('FoodNutritionService local search', () {
    test('loads local database and searches correctly', () async {
      final service = FoodNutritionService.instance;
      await service.init();

      final chickenResults = service.searchLocal('chicken');
      expect(chickenResults.isNotEmpty, isTrue);
      expect(chickenResults.any((f) => f.name.toLowerCase().contains('chicken')), isTrue);

      final appleResults = service.searchLocal('apple');
      expect(appleResults.isNotEmpty, isTrue);
      expect(appleResults.first.name.toLowerCase().contains('apple'), isTrue);
      expect(appleResults.first.localImage, isNotNull);

      // Category filter test
      final meatOnly = service.searchLocal('', category: 'meat');
      expect(meatOnly.every((f) => f.category == 'meat'), isTrue);
    });
  });
}

