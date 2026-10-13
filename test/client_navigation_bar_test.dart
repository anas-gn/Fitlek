import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/ENG/clientNavigationBar.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  for (final width in [320.0, 390.0, 800.0]) {
    for (final light in [false, true]) {
      testWidgets('fixed client navigation fits $width, light=$light and changes tabs', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var selected = 0;
        await tester.pumpWidget(MaterialApp(theme: light ? AppTheme.light : AppTheme.dark,
          home: StatefulBuilder(builder: (context, update) => Scaffold(
            body: ListView(children: List.generate(30, (i) => SizedBox(height: 60, child: Text('Row $i')))),
            bottomNavigationBar: ClientNavigationBar(currentIndex: selected,
              onSelected: (index) => update(() => selected = index)),
          )),
        ));
        final position = tester.getTopLeft(find.text('Home'));
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Home')), position);
        for (final tab in ['Explore', 'Sessions', 'Profile', 'Home']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(selected, ['Home', 'Explore', 'Sessions', 'Profile'].indexOf(tab));
          expect(tester.widget<ClientNavigationBar>(find.byType(ClientNavigationBar)).currentIndex, selected);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
