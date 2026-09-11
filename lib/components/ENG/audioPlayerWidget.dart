import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../services/audioManager.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? url;
  final bool isMe;
  final bool isExpired;

  const AudioPlayerWidget({
    super.key,
    required this.url,
    required this.isMe,
    required this.isExpired,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoaded = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _localCacheExpired = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.url == null || widget.url!.isEmpty) return;

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    if (widget.url == null || widget.url!.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(widget.url!);
      if (fileInfo != null) {
        await _player.setSourceDeviceFile(fileInfo.file.path);
        _isLoaded = true;
      } else {
        if (widget.isExpired) {
          _localCacheExpired = true;
        } else {
          final file = await DefaultCacheManager().downloadFile(widget.url!);
          await _player.setSourceDeviceFile(file.file.path);
          _isLoaded = true;
        }
      }
    } catch (e) {
      if (widget.isExpired) _localCacheExpired = true;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_localCacheExpired || !_isLoaded) return;
    if (_isPlaying) {
      _player.pause();
    } else {
      AudioManager().playNew(_player, widget.url!);
      _player.play(_player.source!);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final fgColor = widget.isMe ? cs.onPrimary : cs.onSurface;

    if (widget.isExpired && _localCacheExpired) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_off_rounded, color: fgColor.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 8),
          Text('Audio Expired', style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isMe ? cs.onPrimary.withValues(alpha: 0.2) : cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: _isLoading 
                ? Padding(padding: const EdgeInsets.all(10), child: CircularProgressIndicator(color: fgColor, strokeWidth: 2))
                : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: widget.isMe ? cs.onPrimary : cs.primary, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 4,
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _duration.inMilliseconds > 0 ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0) : 0.0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isMe ? cs.onPrimary : cs.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDuration(_position.inMilliseconds > 0 ? _position : _duration),
              style: TextStyle(color: fgColor.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
