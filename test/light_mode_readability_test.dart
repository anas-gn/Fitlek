import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitlek1/screens/ENG/clientSessions.dart';
import 'package:fitlek1/screens/ENG/coachDashboard.dart';
import 'package:fitlek1/theme/app_theme.dart';
import 'package:fitlek1/theme/fitlek_theme_extension.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + 0.05) / ((x < y ? x : y) + 0.05);
}

void main() {
  testWidgets('coach dashboard remains readable in light mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: CoachDashboard(
          load: (path) async => path.startsWith('/coach/dashboard')
              ? {'ok': true, 'isVerified': false}
              : {'ok': true, 'isApproved': 0},
        )));
    await tester.pumpAndSettle();
    expect(find.text('Verification pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('light text and status colors remain readable on cards', () {
    final theme = AppTheme.light;
    final colors = theme.extension<FitlekColors>()!;
    for (final color in [
      theme.colorScheme.onSurface,
      colors.textSecondary,
      colors.textMuted,
      colors.success,
      colors.warning,
      colors.error,
      colors.info
    ]) {
      expect(contrast(color, colors.card), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(theme.colorScheme.primary, theme.colorScheme.onPrimary),
        greaterThanOrEqualTo(4.5));
  });
  for (final light in [true, false]) {
    testWidgets(
        'sessions title and coach card use ${light ? 'light' : 'dark'} colors',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = MockClient((request) async => http.Response(
          jsonEncode([
            {
              'id': 1,
              'clientID': 2,
              'coachID': 3,
              'coachName': 'Coach Test',
              'reservedDate': '2030-10-12',
              'reservedTime': '19:00:00',
              'status': 'pending',
              'location': 'Coach gym',
              'price': 100,
            }
          ]),
          200));
      addTearDown(client.close);
      final theme = light ? AppTheme.light : AppTheme.dark;
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home:
              SessionsScreen(clientID: 2, token: 'test', httpClient: client)));
      await tester.pumpAndSettle();
      final title = tester.widget<Text>(find.text('My sessions'));
      expect(title.style?.color, theme.colorScheme.onSurface);
      final coach = tester.widget<Text>(find.text('Coach Test'));
      expect(coach.style?.color, theme.colorScheme.onSurface);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
