import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const VideoSplashScreen({super.key, required this.nextScreen});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      // On Flutter Web, VideoPlayerController.asset() builds a wrong URL
      // (doubles the 'assets/' prefix), so we use networkUrl on web instead.
      if (kIsWeb) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse('assets/branding/sirvya_intro.mp4'),
        );
      } else {
        _controller = VideoPlayerController.asset('assets/branding/sirvya_intro.mp4');
      }

      // 15s timeout — some Android devices are slow on cold start
      await _controller.initialize().timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() => _isVideoInitialized = true);
        _controller.play();
      }

      _controller.addListener(() {
        if (!_hasNavigated &&
            _controller.value.isInitialized &&
            _controller.value.position >= _controller.value.duration) {
          _navigateToNextScreen();
        }
      });
    } catch (e) {
      debugPrint('Error initializing intro video: $e');
      // Video failed or timed out — skip straight to next screen
      if (mounted) _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isVideoInitialized
          ? GestureDetector(
              onTap: _navigateToNextScreen,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            )
          // Show the logo centered on black while video initialises
          : Center(
              child: Image.asset(
                'assets/branding/logo_dark.png',
                width: 140,
              ),
            ),
    );
  }
}
