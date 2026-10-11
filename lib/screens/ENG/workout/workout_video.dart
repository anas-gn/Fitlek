import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../models/workout_video.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'workout_gif.dart';

class WorkoutVideoPanel extends StatefulWidget {
  final WorkoutVideo video;
  final bool compact;
  const WorkoutVideoPanel(
      {super.key, required this.video, this.compact = false});
  @override
  State<WorkoutVideoPanel> createState() => _WorkoutVideoPanelState();
}

class _WorkoutVideoPanelState extends State<WorkoutVideoPanel>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Object? _error;
  int _generation = 0;
  bool _enabled = true, _foreground = true, _wanted = false;
  bool _initializedPreference = false, _mini = false, _lastPlaying = false;
  bool _savingSize = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mini = WorkoutService.preferences['demonstrationSize'] == 'mini';
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled = TickerMode.valuesOf(context).enabled;
    if (!_initializedPreference) {
      _initializedPreference = true;
      _wanted = !MediaQuery.disableAnimationsOf(context) &&
          !MediaQuery.accessibleNavigationOf(context);
    }
    unawaited(_applyPlayback());
  }

  @override
  void didUpdateWidget(WorkoutVideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.asset != widget.video.asset) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_applyPlayback());
  }

  Future<void> _applyPlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (_enabled && _foreground && _wanted && !_mini) {
        await controller.play();
      } else {
        await controller.pause();
      }
    } catch (_) {
      if (mounted && identical(controller, _controller)) {
        setState(() => _error = 'Video playback unavailable');
      }
    }
  }

  void _changed() {
    final playing = _controller?.value.isPlaying ?? false;
    if (mounted && _controller?.value.hasError == true && _error == null) {
      setState(() => _error = 'Video playback unavailable');
    }
    if (mounted && playing != _lastPlaying) {
      setState(() => _lastPlaying = playing);
    }
  }

  Future<void> _release(VideoPlayerController controller) async {
    // A platform can reject creation before the plugin's creation completer
    // resolves. Cleanup must not prevent the poster and retry control appearing.
    try {
      await controller.dispose().timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final previous = _controller;
    _controller = null;
    previous?.removeListener(_changed);
    if (previous != null) await _release(previous);
    if (!mounted || generation != _generation) return;
    _error = null;
    if (widget.video.isGif) {
      setState(() {});
      return;
    }
    final options = VideoPlayerOptions(allowBackgroundPlayback: true);
    final controller = widget.video.isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.video.asset),
            videoPlayerOptions: options)
        : VideoPlayerController.asset(widget.video.asset,
            videoPlayerOptions: options);
    try {
      await controller.initialize().timeout(const Duration(seconds: 20));
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (!mounted || generation != _generation) {
        await _release(controller);
        return;
      }
      _controller = controller;
      _lastPlaying = controller.value.isPlaying;
      controller.addListener(_changed);
      setState(() => _error = null);
      await _applyPlayback();
    } catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error);
      unawaited(_release(controller));
    }
  }

  Future<void> _size() async {
    if (_savingSize) return;
    setState(() {
      _mini = !_mini;
      _savingSize = true;
    });
    await _applyPlayback();
    try {
      final current = await WorkoutService.get('/preferences');
      WorkoutService.preferences = await WorkoutService.put('/preferences',
          {...current, 'demonstrationSize': _mini ? 'mini' : 'full'});
    } catch (error) {
      if (mounted) workoutError(context, error);
    } finally {
      if (mounted) setState(() => _savingSize = false);
    }
  }

  Future<void> _credits() => workoutDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: WorkoutLabel(widget.video.name),
              content: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text('${widget.video.author} · ${widget.video.license}'),
                    const SizedBox(height: 8),
                    Text(widget.video.modifications),
                    TextButton(
                        onPressed: () => launchUrl(
                            Uri.parse(widget.video.sourceUrl),
                            mode: LaunchMode.externalApplication),
                        child: const WorkoutLabel('Original video')),
                    TextButton(
                        onPressed: () => launchUrl(
                            Uri.parse(widget.video.licenseUrl),
                            mode: LaunchMode.externalApplication),
                        child: const WorkoutLabel('License')),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const WorkoutLabel('Close'))
              ]));

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_changed);
    final controller = _controller;
    if (controller != null) unawaited(_release(controller));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Row(children: [
                const Expanded(child: WorkoutLabel('Demonstration')),
                WorkoutLabel(widget.video.isGif ? 'GIF' : 'Video',
                    style: const TextStyle(fontSize: 12)),
                IconButton(
                    tooltip: (_mini
                            ? 'Expand demonstration'
                            : 'Minimize demonstration')
                        .workoutTr(context),
                    onPressed: _savingSize ? null : _size,
                    icon: Icon(
                        _mini ? Icons.open_in_full : Icons.close_fullscreen)),
              ]),
              if (widget.video.isGif && !_mini)
                SizedBox(
                    height: widget.compact ? 180 : 260,
                    child: WorkoutAnimatedImage(
                        location: widget.video.asset,
                        playing: _wanted,
                        semanticLabel: widget.video.name))
              else if (_mini || controller == null)
                WorkoutMediaImage(
                    location: widget.video.poster,
                    height: _mini
                        ? 64
                        : widget.compact
                            ? 160
                            : 240,
                    fit: BoxFit.contain)
              else
                ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: widget.compact ? 180 : 260),
                    child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller))),
              if (!_mini && controller != null)
                Row(children: [
                  IconButton(
                      tooltip: (_lastPlaying
                              ? 'Pause demonstration'
                              : 'Play demonstration')
                          .workoutTr(context),
                      onPressed: () {
                        _wanted = !_lastPlaying;
                        unawaited(_applyPlayback());
                      },
                      icon:
                          Icon(_lastPlaying ? Icons.pause : Icons.play_arrow)),
                  Expanded(
                      child: VideoProgressIndicator(controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.all(8))),
                ]),
              if (!_mini && widget.video.isGif)
                IconButton(
                    tooltip:
                        (_wanted ? 'Pause demonstration' : 'Play demonstration')
                            .workoutTr(context),
                    onPressed: () => setState(() => _wanted = !_wanted),
                    icon: Icon(_wanted ? Icons.pause : Icons.play_arrow)),
              if (_error != null)
                TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const WorkoutLabel('Reload video')),
              if (widget.video.hasCredits)
                TextButton(
                    onPressed: _credits,
                    child: Text(
                        '${widget.video.author} · ${widget.video.license}',
                        style: const TextStyle(fontSize: 11))),
            ])));
  }
}
