# Sirvya ingredient imagery

The curated catalog has 99 entries, including 91 downloaded Ingredient Atlas thumbnails and a Sirvya neutral-bowl illustration. It covers common Moroccan meal components, including mint, dates, couscous, chickpeas, preserved lemon, harissa, olive oil, eggs, poultry, vegetables and grains. Prepared-food entries without suitable artwork deliberately use the neutral bowl.

## Storage and hosting

- `data/ingredients.json`: canonical key, display name, aliases, category, preparation, image filename, license, original source URL and source SHA-256.
- `public/ingredients/`: checked-in 256px WebP thumbnails. They survive Heroku restarts because they are deployment assets, rather than runtime uploads.
- `GET /api/meals/catalog`: public catalog with relative image URLs.
- `GET /api/meals/ingredients/<filename>.webp`: Sirvya-hosted thumbnails with seven-day caching.
- The mobile app bundles the same small thumbnail collection as an offline fallback, using the server image URL when available.

This does not create or modify MySQL tables. Meal history stays in the existing per-user device storage.

## Matching and nutrition

The scanner requests `name`, `image_key`, `preparation` and readable `quantity` alongside numeric grams/calories/macros. The server resolves only known catalog keys or aliases; an AI response cannot inject an arbitrary image URL. French and Arabic aliases are supported. Existing saved meals without image metadata remain readable.

Grilled, fried, roasted and raw chicken resolve to separate entries. When an exact preparation-specific image is absent, the server uses the neutral bowl rather than illustrating a cooked food with raw meat. Unknown foods use the same generic fallback. Catalog images are illustrations and are not used to calculate or change calories, grams, protein, carbs or fat.

Ingredient Atlas metadata and AI-generated images are CC0-1.0. Original licensing and provenance: https://github.com/ionmesca/ingredient-atlas/blob/main/LICENSE-DATA.md. The source checksums were verified before image resizing. No Atlas nutrition metadata is imported.

Run `node --test test/meal_analysis.test.mjs test/ingredient_catalog.test.mjs` to verify API request compatibility, alias matching, preparation distinctions, fallback coverage and nutrition independence.
