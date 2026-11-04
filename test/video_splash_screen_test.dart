import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:fitlek1/components/video_splash_screen.dart';

class FakeIntroPlayer extends VideoPlayerPlatform {
  final events = StreamController<VideoEvent>.broadcast();
  bool failPlay = false;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setMixWithOthers(bool mix) async {}
  @override
  Future<void> play(int playerId) async {
    if (failPlay) throw PlatformException(code: 'play_failed');
  }

  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

void main() {
  late VideoPlayerPlatform original;
  late FakeIntroPlayer player;
  setUp(() {
    original = VideoPlayerPlatform.instance;
    player = FakeIntroPlayer();
    VideoPlayerPlatform.instance = player;
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = original;
    await player.events.close();
  });
  Future<void> start(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: VideoSplashScreen(
            nextScreen: Scaffold(body: Text('Session ready')))));
    await tester.pump();
  }

  Future<void> initialize(WidgetTester tester) async {
    player.events.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 3),
        size: const Size(1920, 1080)));
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('native completion reaches next screen without resuming the app',
      (tester) async {
    await start(tester);
    await initialize(tester);
    player.events.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pump();
    await tester.pump();
    expect(find.text('Session ready'), findsOneWidget);
    await close(tester);
  });
  testWidgets(
      'initialization failure reaches next screen without another frame event',
      (tester) async {
    await start(tester);
    player.events.addError(PlatformException(
        code: 'video_unavailable', message: 'Could not open video'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Session ready'), findsOneWidget);
    await close(tester);
  });
  testWidgets('playback failure reaches next screen', (tester) async {
    player.failPlay = true;
    await start(tester);
    await initialize(tester);
    await tester.pump();
    expect(find.text('Session ready'), findsOneWidget);
    await close(tester);
  });
  testWidgets('stalled native player cannot keep the app on a black screen',
      (tester) async {
    await start(tester);
    await initialize(tester);
    await tester.pump(const Duration(seconds: 26));
    expect(find.text('Session ready'), findsOneWidget);
    await close(tester);
  });
  testWidgets('intro fills the screen and tapping skips without a skip button',
      (tester) async {
    await start(tester);
    await initialize(tester);
    expect(find.text('Skip intro'), findsNothing);
    expect(tester.widget<FittedBox>(find.byType(FittedBox)).fit, BoxFit.cover);
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();
    expect(find.text('Session ready'), findsOneWidget);
    await close(tester);
  });
  testWidgets('disposing while initializing cancels the fallback safely',
      (tester) async {
    await start(tester);
    await close(tester);
    await tester.pump(const Duration(seconds: 26));
    expect(tester.takeException(), isNull);
  });
  testWidgets('tapping skips even while the player is still initializing',
      (tester) async {
    await start(tester);
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(find.text('Session ready'), findsOneWidget);
    await close(tester);
  });
}
