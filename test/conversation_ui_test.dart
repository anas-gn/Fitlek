import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/components/ENG/conversationUi.dart';
import 'package:fitlek1/components/ENG/audioPlayerWidget.dart';
import 'package:fitlek1/components/ENG/localChatMedia.dart';
import 'package:fitlek1/services/chat_media_store.dart';
import 'package:fitlek1/screens/ENG/clientConversation.dart';
import 'package:fitlek1/screens/ENG/coachChat.dart';
import 'package:fitlek1/models/coachConversation.dart';
import 'package:fitlek1/theme/app_theme.dart';

Map<String, dynamic> row(int id) => {
      'id': id,
      'conversationID': 1,
      'senderID': 9,
      'body': 'Message $id. A little planning for our next session.',
      'mediaType': 'text',
      'isRead': true,
      'createdAt': DateTime(2026, 10, 16, 10)
          .add(Duration(minutes: id))
          .toIso8601String()
    };

class WaitingMedia extends ChatMediaStore {
  final pending = Completer<SavedChatMedia>();
  int reads = 0;
  @override
  Future<SavedChatMedia> resolve(
      int id, String? url, String type, bool expired) {
    reads++;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.llfbandit.record/messages'),
            (_) async => null);
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'), null));

  for (final dark in [true, false]) {
    testWidgets('composer and voice controls fit a small screen, dark=$dark',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final text = TextEditingController();
      addTearDown(text.dispose);
      var sends = 0, plays = 0, speeds = 0;
      double? seek;
      await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
              appBar: const ConversationHeader(
                  name: 'Mohssine Kamal', subtitle: 'Fitness coach'),
              body: Column(children: [
                Expanded(
                    child: ConversationBubble(
                        message: ChatEntry(
                            id: '12',
                            time: DateTime(2026, 10, 16, 16, 9),
                            mine: true,
                            body: 'See you tomorrow 👋',
                            read: true))),
                Container(
                    color: const Color(0xFFF1EDE2),
                    padding: const EdgeInsets.all(12),
                    child: VoiceNoteControls(
                        isMe: true,
                        duration: const Duration(seconds: 24),
                        position: const Duration(seconds: 8),
                        onPlay: () => plays++,
                        onSpeed: () => speeds++,
                        onSeek: (v) => seek = v)),
                ConversationComposer(
                    controller: text,
                    recording: false,
                    busy: false,
                    onAttach: () {},
                    onGallery: () {},
                    onRecord: () {},
                    onSend: () => sends++),
              ]))));
      await tester.pump();
      expect(find.byTooltip('Record voice message'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      expect(sends, 1);
      await tester.tap(find.byTooltip('Play voice message'));
      expect(plays, 1);
      await tester.tap(find.text('1×'));
      expect(speeds, 1);
      final wave = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is VoiceWavePainter);
      await tester.tapAt(tester.getTopLeft(wave) +
          Offset(tester.getSize(wave).width * .75, 15));
      expect(seek, closeTo(.75, .02));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('untapped audio does not allocate native players',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ListView(children: [
      for (var i = 0; i < 12; i++)
        AudioPlayerWidget(
            url: 'https://test/$i.m4a',
            localPath: '/phone/$i.m4a',
            isMe: i.isEven,
            isExpired: false)
    ]))));
    await tester.pumpAndSettle(); // No platform mock is needed before playback.
    expect(find.text('Voice note'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'photo loading and missing states keep their size and ignore other downloads',
      (tester) async {
    final store = WaitingMedia();
    addTearDown(store.mediaChanges.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 280,
                child: LocalChatMedia(
                    messageID: 5,
                    url: 'https://test/photo.jpg',
                    type: 'image',
                    expired: false,
                    isMe: true,
                    store: store)))));
    await tester.pump();
    final before = tester.getSize(find.byType(AspectRatio));
    expect(find.text('Downloading…'), findsOneWidget);
    store.mediaChanges.add(99);
    await tester.pump();
    expect(store.reads, 1);
    store.pending.complete(const SavedChatMedia());
    await tester.pump();
    await tester.pump();
    expect(find.text("Not on this device"), findsOneWidget);
    expect(tester.getSize(find.byType(AspectRatio)), before);
    expect(tester.takeException(), isNull);
  });

  for (final coach in [false, true]) {
    testWidgets(
        '${coach ? 'coach' : 'client'} loads older pages at the top without losing the reading position',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = Completer<List<Map<String, dynamic>>>();
      final older = Completer<List<Map<String, dynamic>>>();
      final requests = <int>[];
      Future<List<Map<String, dynamic>>> history(Uri uri) async {
        final page = int.parse(uri.queryParameters['page']!);
        requests.add(page);
        return page == 1 ? first.future : older.future;
      }

      final client = MockClient(
          (r) async => http.Response(jsonEncode(await history(r.url)), 200));
      addTearDown(client.close);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: coach
              ? CoachChat(
                  conversation: CoachConversation(
                      id: '1',
                      clientId: '7',
                      clientName: 'Mehdi',
                      clientPhotoUrl: '',
                      lastMessage: '',
                      lastMessageTime: DateTime(2026),
                      unreadCount: 0),
                  connectRealtime: false,
                  loadData: (path) async => path == '/coach/profile'
                      ? {'ok': true, 'id': 9}
                      : {'ok': true, 'data': await history(Uri.parse(path))})
              : ClientConversationScreen(
                  conversationID: 1,
                  clientID: 7,
                  token: 'test',
                  coachName: 'Mohssine',
                  connectRealtime: false,
                  httpClient: client)));
      await tester.pump();
      expect(find.text('Loading conversation…'), findsOneWidget);
      final latest = [for (var i = 51; i <= 100; i++) row(i)];
      first.complete(latest);
      await tester.pumpAndSettle();
      expect(requests, [1]);
      final controller = tester
          .widget<ConversationTimeline>(find.byType(ConversationTimeline))
          .controller;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(requests, [1, 2]);
      final message =
          find.text('Message 51. A little planning for our next session.');
      final offset = controller.offset;
      final y = tester.getTopLeft(message).dy;
      older.complete([for (var i = 1; i <= 50; i++) row(i)]);
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(offset, 1));
      expect(tester.getTopLeft(message).dy, closeTo(y, 1));
      latest.removeAt(0);
      latest.add(row(101));
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refresh messages'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(message).dy, closeTo(y, 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('failed text send shows loading and restores the draft for retry',
      (tester) async {
    final sent = Completer<http.Response>();
    final client = MockClient((r) async =>
        r.method == 'POST' ? await sent.future : http.Response('[]', 200));
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: ClientConversationScreen(
            conversationID: 1,
            clientID: 7,
            token: 'test',
            connectRealtime: false,
            httpClient: client)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Please keep this draft');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    expect(find.text('Sending message…'), findsOneWidget);
    sent.complete(http.Response('Server unavailable', 503));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Please keep this draft');
    expect(find.byTooltip('Send message'), findsOneWidget);
    expect(find.text('Sending message…'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
