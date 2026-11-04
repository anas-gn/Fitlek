import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/account_password_sheet.dart';
import 'package:fitlek1/services/account_security.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  testWidgets(
      'password form validates, shows server errors and completes a retry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var calls = 0;
    bool? result;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    child: const Text('Open'),
                    onPressed: () async {
                      result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AccountPasswordSheet(
                              token: 'test',
                              save: (current, password) async {
                                calls++;
                                expect(current, ' old password ');
                                expect(password, 'newPassword123');
                                if (calls == 1)
                                  throw const PasswordUpdateException(
                                      'Incorrect current password');
                              }));
                    })))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' old password ');
    await tester.enterText(fields.at(1), 'newPassword123');
    await tester.enterText(fields.at(2), 'different');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(fields.at(2), 'newPassword123');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect current password'), findsOneWidget);
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });
}
