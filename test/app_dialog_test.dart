import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/app_dialog.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  for (final light in [true, false]) {
    testWidgets(
        'input dialog scrolls on small screens and retains its action, light=$light',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? result;
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
          theme: light ? AppTheme.light : AppTheme.dark,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      child: const Text('Open'),
                      onPressed: () async {
                        result = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AppDialog(
                                    title: const Text('Add your expertise'),
                                    content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(List.filled(12,
                                                  'Help clients discover what you do best.')
                                              .join(' ')),
                                          TextField(
                                              controller: controller,
                                              decoration: const InputDecoration(
                                                  labelText: 'Specialty')),
                                        ]),
                                    actions: [
                                      FilledButton(
                                          onPressed: () => Navigator.pop(
                                              ctx, controller.text),
                                          child: const Text('Save'))
                                    ]));
                      })))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Strength training');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 'Strength training');
      expect(tester.takeException(), isNull);
      controller.dispose();
    });
  }
}
