import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { resolveIngredient, decorateMeal, publicIngredientCatalog } from '../services/ingredientCatalog.js';

test('aliases and standardized keys resolve to Sirvya-hosted thumbnails', () => {
  assert.equal(resolveIngredient({ name: 'Eggs' }).image_key, 'egg');
  assert.equal(resolveIngredient({ name: 'Courgette' }).image_key, 'zucchini');
  assert.equal(resolveIngredient({ name: 'Huile d’olive' }).image_key, 'olive-oil');
  assert.equal(resolveIngredient({ name: 'نعناع' }).image_key, 'fresh-mint');
});
test('chicken preparation stays distinct even when AI supplies an incorrect raw image key', () => {
  const raw = resolveIngredient({ name: 'Raw chicken breast', preparation: 'raw', image_key: 'chicken-breast' });
  const grilled = resolveIngredient({ name: 'Grilled chicken breast', preparation: 'grilled', image_key: 'chicken-breast' });
  const fried = resolveIngredient({ name: 'Fried chicken breast', preparation: 'fried', image_key: 'chicken-breast' });
  assert.equal(raw.image_key, 'chicken-breast');
  assert.equal(grilled.image_key, 'grilled-chicken');
  assert.equal(fried.image_key, 'fried-chicken');
  assert.equal(grilled.image_is_generic, true);
  assert.equal(fried.image_is_generic, true);
  assert.notEqual(raw.image_url, grilled.image_url);
});
test('unknown foods and cooked meat without suitable artwork use neutral fallback', () => {
  assert.equal(resolveIngredient({ name: 'Unknown Moroccan dish', image_key: '../../secret' }).image_key, 'generic');
  assert.equal(resolveIngredient({ name: 'Fried salmon', image_key: 'salmon', preparation: 'fried' }).image_key, 'generic');
});
test('image matching never modifies quantity, calories or macros', () => {
  const ingredient = { name: 'Grilled chicken breast', image_key: 'chicken-breast', grams: 150, quantity: '150 g', calories: 248, protein: 46, carbs: 0, fat: 5.4 };
  const output = decorateMeal({ ingredients: [ingredient] }).ingredients[0];
  for (const key of ['grams', 'quantity', 'calories', 'protein', 'carbs', 'fat']) assert.equal(output[key], ingredient[key]);
  assert.equal(ingredient.image_key, 'chicken-breast');
});
test('catalog has food metadata and every hosted image exists', () => {
  const catalog = publicIngredientCatalog();
  assert.ok(catalog.records.length >= 90);
  for (const record of catalog.records) {
    assert.equal(typeof record.name, 'string');
    assert.ok(Array.isArray(record.aliases));
    assert.equal(typeof record.category, 'string');
    assert.match(record.image_url, /^\/api\/meals\/ingredients\/[a-z0-9-]+\.webp$/);
    assert.ok(fs.existsSync(new URL('../public/ingredients/' + record.image, import.meta.url)), record.key);
    assert.equal(record.calories, undefined); // No nutrition imported into the image catalog.
  }
});
