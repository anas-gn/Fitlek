import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/components/connection_recovery_prompt.dart';
import 'package:fitlek1/screens/ENG/clientSessions.dart';
import 'package:fitlek1/services/connection_recovery.dart';
import 'package:fitlek1/services/socketService.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConnectionRecovery.failure.value = null;
  });
  tearDown(() {
    ConnectionRecovery.failure.value = null;
    SocketService().disconnect();
  });

  test('only transport failures produce a connection notice', () {
    expect(ConnectionRecovery.report(const FormatException('Invalid JSON')),
        false);
    expect(ConnectionRecovery.failure.value, isNull);
    expect(ConnectionRecovery.report(TimeoutException('Slow request')), true);
    expect(ConnectionRecovery.failure.value, ConnectionRecovery.message);
  });

  testWidgets(
      'one popup handles a failure burst and Refresh app reloads sessions',
      (tester) async {
    var offline = true;
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      if (offline) throw http.ClientException('Offline');
      return http.Response('[]', 200);
    });
    addTearDown(client.close);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      navigatorKey: navigator,
      builder: (_, child) =>
          ConnectionRecoveryPrompt(navigatorKey: navigator, child: child!),
      home: SessionsScreen(clientID: 8, token: 'test', httpClient: client),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Check your connection'), findsOneWidget);
    ConnectionRecovery.report(http.ClientException('Another failed request'));
    await tester.pumpAndSettle();
    expect(find.text('Check your connection'), findsOneWidget);
    offline = false;
    await tester.tap(find.text('Refresh app'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Check your connection'), findsNothing);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('No upcoming sessions.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('empty and failed sessions can both be pulled down to refresh',
      (tester) async {
    var offline = false;
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      if (offline) throw http.ClientException('Offline');
      return http.Response('[]', 200);
    });
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: SessionsScreen(clientID: 8, token: 'test', httpClient: client),
    ));
    await tester.pumpAndSettle();
    offline = true;
    await tester.drag(find.byType(ListView).first, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Try again'), findsOneWidget);
    offline = false;
    await tester.drag(find.byType(ListView).first, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(requests, 3);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('No upcoming sessions.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
