import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Client navigation mascot. Greets on app open, then waves at random intervals.
/// The GIF's embedded infinite-loop setting is intentionally ignored.
class HomeRobotWave extends StatefulWidget {
  static const double size = 72;
  static const minimumPause = Duration(seconds: 20);
  static const maximumPause = Duration(seconds: 45);
  final bool active;
  // An optional random source keeps scheduling deterministic in widget tests.
  final Random? random;
  const HomeRobotWave({super.key, required this.active, this.random});
  @override
  State<HomeRobotWave> createState() => _HomeRobotWaveState();
}

class _HomeRobotWaveState extends State<HomeRobotWave>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static final _asset = rootBundle.load('assets/branding/meal_robot_wave.gif');
  late final AnimationController _peek = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  ui.Codec? _codec;
  ui.Image? _frame;
  ui.Image? _firstFrame;
  Timer? _timer;
  Timer? _repeatTimer;
  int _generation = 0;
  bool _enabled = false, _animationsEnabled = true;
  bool _foreground = true, _hasGreeted = false;
  late final Random _random = widget.random ?? Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_foreground) _hasGreeted = false;
      _foreground = true;
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _foreground = false;
    } else {
      return;
    }
    _syncVisibility();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncVisibility();
  }

  @override
  void didUpdateWidget(HomeRobotWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncVisibility();
  }

  void _syncVisibility() {
    final allowed =
        widget.active && _foreground && TickerMode.valuesOf(context).enabled;
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (allowed == _enabled && animate == _animationsEnabled) return;
    _enabled = allowed;
    _animationsEnabled = animate;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _stop();
    if (allowed) {
      final greet = animate && !_hasGreeted;
      if (greet) _hasGreeted = true;
      _playOnce(_generation, animate: greet);
    }
  }

  void _scheduleNextWave() {
    _repeatTimer?.cancel();
    if (!_enabled || !_animationsEnabled) return;
    final seconds = HomeRobotWave.minimumPause.inSeconds +
        _random.nextInt(HomeRobotWave.maximumPause.inSeconds -
            HomeRobotWave.minimumPause.inSeconds +
            1);
    _repeatTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || !_enabled || !_animationsEnabled) return;
      _stop(clearFrame: false);
      _playOnce(_generation);
    });
  }

  Future<void> _playOnce(int generation, {bool animate = true}) async {
    try {
      final asset = await _asset;
      if (!mounted || generation != _generation) return;
      final codec = await ui.instantiateImageCodec(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
      );
      if (!mounted || generation != _generation) {
        codec.dispose();
        return;
      }
      _codec = codec;
      if (!animate) {
        final first = await codec.getNextFrame();
        if (!mounted || generation != _generation) {
          first.image.dispose();
          return;
        }
        final previous = _frame;
        setState(() => _frame = first.image);
        _releaseAfterPaint(previous);
        _peek.value = 1;
        codec.dispose();
        _codec = null;
        _scheduleNextWave();
        return;
      }
      await _advance(codec, generation, 0);
    } catch (_) {
      // An unavailable or unsupported animation must not affect navigation.
      if (mounted && generation == _generation) _stop();
    }
  }

  Future<void> _advance(ui.Codec codec, int generation, int index) async {
    if (!mounted || generation != _generation) return;
    try {
      final next = await codec.getNextFrame();
      if (!mounted || generation != _generation) {
        next.image.dispose();
        return;
      }
      final previous = _frame;
      if (index == 0) _firstFrame = next.image.clone();
      setState(() => _frame = next.image);
      _releaseAfterPaint(previous);
      if (index == 0) _peek.value = 1;
      final delay = next.duration < const Duration(milliseconds: 16)
          ? const Duration(milliseconds: 16)
          : next.duration;
      _timer = Timer(delay, () {
        if (!mounted || generation != _generation) return;
        if (index + 1 < codec.frameCount) {
          _advance(codec, generation, index + 1);
        } else {
          _finish(generation);
        }
      });
    } catch (_) {
      if (mounted && generation == _generation) _stop();
    }
  }

  void _finish(int generation) {
    if (!mounted || generation != _generation) return;
    _timer?.cancel();
    _timer = null;
    _codec?.dispose();
    _codec = null;
    // Return to the opening pose and hold it behind the logo after the wave.
    final previous = _frame;
    setState(() {
      _frame = _firstFrame;
      _firstFrame = null;
    });
    _releaseAfterPaint(previous);
    _peek.value = 1;
    // Sample a fresh delay after every wave; tab changes do not replay it.
    _scheduleNextWave();
  }

  void _releaseAfterPaint(ui.Image? image) {
    if (image != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
    }
  }

  void _stop({bool clearFrame = true}) {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _peek.stop();
    _codec?.dispose();
    _codec = null;
    _firstFrame?.dispose();
    _firstFrame = null;
    if (clearFrame) {
      final previous = _frame;
      _frame = null;
      if (mounted) setState(() {});
      _releaseAfterPaint(previous);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _timer?.cancel();
    _repeatTimer?.cancel();
    _codec?.dispose();
    _frame?.dispose();
    _firstFrame?.dispose();
    _peek.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frame == null) return const SizedBox.shrink();
    return IgnorePointer(
        child: ExcludeSemantics(
            child: ClipRect(
                child: AnimatedBuilder(
      animation: _peek,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_peek.value);
        return Transform.translate(
            offset: Offset(0, (1 - progress) * HomeRobotWave.size),
            child: child);
      },
      child: SizedBox(
          key: const ValueKey('meal-robot-wave'),
          width: HomeRobotWave.size,
          height: HomeRobotWave.size,
          child: CustomPaint(painter: _RobotFrame(_frame!))),
    ))));
  }
}

class _RobotFrame extends CustomPainter {
  final ui.Image image;
  _RobotFrame(this.image);
  @override
  void paint(Canvas canvas, Size size) {
    // Union of the transparent bounds across all 80 original frames. Cropping
    // the canvas at paint time keeps the original GIF asset unchanged.
    final fitted = applyBoxFit(BoxFit.contain, const Size(316, 224), size);
    final destination =
        Alignment.center.inscribe(fitted.destination, Offset.zero & size);
    canvas.drawImageRect(image, const Rect.fromLTWH(23, 17, 316, 224),
        destination, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_RobotFrame oldDelegate) => oldDelegate.image != image;
}
