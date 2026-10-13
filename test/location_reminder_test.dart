import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/location_reminder.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  for (final role in ['client', 'coach']) {
    for (final enable in [false, true]) {
      testWidgets('$role location reminder fits narrow screens and returns $enable', (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        bool? result;
        await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Builder(
          builder: (context) => Scaffold(body: TextButton(onPressed: () async {
            result = await showDialog<bool>(context: context,
                builder: (_) => LocationReminderDialog(role: role));
          }, child: const Text('Open'))),
        )));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text(role == 'coach' ? 'Help nearby clients find you' : 'Find coaches closer to you'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(enable ? 'Enable location' : 'Not now'));
        await tester.pumpAndSettle();
        expect(result, enable);
        expect(find.byType(LocationReminderDialog), findsNothing);
      });
    }
  }
}
