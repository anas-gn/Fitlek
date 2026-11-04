import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitlek1/screens/ENG/clientConversation.dart';
import 'package:fitlek1/screens/ENG/coachChat.dart';
import 'package:fitlek1/models/coachConversation.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  testWidgets('ClientConversation report and block submit correct payloads to UGC',
      (tester) async {
    final recordedRequests = <http.Request>[];
    final client = MockClient((request) async {
      if (request is http.Request) {
        recordedRequests.add(request);
      }
      if (request.url.path.contains('/messages/')) {
        return http.Response('[]', 200);
      }
      if (request.url.path.endsWith('/ugc/report')) {
        return http.Response(jsonEncode({'success': true}), 200);
      }
      if (request.url.path.endsWith('/ugc/block')) {
        return http.Response(jsonEncode({'success': true}), 200);
      }
      return http.Response('{}', 200);
    });
    addTearDown(client.close);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: ClientConversationScreen(
        conversationID: 42,
        clientID: 10,
        coachID: 99,
        token: 'test-token',
        coachName: 'Coach John',
        connectRealtime: false,
        httpClient: client,
      ),
    ));
    await tester.pumpAndSettle();

    // 1. Open popup menu and tap Report Coach
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Report Coach'), findsOneWidget);
    await tester.tap(find.text('Report Coach'));
    await tester.pumpAndSettle();

    // Select reason and submit
    expect(find.text('Spam'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // Check report request
    final reportReq = recordedRequests.firstWhere(
      (r) => r.url.path.endsWith('/ugc/report'),
    );
    final reportBody = jsonDecode(reportReq.body);
    expect(reportBody['reportedID'], 99);
    expect(reportBody['reason'], 'Spam');
    expect(reportBody['type'], 'user');
    expect(reportBody['entityID'], 42);

    // 2. Open popup menu and tap Block Coach
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Block Coach'), findsOneWidget);
    await tester.tap(find.text('Block Coach'));
    await tester.pumpAndSettle();

    expect(find.text('Block Coach John?'), findsOneWidget);
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();

    // Check block request
    final blockReq = recordedRequests.firstWhere(
      (r) => r.url.path.endsWith('/ugc/block'),
    );
    final blockBody = jsonDecode(blockReq.body);
    expect(blockBody['blockedID'], 99);
  });
}

