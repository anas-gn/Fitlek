import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/ENG/coachHeader.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('coach avatar uses only the intended right inset at $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      var opened = false;
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
              body: CoachHeader(
                  coachName: 'Sirvya Coach',
                  avatarUrl: '',
                  unreadCount: 1,
                  onAvatarTap: () => opened = true))));
      await tester.pumpAndSettle();
      final avatar = find.bySemanticsLabel(RegExp('^Open Coach Profile'));
      expect(tester.getRect(avatar).right, closeTo(width - 20, .1));
      expect(tester.getSize(avatar).width, 44);
      await tester.tap(avatar);
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
