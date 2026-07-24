import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitlek1/main.dart';
import 'package:fitlek1/services/theme_service.dart';

void main() {
  testWidgets('Fitlek app smoke test', (WidgetTester tester) async {
    final themeController = ThemeController();
    await themeController.load();

    await tester.pumpWidget(Fitlek(themeController: themeController));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
