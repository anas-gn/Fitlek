import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/screens/ENG/clientProfil.dart';
import 'package:fitlek1/services/theme_service.dart';
import 'package:fitlek1/components/theme_selector.dart';
import 'package:fitlek1/theme/app_theme.dart';
import 'package:fitlek1/models/client_profile_completion.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Map<String, dynamic> fixture() => {
        'id': 7,
        'firstName': 'Amal',
        'lastName': 'Client',
        'email': 'amal@example.test',
        'phoneNumber': '',
        'ville': 'El Jadida',
        'gender': 'Female',
        'height': null,
        'avatarUrl': '',
        'interests': '["Yoga"]'
      };
  MockClient api(Map<String, dynamic> saved) => MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/clients/me')) {
          if (request.method == 'PUT') {
            saved.addAll(jsonDecode(request.body) as Map<String, dynamic>);
            return http.Response(jsonEncode({'profile': saved}), 200);
          }
          return http.Response(jsonEncode(saved), 200);
        }
        if (path.endsWith('/stats')) {
          return http.Response('{"currentWeight":null,"totalEntries":0}', 200);
        }
        if (path.endsWith('/categories')) {
          return http.Response(
              '[{"name":"Yoga","icon":"self_improvement"},{"name":"Swimming","icon":"fitness_center"}]',
              200);
        }
        return http.Response('[]', 200);
      });
  Widget app(http.Client client, ThemeController controller,
          {Key? key, bool dark = true, double scale = 1}) =>
      ThemeControllerScope(
          controller: controller,
          child: MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: ClientProfileScreen(
                key: key,
                clientID: 7,
                token: 'test',
                embedded: true,
                apiClient: client),
          ));

  testWidgets(
      'edits only advance completion after server confirmation and survive reopening',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final saved = fixture();
    final controller = ThemeController();
    // Use one mutable server fixture across opening/saving/reopening the page.
    final server = api(saved);
    addTearDown(server.close);
    addTearDown(controller.dispose);
    await tester.pumpWidget(app(server, controller));
    await tester.pumpAndSettle();
    expect(find.text('My profile'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('Weight loss and toning'), findsNothing);
    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    final name = find.byKey(const ValueKey('client-profile-First name'));
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Amina');
    final height = find.byKey(const ValueKey('client-profile-Height (cm)'));
    await tester.ensureVisible(height);
    await tester.enterText(height, '172,5');
    await tester.pump();
    expect(saved['height'], isNull);
    expect(ClientProfileCompletion(saved).percent, 62);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(saved['firstName'], 'Amina');
    expect(saved['height'], 172.5);
    expect(ClientProfileCompletion(saved).percent, 75);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(app(server, controller, key: UniqueKey()));
    await tester.pumpAndSettle();
    expect(find.text('Amina Client'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saved weigh-in is posted and reloaded into the progress view',
      (tester) async {
    final logs = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/clients/me')) {
        return http.Response(jsonEncode(fixture()), 200);
      }
      if (path.endsWith('/weight-history') && request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['clientID'], 7);
        logs.add({
          'id': 12,
          'weight': body['weight'],
          'createdAt': DateTime.now().toUtc().toIso8601String()
        });
        return http.Response('{"id":12}', 201);
      }
      if (path.endsWith('/weight-history/me')) {
        return http.Response(jsonEncode(logs), 200);
      }
      if (path.endsWith('/stats')) {
        return http.Response(
            jsonEncode({
              'currentWeight': logs.lastOrNull?['weight'],
              'startWeight': logs.firstOrNull?['weight'],
              'totalEntries': logs.length
            }),
            200);
      }
      return http.Response('[]', 200);
    });
    final controller = ThemeController();
    addTearDown(controller.dispose);
    addTearDown(client.close);
    await tester.pumpWidget(app(client, controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My progress', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My progress'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Log weight'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Log weight'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('weight-log-input')), '68,4');
    await tester.tap(find.text('Save weigh-in'));
    await tester.pumpAndSettle();
    expect(logs.single['weight'], 68.4);
    expect(find.text('68.4'), findsOneWidget);
    expect(find.byKey(const ValueKey('weight-log-input')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final dark in [true, false]) {
    testWidgets(
        'small profile scrolls through settings and weight tracking, dark=$dark',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = api(fixture()), controller = ThemeController();
      addTearDown(client.close);
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(client, controller, dark: dark, scale: 1.3));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('My progress', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My progress', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Log a weigh-in'), 200,
          scrollable: find.byType(Scrollable).last);
      expect(find.text('Log a weigh-in'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
