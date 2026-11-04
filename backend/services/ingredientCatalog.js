import fs from 'node:fs';
const catalog = JSON.parse(fs.readFileSync(new URL('../data/ingredients.json', import.meta.url), 'utf8'));
export const normalizeIngredient = value => String(value ?? '').normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
  .toLowerCase().replace(/[^a-z0-9\u0600-\u06ff]+/g, '-').replace(/^-|-$/g, '');
const byKey = new Map(catalog.records.map(item => [item.key, item]));
const aliases = new Map();
for (const item of catalog.records) for (const name of [item.key, item.name, ...item.aliases]) aliases.set(normalizeIngredient(name), item);
const preparations = new Set(['raw', 'grilled', 'fried', 'roasted', 'boiled', 'steamed', 'cooked', 'unknown']);
export function resolveIngredient(ingredient) {
  const name = normalizeIngredient(ingredient.name);
  const inferred = /(^|-)(grilled|grille)(-|$)/.test(name) ? 'grilled'
    : /(^|-)(fried|breaded|frit)(-|$)/.test(name) ? 'fried'
    : /(^|-)(raw|uncooked|cru)(-|$)/.test(name) ? 'raw'
    : /(^|-)(roasted|rotisserie|roti)(-|$)/.test(name) ? 'roasted'
    : /(^|-)(cooked|boiled|steamed|stewed|cuit)(-|$)/.test(name) ? 'cooked' : 'unknown';
  const preparation = inferred !== 'unknown' ? inferred : preparations.has(ingredient.preparation) ? ingredient.preparation : 'unknown';
  let record;
  if (/chicken|poulet/.test(name)) {
    const key = preparation === 'grilled' ? 'grilled-chicken' : preparation === 'fried' ? 'fried-chicken'
      : preparation === 'roasted' ? 'rotisserie-chicken' : ['boiled', 'steamed', 'cooked'].includes(preparation) ? 'cooked-chicken' : null;
    if (key) record = byKey.get(key);
  }
  if (!record && /(^|-)(rice|riz)(-|$)/.test(name) && ['cooked', 'boiled', 'steamed'].includes(preparation)) record = byKey.get('cooked-white-rice');
  if (!record && /couscous/.test(name) && ['cooked', 'boiled', 'steamed'].includes(preparation)) record = byKey.get('cooked-couscous');
  if (!record) record = aliases.get(name) || byKey.get(normalizeIngredient(ingredient.image_key));
  if (record && ['meat', 'seafood'].includes(record.category) && record.preparation === 'raw'
      && preparation !== 'unknown' && preparation !== 'raw') record = null;
  record ||= byKey.get('generic');
  return { ...ingredient, image_key: record.key, standardized_name: record.name,
    preparation, category: record.category, image_url: '/api/meals/ingredients/' + record.image,
    image_is_generic: record.image === 'generic.webp' };
}
export function decorateMeal(meal) { return { ...meal, ingredients: meal.ingredients.map(resolveIngredient) }; }
export function publicIngredientCatalog() {
  return { version: catalog.version, records: catalog.records.map(({ source_sha256, ...item }) => ({ ...item, image_url: '/api/meals/ingredients/' + item.image })) };
}
export const ingredientCatalogPrompt = catalog.records.filter(item => item.key !== 'generic')
  .map(item => `${item.key}: ${item.name}${item.preparation === 'unknown' ? '' : ' (' + item.preparation + ')'}`).join('; ');
