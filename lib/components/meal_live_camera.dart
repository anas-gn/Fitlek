import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'meal_visuals.dart';

/// Owns the camera only while the scanner is visible and in the foreground.
class MealLiveCamera extends StatefulWidget {
  final ValueChanged<XFile> onCaptured;
  final ValueChanged<bool> onCapturing;
  const MealLiveCamera(
      {super.key, required this.onCaptured, required this.onCapturing});

  @override
  State<MealLiveCamera> createState() => MealLiveCameraState();
}

class MealLiveCameraState extends State<MealLiveCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;
  int _generation = 0;
  bool _visible = false, _foreground = true, _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncVisibility();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A browser permission dialog can temporarily remove window focus.
    if (kIsWeb && state == AppLifecycleState.inactive) return;
    _foreground = state == AppLifecycleState.resumed;
    _syncVisibility();
  }

  void _syncVisibility() {
    final visible = _foreground && TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    if (visible) {
      _open();
    } else {
      _generation++;
      _release();
    }
  }

  Future<void> _release() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  Future<void> _open() async {
    final generation = ++_generation;
    setState(() => _error = null);
    try {
      await _release();
      if (!mounted || generation != _generation) return;
      final cameras = await availableCameras();
      if (!mounted || generation != _generation) return;
      if (cameras.isEmpty) {
        setState(() =>
            _error = 'No camera found. Choose a photo from your gallery.');
        return;
      }
      final rear =
          cameras.where((c) => c.lensDirection == CameraLensDirection.back);
      final controller = CameraController(
          rear.isEmpty ? cameras.first : rear.first, ResolutionPreset.high,
          enableAudio: false);
      _controller = controller;
      await controller.initialize();
      if (!mounted || generation != _generation) return;
      setState(() {});
    } catch (error) {
      if (!mounted || generation != _generation) return;
      await _release();
      if (!mounted || generation != _generation) return;
      setState(() => _error = error is CameraException &&
              error.code.toLowerCase().contains('denied')
          ? 'Allow camera access in your device or browser settings, then retry.'
          : 'Camera unavailable. Retry or choose a photo from your gallery.');
    }
  }

  Future<void> capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    final generation = _generation;
    _capturing = true;
    widget.onCapturing(true);
    try {
      final photo = await controller.takePicture();
      if (mounted && generation == _generation) widget.onCaptured(photo);
    } catch (_) {
      if (mounted && generation == _generation) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not capture the photo. Try again.')));
      }
    } finally {
      _capturing = false;
      if (mounted) widget.onCapturing(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_visible && controller != null && controller.value.isInitialized) {
      return LayoutBuilder(builder: (context, constraints) {
        // Preserve the camera's orientation and crop to fill the scanner box.
        final portrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        final ratio = kIsWeb || !portrait
            ? controller.value.aspectRatio
            : 1 / controller.value.aspectRatio;
        return ClipRect(
            child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                    width: constraints.maxHeight * ratio,
                    height: constraints.maxHeight,
                    child: CameraPreview(controller))));
      });
    }
    return ColoredBox(
        color: mealSurface,
        child: Center(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (_error == null) ...[
                    const CircularProgressIndicator(
                        color: mealLime, strokeWidth: 2),
                    const SizedBox(height: 16),
                    const Text('Starting camera…',
                        style: TextStyle(color: mealCream)),
                  ] else ...[
                    const Icon(Icons.videocam_off_outlined,
                        color: mealLime, size: 32),
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: mealCream, fontSize: 12)),
                    TextButton(
                        onPressed: _open, child: const Text('Retry camera')),
                  ],
                ]))));
  }
}
