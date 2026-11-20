import 'package:flutter/material.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../services/nutrition_diary_service.dart';
import 'meal_visuals.dart';

String _localizedMealTypeLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'breakfast' => l10n.mealDiaryTypeBreakfast,
      'lunch' => l10n.mealDiaryTypeLunch,
      'dinner' => l10n.mealDiaryTypeDinner,
      'snack' => l10n.mealDiaryTypeSnack,
      _ => mealTypeLabel(value),
    };

Future<String?> chooseMealCategory(BuildContext context,
        {required String initialType, bool moving = false}) =>
    showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: mealInk,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) =>
            MealCategorySheet(initialType: initialType, moving: moving));

class MealCategorySheet extends StatefulWidget {
  final String initialType;
  final bool moving;
  const MealCategorySheet(
      {super.key, required this.initialType, this.moving = false});
  @override
  State<MealCategorySheet> createState() => _MealCategorySheetState();
}

class _MealCategorySheetState extends State<MealCategorySheet> {
  late String _selected =
      mealTypes.contains(widget.initialType) ? widget.initialType : 'lunch';
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedLabel = _localizedMealTypeLabel(l10n, _selected);
    return SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: mealMuted.withValues(alpha: .3),
                              borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                        child: Text(
                            widget.moving
                                ? l10n.mealDiaryMoveTitle
                                : l10n.mealDiarySaveTitle,
                            style: const TextStyle(
                                color: mealCream,
                                fontSize: 26,
                                fontWeight: FontWeight.w800))),
                    IconButton(
                        tooltip: l10n.mealDiaryCancel,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: mealMuted))
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      widget.moving
                          ? l10n.mealDiaryMoveSubtitle
                          : l10n.mealDiarySaveSubtitle,
                      style: const TextStyle(color: mealMuted, fontSize: 13)),
                  const SizedBox(height: 22),
                  for (final type in mealTypes)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Semantics(
                            selected: _selected == type,
                            child: Material(
                              color:
                                  _selected == type ? mealCream : mealSurface,
                              borderRadius: BorderRadius.circular(17),
                              child: ListTile(
                                key: ValueKey('choose-meal-$type'),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 3),
                                leading: Icon(
                                    switch (type) {
                                      'breakfast' => Icons.wb_twilight_rounded,
                                      'lunch' => Icons.wb_sunny_outlined,
                                      'dinner' => Icons.nights_stay_outlined,
                                      _ => Icons.apple_outlined
                                    },
                                    color:
                                        _selected == type ? mealInk : mealLime),
                                title: Text(_localizedMealTypeLabel(l10n, type),
                                    style: TextStyle(
                                        color: _selected == type
                                            ? mealInk
                                            : mealCream,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                trailing: Icon(
                                    _selected == type
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color:
                                        _selected == type ? mealInk : mealMuted,
                                    size: 22),
                                onTap: () => setState(() => _selected = type),
                              ),
                            ))),
                  const SizedBox(height: 12),
                  SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: mealCream,
                            foregroundColor: mealInk),
                        onPressed: () => Navigator.pop(context, _selected),
                        child: Text(
                            widget.moving
                                ? l10n.mealDiaryMoveTo(selectedLabel)
                                : l10n.mealDiarySaveTo(selectedLabel),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      )),
                ])));
  }
}

Future<bool> confirmMealDeletion(BuildContext context, String name) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            backgroundColor: mealSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            icon: const Icon(Icons.delete_outline_rounded,
                color: mealCarbs, size: 30),
            title: Text(l10n.mealDiaryDeleteTitle,
                style: const TextStyle(
                    color: mealCream, fontWeight: FontWeight.w800)),
            content: Text(l10n.mealDiaryDeleteBody(name),
                style: const TextStyle(color: mealMuted, height: 1.5)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.mealDiaryKeepMeal,
                      style: const TextStyle(color: mealCream))),
              FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: mealCream, foregroundColor: mealInk),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.mealDiaryDeleteMeal)),
            ],
          );
        }) ??
    false;
