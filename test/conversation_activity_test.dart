import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/conversation_activity.dart';
import 'package:fitlek1/components/ENG/conversationUi.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  testWidgets(
      'typing is throttled, recording heartbeats, and remote indicators expire',
      (tester) async {
    final events = StreamController<Map<String, dynamic>>.broadcast();
    final sent = <String>[];
    var now = DateTime(2026);
    final activity = ConversationActivity(
        conversationID: '1',
        userID: 7,
        events: events.stream,
        send: (room, state) {
          expectSync(room, '1');
          sent.add(state);
        },
        clock: () => now);
    await tester.pumpWidget(MaterialApp(theme:AppTheme.dark,
        home: Scaffold(
            appBar: ConversationHeader(
                name: 'Coach',
                subtitle: 'Fitness coach',
                activity: activity))));
    activity.textChanged('H');
    activity.textChanged('Hi');
    expect(sent, ['typing']);
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(sent.last, 'idle');
    activity.recording(true);
    expect(sent.last, 'recording');
    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(sent.where((v) => v == 'recording').length, 2);
    activity.recording(false);
    expect(sent.last, 'idle');
    events.add({'conversationID': 2, 'userID': 9, 'activity': 'typing'});
    events.add({'conversationID': 1, 'userID': 7, 'activity': 'typing'});
    await tester.pump();
    expect(activity.value, isNull);
    events.add({
      'conversationID': 1,
      'userID': 9,
      'activity': 'typing',
      'expiresInMs': 1000
    });
    await tester.pump();
    await tester.pump();
    expect(activity.value, 'Typing…');
    expect(find.text('Typing…'), findsOneWidget);
    events.add({
      'conversationID': 1,
      'userID': 9,
      'activity': 'recording',
      'expiresInMs': 1000
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('Recording a voice message…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Fitness coach'), findsOneWidget);
    events.add({'conversationID': 1, 'userID': 9, 'activity': 'typing'});
    await tester.pump();
    events.add({'reset': true});
    await tester.pump();
    expect(activity.value, isNull);
    activity.recording(true);
    activity.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(sent.last, 'idle');
    activity.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(sent.last, 'recording');
    activity.dispose();
    expect(sent.last, 'idle');
    await events.close();
    await tester.pumpWidget(const SizedBox());
  });
}
