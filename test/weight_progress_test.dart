import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/weight_progress_view.dart';
import 'package:fitlek1/models/weight_entry.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  final now = DateTime.utc(2026, 10, 15, 18);
  final entries = [
    WeightEntry(id: 1, weight: 72, at: DateTime.utc(2026, 9, 1)),
    WeightEntry(id: 2, weight: 71, at: DateTime.utc(2026, 10, 1)),
    WeightEntry(id: 3, weight: 70.2, at: DateTime.utc(2026, 10, 12)),
    WeightEntry(id: 4, weight: 70.5, at: DateTime.utc(2026, 10, 15)),
  ];
  test('calendar filters and parsing preserve actual UTC records', () {
    expect(weightPeriod(entries.reversed.toList(), 7, now).map((e) => e.id),
        [3, 4]);
    expect(weightPeriod(entries, 30, now).map((e) => e.id), [2, 3, 4]);
    expect(weightPeriod(entries, null, now).length, 4);
    expect(weightChange(.3), '+0.3 kg');
    expect(weightChange(-.3), '−0.3 kg');
    final parsed = WeightEntry.fromJson(
        {'id': 7, 'weight': '68.40', 'createdAt': '2026-10-15T00:30:00+01:00'});
    expect(parsed!.at.day, 14);
    expect(parsed.at.isUtc, true);
    expect(WeightEntry.fromJson({'weight': -5, 'createdAt': '2026-10-15'}),
        isNull);
  });
  for (final dark in [true, false]) {
    testWidgets(
        'chart filters, selection and responsive history work, dark=$dark',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
              body: WeightProgressView(
                  entries: entries,
                  current: 70.5,
                  start: 72,
                  total: 4,
                  bmi: '24.1',
                  now: now,
                  onRefresh: () async {},
                  onAdd: (_) async {}))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('7 days'), 200);
      await tester.ensureVisible(find.text('7 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7 days'));
      await tester.pumpAndSettle();
      final chart = find.byWidgetPredicate((widget) =>
          widget is CustomPaint && widget.painter is WeightTrendPainter);
      await tester.ensureVisible(chart);
      await tester.pumpAndSettle();
      expect(chart, findsOneWidget);
      final rect = tester.getRect(chart);
      await tester.tapAt(Offset(rect.left + 10, rect.center.dy));
      await tester.pumpAndSettle();
      final painter =
          tester.widget<CustomPaint>(chart).painter! as WeightTrendPainter;
      expect(painter.selectedID, 3);
      expect(painter.entries.length, 2);
      await tester.scrollUntilVisible(find.text('Recent weigh-ins'), 200);
      expect(find.text('15 Oct 2026'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('single and empty histories render without inventing progress',
      (tester) async {
    Widget page(List<WeightEntry> data) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
            body: WeightProgressView(
                entries: data,
                current: data.lastOrNull?.weight,
                start: data.firstOrNull?.weight,
                total: data.length,
                bmi: '—',
                now: now,
                onRefresh: () async {},
                onAdd: (_) async {})));
    await tester.pumpWidget(page([]));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Your story starts with one log.'), 200);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is CustomPaint && widget.painter is WeightTrendPainter),
        findsNothing);
    await tester.pumpWidget(page([entries.last]));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.textContaining('Your first point is on the chart.'), 200);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is CustomPaint && widget.painter is WeightTrendPainter),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'logging validates, accepts decimal commas and preserves failed input',
      (tester) async {
    int calls = 0;
    double? value;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => WeightLogSheet(onSave: (weight) async {
                              calls++;
                              value = weight;
                              if (calls == 1) throw Exception('Network');
                            })),
                    child: const Text('Log'))))));
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('weight-log-input'));
    await tester.enterText(input, '-1');
    await tester.tap(find.text('Save weigh-in'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.enterText(input, '70,5');
    await tester.tap(find.text('Save weigh-in'));
    await tester.pumpAndSettle();
    expect(value, 70.5);
    expect(tester.widget<TextField>(input).controller!.text, '70,5');
    expect(find.textContaining('Could not save.'), findsOneWidget);
    await tester.tap(find.text('Save weigh-in'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(WeightLogSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
