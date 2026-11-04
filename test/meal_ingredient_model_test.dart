import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/meal_scan_service.dart';

void main() {
  test('old saved ingredients remain readable without image metadata', () {
    final ingredient = MealIngredient.fromJson({
      'name': 'Chicken',
      'grams': 100,
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fat': 3.6
    });
    expect(ingredient.imageKey, 'generic');
    expect(ingredient.calories, 165);
  });
  test('portion edits keep image identity separate from scaled nutrition', () {
    const ingredient = MealIngredient(
        name: 'Grilled chicken',
        grams: 100,
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        imageKey: 'grilled-chicken',
        imageUrl: '/api/meals/ingredients/generic.webp',
        preparation: 'grilled',
        quantity: '1 piece');
    final changed = ingredient.withGrams(200);
    final restored = MealIngredient.fromJson(changed.toJson());
    expect(restored.imageKey, ingredient.imageKey);
    expect(restored.imageUrl, ingredient.imageUrl);
    expect(restored.preparation, 'grilled');
    expect(restored.calories, 330);
    expect(restored.quantity, '200 g');
  });
}
