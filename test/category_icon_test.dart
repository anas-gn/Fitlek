import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/category_icon.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('mobile icon identifiers match the admin catalogue and all assets parse', () async {
    final catalogue = jsonDecode(await rootBundle.loadString('assets/category_icons/catalogue.json')) as List;
    expect(catalogue.map((icon) => (icon['key'] as String).split(':').last).toSet(), CategoryIcon.ids);
    for (final icon in catalogue) {
      final asset = CategoryIcon.assetFor(icon['key']);
      expect(asset, isNotNull);
      final picture = await vg.loadPicture(SvgAssetLoader(asset!), null);
      expect(picture.size.width, greaterThan(0));
      picture.picture.dispose();
    }
  });
  for (final light in [true, false]) {
    testWidgets('selected SVG renders with theme color and unknown icons fall back, light=$light', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: light ? AppTheme.light : AppTheme.dark,
        home: const Scaffold(body: Row(children: [CategoryIcon(name: 'svgrepo:28674'),
          CategoryIcon(name: 'fitness_center'), CategoryIcon(name: 'svgrepo:unknown')]))));
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsNWidgets(2));
      expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
