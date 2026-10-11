import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlatform extends VideoPlayerPlatform {
  final events = <String>[];
  final streams = <int, StreamController<VideoEvent>>{};
  int sequence = 0;
  bool failNextCreation = false;
  @override
  Future<void> init() async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (failNextCreation) {
      failNextCreation = false;
      throw StateError('Player unavailable');
    }
    events.add('asset:${options.dataSource.asset}');
    events.add('uri:${options.dataSource.uri}');
    final id = ++sequence;
    streams[id] = StreamController<VideoEvent>();
    streams[id]!.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 12),
        size: const Size(640, 360)));
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;

  @override
  Future<void> play(int playerId) async {
    events.add('play:$playerId');
  }

  @override
  Future<void> pause(int playerId) async {
    events.add('pause:$playerId');
  }

  @override
  Future<void> dispose(int playerId) async {
    events.add('dispose:$playerId');
    await streams.remove(playerId)?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    events.add('loop:$looping');
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    events.add('volume:$volume');
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}
