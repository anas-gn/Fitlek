import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/meal_scan_limit_dialog.dart';
import 'package:fitlek1/services/meal_scan_service.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  for (final limit in [3, 7, 0, 5]) {
    testWidgets('quota pop-up reflects configured limit $limit',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          // The scanner uses its own ThemeData without app theme extensions.
          theme: limit == 5 ? ThemeData.dark() : AppTheme.light,
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => MealScanLimitDialog(
                              dailyLimit: limit, used: limit)),
                      child: const Text('Scan'))))));
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();
      expect(find.text('$limit / $limit scans used today'), findsOneWidget);
      expect(find.text('$limit ${limit == 1 ? 'scan' : 'scans'} per day'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(MealScanLimitDialog), findsNothing);
    });
  }
  test('quota response preserves customized limits and bonus credits', () {
    final exception = MealScanLimitException.fromJson(
        {'dailyLimit': 7, 'bonus': 2, 'used': 9});
    expect(exception.dailyLimit, 7);
    expect(exception.bonus, 2);
    expect(exception.used, 9);
  });
}
