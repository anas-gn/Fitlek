import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitlek1/models/anas/coach.dart';
import 'package:fitlek1/components/ENG/exploreCoachGrid.dart';
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

  test('coach cards and coach details do not have hardcoded dark green colors', () {
    for (final path in [
      'lib/screens/ENG/clientList.dart',
      'lib/screens/ENG/clientCoachDetail.dart',
    ]) {
      final file = File(path);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        expect(content.contains('0xFF13322B'), isFalse,
            reason: '$path should not contain hardcoded dark green 0xFF13322B');
        expect(content.contains('0xFF0F2C24'), isFalse,
            reason: '$path should not contain hardcoded dark green 0xFF0F2C24');
        expect(content.contains('0xFF0C2420'), isFalse,
            reason: '$path should not contain hardcoded dark green 0xFF0C2420');
      }
    }
  });

  testWidgets('explore coach grid in light mode uses light card background',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final coach = CoachModel.fromJson({
      'id': 1,
      'firstName': 'Anas',
      'lastName': 'Coach',
      'ville': 'Casablanca',
      'specialties': ['Fitness', 'Cardio'],
      'isApproved': 1,
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ExploreCoachGrid(
          coaches: [coach],
          favorites: const {},
          ratings: const {1: 5.0},
          reviewCounts: const {1: 4},
          onOpen: (_) {},
          onFavorite: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final materialFinder = find.byType(Material);
    expect(materialFinder, findsWidgets);
    final cardMaterial = tester.widget<Material>(
        find.byKey(const ValueKey(1)));
    expect(cardMaterial.color, AppTheme.light.extension<FitlekColors>()!.card);
    expect(find.text('Anas Coach'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
