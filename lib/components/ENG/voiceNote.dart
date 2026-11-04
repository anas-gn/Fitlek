import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/audioManager.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? url, localPath;
  final bool isMe, isExpired;
  const AudioPlayerWidget(
      {super.key,
      required this.url,
      this.localPath,
      required this.isMe,
      required this.isExpired});
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with AutomaticKeepAliveClientMixin {
  // Untapped voice notes do not create a native player or prepare a source.
  AudioPlayer? _player;
  final _subscriptions = <StreamSubscription>[];
  bool _playing = false, _loading = false, _loaded = false;
  String? _error;
  Duration _duration = Duration.zero, _position = Duration.zero;
  double _rate = 1;
  static final _durations = <String, Duration>{};
  String get _key => widget.localPath ?? widget.url ?? '';
  @override
  bool get wantKeepAlive => _playing || _loading;
  @override
  void initState() {
    super.initState();
    _duration = _durations[_key] ?? Duration.zero;
  }

  @override
  void didUpdateWidget(AudioPlayerWidget old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.localPath != widget.localPath) {
      _disposePlayer();
      _playing = false;
      _loaded = false;
      _loading = false;
      _error = null;
      _position = Duration.zero;
      _duration = _durations[_key] ?? Duration.zero;
    }
  }

  void _disposePlayer() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    final player = _player;
    _player = null;
    if (player != null) {
      AudioManager().release(player);
      unawaited(player.dispose());
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _onPlayerError(Object error) {
    if (!mounted) return;
    setState(() {
      _error = 'Tap to retry';
      _loaded = false;
      _loading = false;
      _playing = false;
    });
    updateKeepAlive();
  }

  Future<void> _toggle() async {
    if (_loading ||
        _key.isEmpty ||
        (widget.localPath == null && widget.isExpired)) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    updateKeepAlive();
    try {
      final player = _player ??= AudioPlayer();
      if (_subscriptions.isEmpty) {
        _subscriptions.add(player.onPlayerStateChanged
            .handleError(_onPlayerError)
            .listen((state) {
          if (!mounted) return;
          setState(() => _playing = state == PlayerState.playing);
          updateKeepAlive();
        }));
        _subscriptions.add(player.onDurationChanged
            .handleError(_onPlayerError)
            .listen((duration) {
          _durations[_key] = duration;
          if (_durations.length > 200) _durations.remove(_durations.keys.first);
          if (mounted) setState(() => _duration = duration);
        }));
        _subscriptions.add(player.onPositionChanged
            .handleError(_onPlayerError)
            .listen((position) {
          if (mounted) setState(() => _position = position);
        }));
        _subscriptions.add(
            player.onPlayerComplete.handleError(_onPlayerError).listen((_) {
          if (!mounted) return;
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
          updateKeepAlive();
        }));
      }
      if (_playing) {
        await player.pause();
      } else {
        await AudioManager().playNew(player, _key);
        if (!mounted) return;
        if (!_loaded) {
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setSource(kIsWeb && widget.localPath == null
              ? UrlSource(widget.url!)
              : DeviceFileSource(widget.localPath ?? widget.url!));
          _loaded = true;
        }
        if (!mounted || !AudioManager().isCurrentlyPlaying(_key)) return;
        if (player.state == PlayerState.completed) {
          await player.seek(Duration.zero);
        }
        await player.setPlaybackRate(_rate);
        await player.resume();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Tap to retry';
          _loaded = false;
          _playing = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        updateKeepAlive();
      }
    }
  }

  Future<void> _seek(double fraction) async {
    if (!_loaded || _loading || _duration == Duration.zero) return;
    final position = Duration(
        milliseconds:
            (_duration.inMilliseconds * fraction.clamp(0, 1)).round());
    try {
      await _player?.seek(position);
      if (mounted) setState(() => _position = position);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tap to retry');
    }
  }

  Future<void> _speed() async {
    final rate = _rate == 1
        ? 1.5
        : _rate == 1.5
            ? 2.0
            : 1.0;
    try {
      await _player?.setPlaybackRate(rate);
      if (mounted) setState(() => _rate = rate);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tap to retry');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VoiceNoteControls(
        isMe: widget.isMe,
        playing: _playing,
        loading: _loading,
        duration: _duration,
        position: _position,
        rate: _rate,
        error: _error,
        onPlay: _toggle,
        onSeek: _seek,
        onSpeed: _speed);
  }
}

/// Lightweight waveform-style seek surface; the bars do not claim to show
/// measured amplitude. Actual duration and progress come from the player.
class VoiceNoteControls extends StatelessWidget {
  final bool isMe, playing, loading;
  final Duration duration, position;
  final double rate;
  final String? error;
  final VoidCallback onPlay, onSpeed;
  final ValueChanged<double> onSeek;
  const VoiceNoteControls(
      {super.key,
      required this.isMe,
      this.playing = false,
      this.loading = false,
      this.duration = Duration.zero,
      this.position = Duration.zero,
      this.rate = 1,
      this.error,
      required this.onPlay,
      required this.onSeek,
      required this.onSpeed});
  @override
  Widget build(BuildContext context) {
    final ink = isMe
        ? const Color(0xFF123E37)
        : Theme.of(context).colorScheme.onSurface;
    final accent = isMe ? const Color(0xFF267567) : const Color(0xFFB6E3D3);
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final time = position > Duration.zero ? position : duration;
    return SizedBox(
        width: 280,
        height: 53,
        child: Row(children: [
          SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                  tooltip: loading
                      ? 'Loading voice message'
                      : error != null
                          ? 'Retry voice message'
                          : playing
                              ? 'Pause voice message'
                              : 'Play voice message',
                  onPressed: loading ? null : onPlay,
                  style: IconButton.styleFrom(
                      backgroundColor:
                          accent.withValues(alpha: isMe ? .18 : .28)),
                  icon: loading
                      ? SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: ink))
                      : Icon(
                          error != null
                              ? Icons.refresh_rounded
                              : playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          size: 28,
                          color: isMe ? ink : const Color(0xFFD7EEE4)))),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                LayoutBuilder(
                    builder: (context, constraints) => Semantics(
                        label: 'Voice message seek bar',
                        value: '${(progress * 100).round()} percent',
                        child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (d) => onSeek(
                                (d.localPosition.dx / constraints.maxWidth)
                                    .clamp(0.0, 1.0)),
                            onHorizontalDragUpdate: (d) => onSeek(
                                (d.localPosition.dx / constraints.maxWidth)
                                    .clamp(0.0, 1.0)),
                            child: CustomPaint(
                                size: const Size(double.infinity, 30),
                                painter: VoiceWavePainter(progress, accent,
                                    ink.withValues(alpha: .38)))))),
                if (duration == Duration.zero || error != null)
                  Text(error ?? (loading ? 'Loading…' : 'Voice note'),
                      maxLines: 1,
                      style: TextStyle(
                          color: ink.withValues(alpha: .65), fontSize: 10)),
              ])),
          if (duration > Duration.zero) ...[
            const SizedBox(width: 7),
            Text(
                '${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}',
                style:
                    TextStyle(color: ink.withValues(alpha: .75), fontSize: 11))
          ],
          const SizedBox(width: 6),
          SizedBox(
              width: 39,
              height: 32,
              child: TextButton(
                  onPressed: loading ? null : onSpeed,
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      foregroundColor: ink,
                      backgroundColor: ink.withValues(alpha: .09),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9))),
                  child: Text(
                      '${rate == rate.roundToDouble() ? rate.toInt() : rate}×',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)))),
        ]));
  }
}

class VoiceWavePainter extends CustomPainter {
  final double progress;
  final Color active, idle;
  const VoiceWavePainter(this.progress, this.active, this.idle);
  static const heights = [
    8,
    14,
    24,
    16,
    30,
    20,
    12,
    26,
    18,
    10,
    22,
    15,
    28,
    19,
    12,
    24,
    16,
    29,
    21,
    13,
    25,
    18,
    10,
    22,
    15,
    27,
    18,
    12,
    20,
    14,
    8,
    12
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final count = (size.width / 4).floor().clamp(1, 64);
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final x = (i + .5) * size.width / count;
      final height = heights[i % heights.length].toDouble();
      paint.color = x / size.width <= progress ? active : idle;
      canvas.drawLine(Offset(x, (size.height - height) / 2),
          Offset(x, (size.height + height) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(VoiceWavePainter old) =>
      progress != old.progress || active != old.active || idle != old.idle;
}
