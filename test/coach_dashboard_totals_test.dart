import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/screens/ENG/coachDashboard.dart';
import 'package:fitlek1/theme/fitlek_theme_extension.dart';

void main() {
  testWidgets('dashboard displays API prices and percentages for each period',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final paths = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [FitlekColors.dark]),
      home: CoachDashboard(load: (path) async {
        paths.add(path);
        final week = path.contains('period=week');
        return {
          'ok': true,
          'isVerified': true,
          'totalReservations': week ? 0 : 4,
          'confirmedReservations': week ? 0 : 3,
          'pendingReservations': week ? 0 : 1,
          'confirmedValue': week ? '0.00' : '750.50',
          'totalClients': 6,
          'periodClients': 2
        };
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text('750.50 MAD'), findsOneWidget);
    expect(find.text('75.0% of total'), findsOneWidget);
    expect(find.text('25.0% of total'), findsOneWidget);
    expect(paths.where((path) => path.contains('/coach/dashboard')).length, 3);
    final requestCount = paths.length;
    await tester.tap(find.text('This Week'));
    await tester.pump();
    expect(find.text('0.00 MAD'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(paths.length, requestCount);
    expect(find.text('0.00 MAD'), findsOneWidget);
    expect(find.text('0.0% of total'), findsNWidgets(2));
    await tester.tap(find.text('Today'));
    await tester.pump();
    expect(find.text('750.50 MAD'), findsOneWidget);
    expect(paths.length, requestCount);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
