import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/meal_scan_service.dart';
import '../constants/urls.dart';
import 'meal_share_modal.dart';

const mealInk = Color(0xFF071E19);
const mealSurface = Color(0xFF15372C);
const mealCream = Color(0xFFF3F0E3);
const mealMuted = Color(0xFFA1B6AB);
const mealLime = Color(0xFFC7E59A);
const mealProtein = Color(0xFFBCDFA5);
const mealCarbs = Color(0xFFF2CB84);
const mealFat = Color(0xFFC9B5E7);

class MealPhoto extends StatelessWidget {
  final String path;
  final Uint8List? bytes;
  final BoxFit fit;
  const MealPhoto(
      {super.key, required this.path, this.bytes, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext _, Object __, StackTrace? ___) => Container(
        color: mealSurface,
        child: const Center(
            child: Icon(Icons.restaurant_rounded, size: 56, color: mealLime)));
    if (bytes != null) {
      return Image.memory(bytes!,
          fit: fit, errorBuilder: fallback, gaplessPlayback: true);
    }
    if (path.isEmpty) return fallback(context, '', null);
    if (kIsWeb) {
      return Container(
          color: mealSurface,
          child: const Icon(Icons.restaurant_rounded, color: mealLime));
    }
    return Image.file(File(path), fit: fit, errorBuilder: fallback);
  }
}

class IngredientThumbnail extends StatelessWidget {
  final MealIngredient ingredient;
  final double size;
  const IngredientThumbnail(
      {super.key, required this.ingredient, this.size = 64});
  static final Future<Map<String, String>> _images = _load();
  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  static Future<Map<String, String>> _load() async {
    final data = jsonDecode(
            await rootBundle.loadString('assets/ingredients/catalog.json'))
        as Map<String, dynamic>;
    final map = <String, String>{};
    for (final item in data['records'] as List) {
      for (final key in [
        item['key'],
        item['name'],
        ...item['aliases'] as List
      ]) {
        map[_normalize(key as String)] = item['image'] as String;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) => Semantics(
      label: '${ingredient.name} illustration',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: mealCream, borderRadius: BorderRadius.circular(19)),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FutureBuilder<Map<String, String>>(
                future: _images,
                builder: (context, snapshot) {
                  final images = snapshot.data;
                  var key = ingredient.imageKey == 'generic'
                      ? _normalize(ingredient.name)
                      : _normalize(ingredient.imageKey);
                  // Old saved meals also get preparation-aware fallback artwork.
                  if (key.contains('chicken') || key.contains('poulet')) {
                    if (key.contains('grill') ||
                        ingredient.preparation == 'grilled') {
                      key = 'grilled-chicken';
                    }
                    if (key.contains('fried') ||
                        key.contains('breaded') ||
                        ingredient.preparation == 'fried') {
                      key = 'fried-chicken';
                    }
                    if (key.contains('cooked') ||
                        ingredient.preparation == 'cooked') {
                      key = 'cooked-chicken';
                    }
                  }
                  final image = images?[key] ?? 'generic.webp';
                  final fallback = Image.asset('assets/ingredients/$image',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.rice_bowl_outlined,
                          color: mealSurface,
                          size: 30));
                  final server = Uri.parse(baseUrl);
                  final uri = server.resolve(ingredient.imageUrl);
                  if (ingredient.imageUrl.isNotEmpty &&
                      uri.scheme == 'https' &&
                      uri.host == server.host) {
                    return CachedNetworkImage(
                        imageUrl: uri.toString(),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => fallback,
                        errorWidget: (_, __, ___) => fallback);
                  }
                  return fallback;
                })),
      ));
}

class MealChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  const MealChip(this.label, {super.key, this.icon, this.color = mealLime});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          border: Border.all(color: color.withValues(alpha: .22)),
          borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6)
        ],
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .4))
      ]));
}

class MealResultView extends StatelessWidget {
  final ScannedMeal meal;
  final bool saving;
  final bool saved;
  final VoidCallback onSave;
  final ValueChanged<int?> onEdit;
  final ValueChanged<int> onRemove;
  final Widget? diaryControls;
  const MealResultView(
      {super.key,
      required this.meal,
      required this.saving,
      this.saved = false,
      required this.onSave,
      required this.onEdit,
      required this.onRemove,
      this.diaryControls});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: mealInk,
        bottomNavigationBar: _saveBar(context),
        body: CustomScrollView(slivers: [
          SliverAppBar(
              backgroundColor: mealInk,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              expandedHeight: 305,
              title: const Text('Meal analysis',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              actions: [
                IconButton(
                    tooltip: 'Share meal',
                    onPressed: () => showMealShareModal(context, meal),
                    icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0x88071E19)),
                        child: const Icon(Icons.share_rounded,
                            size: 19, color: mealCream))),
                const SizedBox(width: 8),
              ],
              leading: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0x88071E19)),
                      child: const Icon(Icons.arrow_back, size: 20))),
              flexibleSpace: FlexibleSpaceBar(
                  background: Stack(fit: StackFit.expand, children: [
                MealPhoto(path: meal.photoPath, bytes: meal.photoBytes),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [
                      0,
                      .4,
                      1
                    ],
                            colors: [
                      Color(0x77071E19),
                      Color(0x00071E19),
                      mealInk
                    ]))),
                Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MealChip(
                              meal.confidence == 'manual'
                                  ? 'YOUR MEAL DIARY'
                                  : 'SIRVYA MEAL SCAN',
                              icon: Icons.auto_awesome_rounded),
                          const SizedBox(height: 14),
                          Text(meal.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: mealCream,
                                  fontSize: 27,
                                  height: 1.12,
                                  letterSpacing: -.8,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 9),
                          Row(children: [
                            const Icon(Icons.rice_bowl_outlined,
                                color: mealMuted, size: 15),
                            const SizedBox(width: 7),
                            Expanded(
                                child: Text(
                                    meal.confidence == 'manual'
                                        ? '1 serving · Entered nutrition'
                                        : '${meal.portion == 1 ? '1 plate' : '${meal.portion} plates'} · Estimated nutrition',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: mealMuted, fontSize: 12)))
                          ]),
                        ])),
              ]))),
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              sliver: SliverList.list(children: [
                if (diaryControls != null) ...[
                  diaryControls!,
                  const SizedBox(height: 18)
                ],
                _nutrition(),
                const SizedBox(height: 14),
                _shareBanner(context),
                const SizedBox(height: 22),
                Row(children: [
                  const Expanded(
                      child: Text('Inside your plate',
                          style: TextStyle(
                              color: mealCream,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.5))),
                  Text('${meal.ingredients.length} ingredients',
                      style: const TextStyle(color: mealMuted, fontSize: 11))
                ]),
                const SizedBox(height: 5),
                const Text('Fine-tune portions to make this estimate yours.',
                    style: TextStyle(color: mealMuted, fontSize: 12)),
                const SizedBox(height: 14),
                ...meal.ingredients
                    .asMap()
                    .entries
                    .map((entry) => _ingredient(entry.key, entry.value)),
                const SizedBox(height: 5),
                OutlinedButton.icon(
                    onPressed: saving ? null : () => onEdit(null),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: mealLime,
                        side: BorderSide(color: mealLime.withValues(alpha: .3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add an ingredient')),
                const SizedBox(height: 24),
                _insight(),
                const SizedBox(height: 14),
                Text(
                    meal.confidence == 'manual'
                        ? 'Nutrition is based on the values you entered for this serving.'
                        : 'Ingredient images are illustrations. Nutrition is estimated from your meal photo and portion details.',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: mealMuted, fontSize: 11, height: 1.6)),
              ])),
        ]),
      );

  Widget _nutrition() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF234A37), Color(0xFF112C23)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: mealLime.withValues(alpha: .18))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('TOTAL ENERGY',
                      style: TextStyle(
                          color: mealLime,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8)),
                  const SizedBox(height: 7),
                  FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${meal.total('calories').round()}',
                                style: const TextStyle(
                                    color: mealCream,
                                    fontSize: 55,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -2.5)),
                            const SizedBox(width: 7),
                            const Text('kcal',
                                style:
                                    TextStyle(color: mealMuted, fontSize: 16)),
                          ])),
                  const SizedBox(height: 3),
                  Text(
                      meal.confidence == 'manual'
                          ? 'Nutrition you entered'
                          : 'An estimate of this portion',
                      style: const TextStyle(color: mealMuted, fontSize: 11)),
                ])),
            const SizedBox(width: 14),
            SizedBox(
                width: 88,
                height: 88,
                child: Stack(alignment: Alignment.center, children: [
                  Positioned.fill(
                      child: CustomPaint(painter: _MacroRing(meal))),
                  const Icon(Icons.spa_outlined, color: mealLime, size: 27),
                ]))
          ]),
          const SizedBox(height: 22),
          Container(height: 1, color: mealCream.withValues(alpha: .09)),
          const SizedBox(height: 18),
          Row(children: [
            _macro('Protein', 'protein', mealProtein),
            const SizedBox(width: 8),
            _macro('Carbs', 'carbs', mealCarbs),
            const SizedBox(width: 8),
            _macro('Fat', 'fat', mealFat)
          ]),
        ]),
      );

  Widget _shareBanner(BuildContext context) => InkWell(
        onTap: () => showMealShareModal(context, meal),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C2B24), Color(0xFF08221C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: mealLime.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: mealLime.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.share_rounded, color: mealLime, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share meal card',
                      style: TextStyle(
                        color: mealCream,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Post to Instagram Stories, WhatsApp, or Facebook',
                      style: TextStyle(color: mealMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: mealLime, size: 14),
            ],
          ),
        ),
      );
  Widget _macro(String title, String key, Color color) => Expanded(
      child: Container(
          padding: const EdgeInsets.fromLTRB(11, 12, 9, 12),
          decoration: BoxDecoration(
              color: mealInk.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(14)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Flexible(
                  child: Text(title,
                      style: const TextStyle(color: mealMuted, fontSize: 11)))
            ]),
            const SizedBox(height: 7),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${meal.total(key).round()} g',
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w700))),
          ])));
  Widget _ingredient(int index, MealIngredient ingredient) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
          color: const Color(0xFF102B23),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: saving ? null : () => onEdit(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: mealCream.withValues(alpha: .06))),
                child: Row(children: [
                  IngredientThumbnail(ingredient: ingredient, size: 58),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(ingredient.name,
                            style: const TextStyle(
                                color: mealCream,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.25)),
                        const SizedBox(height: 5),
                        Text(
                            '${ingredient.quantity.isNotEmpty ? ingredient.quantity : '${ingredient.grams.round()} g'} · ${ingredient.calories.round()} kcal',
                            style: const TextStyle(
                                color: mealMuted, fontSize: 11)),
                        if (ingredient.preparation != 'unknown')
                          Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(ingredient.preparation.toUpperCase(),
                                  style: const TextStyle(
                                      color: mealLime,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1))),
                      ])),
                  IconButton(
                      tooltip: 'Edit ${ingredient.name}',
                      visualDensity: VisualDensity.compact,
                      onPressed: saving ? null : () => onEdit(index),
                      icon: const Icon(Icons.tune_rounded,
                          color: mealMuted, size: 19)),
                  if (meal.ingredients.length > 1)
                    PopupMenuButton<String>(
                        tooltip: 'More options for ${ingredient.name}',
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert,
                            color: mealMuted, size: 18),
                        enabled: !saving,
                        onSelected: (_) => onRemove(index),
                        itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remove ingredient'))
                            ]),
                ])),
          )));
  Widget _insight() => Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: mealLime.withValues(alpha: .045),
          border: Border.all(color: mealLime.withValues(alpha: .13)),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
            spacing: 12,
            runSpacing: 9,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome_outlined, color: mealLime, size: 19),
                SizedBox(width: 9),
                Flexible(
                    child: Text('A little context',
                        style: TextStyle(
                            color: mealCream, fontWeight: FontWeight.w600))),
              ]),
              MealChip(
                  meal.confidence == 'manual'
                      ? 'Entered manually'
                      : '${meal.confidence} confidence',
                  color: meal.confidence == 'low' ? mealCarbs : mealLime)
            ]),
        const SizedBox(height: 10),
        Text(meal.notes,
            style:
                const TextStyle(color: mealMuted, fontSize: 12, height: 1.65)),
      ]));
  Widget _saveBar(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: mealInk,
          border:
              Border(top: BorderSide(color: mealCream.withValues(alpha: .08)))),
      child: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                        onPressed: saving ? null : onSave,
                        style: FilledButton.styleFrom(
                            backgroundColor: mealCream,
                            foregroundColor: mealInk,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18))),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Icon(Icons.bookmark_add_outlined, size: 20),
                                    const SizedBox(width: 10),
                                    Flexible(
                                        child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                                saved
                                                    ? 'Save changes'
                                                    : 'Save meal',
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w700)))),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.arrow_forward, size: 18)
                                  ]))),
                const SizedBox(height: 8),
                const Text('Account diary · Photos stay on this device',
                    style: TextStyle(color: mealMuted, fontSize: 10)),
              ]))));
}

class _MacroRing extends CustomPainter {
  final ScannedMeal meal;
  _MacroRing(this.meal);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false,
        paint..color = mealCream.withValues(alpha: .08));
    final values = [
      meal.total('protein') * 4,
      meal.total('carbs') * 4,
      meal.total('fat') * 9
    ];
    final total = values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return;
    var angle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      if (sweep > .08) {
        canvas.drawArc(rect, angle + .04, sweep - .08, false,
            paint..color = [mealProtein, mealCarbs, mealFat][i]);
      }
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(_MacroRing oldDelegate) => true;
}
