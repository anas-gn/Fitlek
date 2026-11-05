import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'meal_scan_service.dart';

class FoodItem {
  final String id;
  final String name;
  final String category;
  final double calories; // per 100g
  final double protein; // per 100g
  final double carbs; // per 100g
  final double fat; // per 100g
  final String? localImage; // e.g. "chicken-breast.webp"
  final String? remoteImageUrl;
  final String? brand;
  final String? emoji;
  final bool isOnline;
  final List<String> aliases;

  const FoodItem({
    required this.id,
    required this.name,
    this.category = 'other',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.localImage,
    this.remoteImageUrl,
    this.brand,
    this.emoji,
    this.isOnline = false,
    this.aliases = const [],
  });

  factory FoodItem.fromLocalJson(Map<String, dynamic> j) => FoodItem(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? 'other',
        calories: (j['cal'] as num?)?.toDouble() ?? 0.0,
        protein: (j['p'] as num?)?.toDouble() ?? 0.0,
        carbs: (j['c'] as num?)?.toDouble() ?? 0.0,
        fat: (j['f'] as num?)?.toDouble() ?? 0.0,
        localImage: j['img'] as String?,
        emoji: j['emoji'] as String?,
        aliases: (j['aliases'] as List?)?.map((e) => '$e').toList() ?? const [],
      );

  factory FoodItem.fromOpenFoodFacts(Map<String, dynamic> p) {
    final nut = (p['nutriments'] as Map<String, dynamic>?) ?? const {};

    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    double kcal = parseNum(nut['energy-kcal_100g']);
    if (kcal == 0.0) kcal = parseNum(nut['energy-kcal']);
    if (kcal == 0.0) kcal = parseNum(nut['energy-kcal_value']);
    if (kcal == 0.0) {
      final kj = parseNum(nut['energy_100g']);
      if (kj > 0) {
        kcal = kj / 4.184;
      } else {
        final kjAlt = parseNum(nut['energy-kj_100g']);
        if (kjAlt > 0) kcal = kjAlt / 4.184;
      }
    }

    double protein = parseNum(nut['proteins_100g']);
    if (protein == 0.0) protein = parseNum(nut['proteins']);
    if (protein == 0.0) protein = parseNum(nut['proteins_value']);

    double carbs = parseNum(nut['carbohydrates_100g']);
    if (carbs == 0.0) carbs = parseNum(nut['carbohydrates']);
    if (carbs == 0.0) carbs = parseNum(nut['carbohydrates_value']);

    double fat = parseNum(nut['fat_100g']);
    if (fat == 0.0) fat = parseNum(nut['fat']);
    if (fat == 0.0) fat = parseNum(nut['fat_value']);

    String? parseBrand(dynamic b) {
      if (b == null) return null;
      if (b is String) {
        final t = b.trim();
        return t.isEmpty ? null : t;
      }
      if (b is List) {
        final list =
            b.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
        return list.isEmpty ? null : list.join(', ');
      }
      return null;
    }

    final brand = parseBrand(p['brands']);

    String rawName = (p['product_name'] as String?)?.trim() ??
        (p['product_name_en'] as String?)?.trim() ??
        (p['generic_name'] as String?)?.trim() ??
        (p['generic_name_en'] as String?)?.trim() ??
        '';

    if (rawName.isEmpty && brand != null && brand.isNotEmpty) {
      rawName = brand;
    } else if (rawName.isEmpty) {
      rawName = 'Unknown food item';
    }

    final img = (p['image_front_small_url'] as String?) ??
        (p['image_small_url'] as String?) ??
        (p['image_front_url'] as String?) ??
        (p['image_url'] as String?);

    final rawCode = p['code'] != null
        ? '${p['code']}'
        : 'off_${DateTime.now().millisecondsSinceEpoch}';

    String displayName = rawName;
    if (brand != null &&
        brand.isNotEmpty &&
        !rawName.toLowerCase().contains(brand.toLowerCase())) {
      displayName = '$rawName ($brand)';
    }

    return FoodItem(
      id: rawCode,
      name: displayName,
      category: 'packaged',
      calories: double.parse(kcal.toStringAsFixed(1)),
      protein: double.parse(protein.toStringAsFixed(1)),
      carbs: double.parse(carbs.toStringAsFixed(1)),
      fat: double.parse(fat.toStringAsFixed(1)),
      remoteImageUrl: img,
      brand: brand,
      isOnline: true,
    );
  }

  MealIngredient toIngredient({required double grams}) {
    final factor = grams / 100.0;
    return MealIngredient(
      name: name,
      grams: grams,
      quantity: '${grams.round()} g',
      calories: double.parse((calories * factor).toStringAsFixed(1)),
      protein: double.parse((protein * factor).toStringAsFixed(1)),
      carbs: double.parse((carbs * factor).toStringAsFixed(1)),
      fat: double.parse((fat * factor).toStringAsFixed(1)),
      imageKey:
          localImage != null ? localImage!.replaceAll('.webp', '') : 'generic',
      imageUrl: remoteImageUrl ?? '',
    );
  }
}

class FoodNutritionService {
  FoodNutritionService._();
  static final FoodNutritionService instance = FoodNutritionService._();

  List<FoodItem> _localFoods = [];
  bool _initialized = false;
  final Map<String, List<FoodItem>> _onlineCache = {};

  static String _clean(String text) => text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '');

  Future<void> init() async {
    if (_initialized) return;
    try {
      final jsonStr = await rootBundle
          .loadString('assets/ingredients/food_database.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = (data['records'] as List? ?? [])
          .map((item) => FoodItem.fromLocalJson(item as Map<String, dynamic>))
          .toList();
      _localFoods = list;
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to load local food database: $e');
    }
  }

  List<FoodItem> searchLocal(String query, {String? category, int limit = 25}) {
    final q = _clean(query);
    Iterable<FoodItem> pool = _localFoods;
    if (category != null && category.isNotEmpty && category != 'all') {
      pool = pool.where((item) => item.category == category);
    }

    if (q.isEmpty) {
      return pool.take(limit).toList();
    }

    final scored = <MapEntry<FoodItem, int>>[];
    for (final item in pool) {
      final nameClean = _clean(item.name);
      final idClean = _clean(item.id);
      int score = 0;

      if (nameClean == q || idClean == q) {
        score = 100;
      } else if (nameClean.startsWith(q)) {
        score = 80;
      } else if (nameClean.split(' ').any((w) => w.startsWith(q))) {
        score = 65;
      } else if (nameClean.contains(q)) {
        score = 45;
      } else if (item.aliases.any((a) => _clean(a).startsWith(q))) {
        score = 35;
      } else if (item.aliases.any((a) => _clean(a).contains(q))) {
        score = 25;
      }

      if (score > 0) {
        scored.add(MapEntry(item, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(limit).toList();
  }

  Future<List<FoodItem>> searchOnline(String query, {int limit = 10}) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final cacheKey = q.toLowerCase();
    if (_onlineCache.containsKey(cacheKey)) {
      return _onlineCache[cacheKey]!;
    }

    const userAgent =
        'FitlekApp - Android - Version 1.0 (contact@fitlek.app)';

    List<FoodItem> parseItems(List rawList) {
      final results = <FoodItem>[];
      for (final p in rawList) {
        if (p is Map<String, dynamic>) {
          final item = FoodItem.fromOpenFoodFacts(p);
          if (item.name.isNotEmpty && item.name != 'Unknown food item') {
            results.add(item);
          }
        }
      }
      return results;
    }

    // Attempt 1: Search-a-licious (Elasticsearch backend, fast & reliable)
    try {
      final uri = Uri.parse(
        'https://search.openfoodfacts.org/search?q=${Uri.encodeComponent(q)}&page_size=$limit',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': userAgent,
      }).timeout(const Duration(seconds: 7));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final hits = data['hits'] as List? ?? [];
        final items = parseItems(hits);
        if (items.isNotEmpty) {
          _onlineCache[cacheKey] = items;
          return items;
        }
      }
    } catch (e) {
      debugPrint('Search-a-licious query failed ($e), falling back to v2 search...');
    }

    // Attempt 2: Open Food Facts API v2 search with projection (fields=)
    try {
      const fields =
          'code,product_name,product_name_en,generic_name,brands,nutriments,image_front_small_url,image_small_url,image_url';
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/search?search_terms=${Uri.encodeComponent(q)}&fields=$fields&page_size=$limit',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': userAgent,
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final products = data['products'] as List? ?? [];
        final items = parseItems(products);
        if (items.isNotEmpty) {
          _onlineCache[cacheKey] = items;
          return items;
        }
      }
    } catch (e) {
      debugPrint('Open Food Facts v2 search fallback failed: $e');
    }

    return const [];
  }

  Future<List<FoodItem>> search({
    required String query,
    String? category,
    bool autoFallbackOnline = true,
  }) async {
    await init();
    final local = searchLocal(query, category: category);

    // If query is specific and local database has few matches, query Open Food Facts
    if (autoFallbackOnline && query.trim().length >= 2 && local.length < 2) {
      final online = await searchOnline(query);
      if (online.isNotEmpty) {
        final existingNames = local.map((e) => _clean(e.name)).toSet();
        final combined = List<FoodItem>.from(local);
        for (final item in online) {
          if (!existingNames.contains(_clean(item.name))) {
            combined.add(item);
          }
        }
        return combined;
      }
    }

    return local;
  }
}
