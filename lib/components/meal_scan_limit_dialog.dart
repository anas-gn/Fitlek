import 'package:flutter/material.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import 'app_dialog.dart';

class MealScanLimitDialog extends StatelessWidget {
  final int dailyLimit, bonus, used;
  const MealScanLimitDialog(
      {super.key,
      required this.dailyLimit,
      required this.used,
      this.bonus = 0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = dailyLimit + bonus;
    return AppDialog(
      icon: const Icon(Icons.hourglass_bottom_rounded),
      title: Text(total == 0
          ? l10n.mealScanLimitPausedTitle
          : l10n.mealScanLimitReachedTitle),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mealScanLimitUsedToday(used, total),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(bonus > 0
                        ? l10n.mealScanLimitPerDayWithBonus(dailyLimit, bonus)
                        : l10n.mealScanLimitPerDay(dailyLimit)),
                  ]),
            ),
            const SizedBox(height: 18),
            Text(total == 0
                ? l10n.mealScanLimitPausedBody
                : l10n.mealScanLimitReachedBody),
          ]),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.mealScanLimitGotIt))
      ],
    );
  }
}
