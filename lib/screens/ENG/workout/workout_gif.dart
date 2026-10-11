import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../models/workout_video.dart';
import 'workout_ui.dart';
import 'workout_gif_browser_stub.dart'
    if (dart.library.js_interop) 'workout_gif_browser.dart' as browser;

/// Decodes one frame at a time so GIFs obey pause, route visibility and
/// reduced-motion preferences, just like the video player.
class WorkoutAnimatedImage extends StatefulWidget {
  final String location;
  final bool playing;
  final BoxFit fit;
  final String? semanticLabel;
  const WorkoutAnimatedImage(
      {super.key,
      required this.location,
      this.playing = false,
      this.fit = BoxFit.contain,
      this.semanticLabel});
  @override
  State<WorkoutAnimatedImage> createState() => _WorkoutAnimatedImageState();
}

class _WorkoutAnimatedImageState extends State<WorkoutAnimatedImage>
    with WidgetsBindingObserver {
  ui.Codec? _codec;
  ui.Image? _image;
  Timer? _timer;
  Object? _error;
  int _generation = 0;
  bool _foreground = true, _enabled = false, _decoding = false;
  Duration _duration = const Duration(milliseconds: 100);
  bool get _playing => widget.playing && _foreground && _enabled;
  bool get _browser =>
      browser.supportsBrowserGif &&
      Uri.tryParse(widget.location)?.hasScheme == true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_browser) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled = TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    _schedule();
  }

  @override
  void didUpdateWidget(WorkoutAnimatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      if (!_browser) _load();
    } else {
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_browser) setState(() {});
    _schedule();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _timer?.cancel();
    _codec?.dispose();
    _codec = null;
    _image?.dispose();
    _image = null;
    _error = null;
    _decoding = false;
    ui.Codec? codec;
    try {
      final location = workoutMediaLocation(widget.location);
      if (location == null) throw StateError('Invalid media location');
      final Uint8List bytes;
      if (location.startsWith('assets/')) {
        bytes = (await rootBundle.load(location)).buffer.asUint8List();
      } else {
        final response = await http
            .get(Uri.parse(location))
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) throw StateError('Media unavailable');
        bytes = response.bodyBytes;
      }
      codec = await ui.instantiateImageCodec(bytes,
          targetWidth: 640, allowUpscaling: false);
      final frame = await codec.getNextFrame();
      if (!mounted || generation != _generation) {
        frame.image.dispose();
        codec.dispose();
        return;
      }
      _codec = codec;
      setState(() {
        _image = frame.image;
        _duration = frame.duration;
      });
      _schedule();
    } catch (error) {
      codec?.dispose();
      if (mounted && generation == _generation) setState(() => _error = error);
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!_playing || _codec == null || _codec!.frameCount < 2 || _decoding) {
      return;
    }
    _timer = Timer(
        _duration.inMilliseconds < 20
            ? const Duration(milliseconds: 100)
            : _duration,
        _next);
  }

  Future<void> _next() async {
    if (!_playing || _codec == null) return;
    final generation = _generation;
    _decoding = true;
    try {
      final frame = await _codec!.getNextFrame();
      if (!mounted || generation != _generation) {
        frame.image.dispose();
        return;
      }
      final previous = _image;
      setState(() {
        _image = frame.image;
        _duration = frame.duration;
      });
      previous?.dispose();
    } catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error);
    } finally {
      if (generation == _generation) {
        _decoding = false;
        if (_error == null) _schedule();
      }
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _codec?.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_browser) {
      return browser.browserGif(
          location: widget.location,
          playing: _playing,
          fit: widget.fit,
          semanticLabel: widget.semanticLabel);
    }
    if (_error != null) {
      return Center(
          child: TextButton.icon(
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              icon: const Icon(Icons.refresh),
              label: const WorkoutLabel('Reload demonstration')));
    }
    if (_image == null) {
      return const Center(
          child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return Semantics(
        label: widget.semanticLabel,
        image: true,
        child: RawImage(image: _image, fit: widget.fit));
  }
}

class WorkoutMediaImage extends StatelessWidget {
  final String location;
  final BoxFit fit;
  final double? height;
  final String? semanticLabel;
  const WorkoutMediaImage(
      {super.key,
      required this.location,
      this.fit = BoxFit.contain,
      this.height,
      this.semanticLabel});
  @override
  Widget build(BuildContext context) {
    final media = workoutMediaLocation(location);
    Widget unavailable(BuildContext context, Object error, StackTrace? stack) =>
        const Center(
            child: WorkoutLabel('No demo yet',
                style: TextStyle(fontSize: 10), textAlign: TextAlign.center));
    if (media == null) {
      return unavailable(context, StateError('No media'), null);
    }
    if (Uri.parse(media).path.toLowerCase().endsWith('.gif')) {
      return SizedBox(
          height: height,
          child: WorkoutAnimatedImage(
              location: media, fit: fit, semanticLabel: semanticLabel));
    }
    return media.startsWith('assets/')
        ? Image.asset(media,
            fit: fit,
            height: height,
            semanticLabel: semanticLabel,
            errorBuilder: unavailable)
        : Image.network(media,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            fit: fit,
            height: height,
            semanticLabel: semanticLabel,
            errorBuilder: unavailable);
  }
}
