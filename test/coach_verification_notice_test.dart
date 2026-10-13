import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/screens/ENG/coachDashboard.dart';
import 'package:fitlek1/theme/fitlek_theme_extension.dart';

void main() {
  testWidgets('notice disappears when verification completes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool verified = false;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [FitlekColors.dark]),
        home: CoachDashboard(
            load: (path) async => path.startsWith('/coach/dashboard')
                ? {'ok': true, 'isVerified': verified}
                : {'ok': true, 'isApproved': verified ? 1 : 0})));
    await tester.pumpAndSettle();
    expect(find.text('Verification pending'), findsOneWidget);
    expect(find.textContaining('up to 48 hours'), findsOneWidget);
    expect(tester.takeException(), isNull);
    verified = true;
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Verification pending'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

