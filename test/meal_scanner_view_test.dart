import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/meal_scanner_view.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
        'scanner fits $width and keeps analysis disabled until a photo exists',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final notes = TextEditingController();
      var captured = false;
      var portion = 1.0;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: StatefulBuilder(
              builder: (_, update) => MealScannerView(
                    busy: false,
                    picking: false,
                    portion: portion,
                    notes: notes,
                    cameraPreview: const ColoredBox(
                        key: ValueKey('embedded-preview'), color: Colors.black),
                    onCamera: () => captured = true,
                    onGallery: () {},
                    onHistory: () {},
                    onAnalyze: () {},
                    onPortion: (value) => update(() => portion = value),
                    frameOverlay: const SizedBox.shrink(),
                  ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('embedded-preview')), findsOneWidget);
      expect(find.text('Let’s take a look'), findsNothing);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull);
      await tester
          .ensureVisible(find.byKey(const ValueKey('meal-capture-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('meal-capture-button')));
      expect(captured, isTrue);
      await tester.ensureVisible(find.text('½ plate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('½ plate'));
      await tester.pumpAndSettle();
      expect(portion, .5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      notes.dispose();
    });
  }
}
