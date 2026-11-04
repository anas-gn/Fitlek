import 'package:flutter/material.dart';
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
    final total = dailyLimit + bonus;
    return AppDialog(
      icon: const Icon(Icons.hourglass_bottom_rounded),
      title: Text(total == 0
          ? 'Meal scans are paused'
          : 'You’re all scanned for today'),
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
                    Text('$used / $total scans used today',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                        '$dailyLimit ${dailyLimit == 1 ? 'scan' : 'scans'} per day${bonus > 0 ? ' + $bonus extra today' : ''}'),
                  ]),
            ),
            const SizedBox(height: 18),
            Text(total == 0
                ? 'Meal scanning is currently disabled for your account. Your admin can update your allowance.'
                : 'You’ve reached your allowance for today. Come back after midnight UTC for your next daily scans, or ask your admin for extra scans.'),
          ]),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'))
      ],
    );
  }
}
