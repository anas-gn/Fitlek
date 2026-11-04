import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final VoidCallback? onFinished;
  const VideoSplashScreen(
      {super.key, required this.nextScreen, this.onFinished});
  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  VideoPlayerController? _controller;
  Timer? _deadline;
  bool _finished = false;
  static const _endBuffer = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    // Native completion events can be missing after interruptions or stalls.
    _deadline = Timer(const Duration(seconds: 25), _finish);
    unawaited(_initVideo());
  }

  Future<void> _initVideo() async {
    try {
      final controller = kIsWeb
          ? VideoPlayerController.networkUrl(
              Uri.base.resolve('assets/branding/sirvya_intro.mp4'))
          : VideoPlayerController.asset('assets/branding/sirvya_intro.mp4');
      _controller = controller;
      controller.addListener(_onVideoTick);
      await controller.initialize();
      if (!mounted || _finished) return;
      setState(() {});
      await controller.play();
    } catch (error) {
      debugPrint('Intro unavailable: $error');
      _finish();
    }
  }

  void _onVideoTick() {
    final value = _controller?.value;
    if (value == null || !mounted || _finished) return;
    if (value.hasError ||
        value.isCompleted ||
        (value.isInitialized &&
            value.duration > Duration.zero &&
            value.position >= value.duration - _endBuffer)) {
      _finish();
    }
  }

  void _finish() {
    if (!mounted || _finished) return;
    _deadline?.cancel();
    // Render the next screen directly. A post-frame navigation callback can
    // remain pending when the native player stops requesting Flutter frames.
    setState(() => _finished = true);
    widget.onFinished?.call();
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      unawaited(controller.pause().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    _deadline?.cancel();
    final controller = _controller;
    controller?.removeListener(_onVideoTick);
    if (controller != null) {
      unawaited(controller.dispose().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.nextScreen;
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Stack(fit: StackFit.expand, children: [
          if (controller != null && controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller)),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ]),
      ),
    );
  }
}
