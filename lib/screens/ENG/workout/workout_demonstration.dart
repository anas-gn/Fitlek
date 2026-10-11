import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/workout.dart';
import '../../../models/workout_demonstration.dart';
import '../../../models/workout_video.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'workout_video.dart';
import 'workout_gif.dart';

// Keep each lookup for the lifetime of its displayed exercise. Parent rebuilds
// must not consume another provider request or reset an animation.
class _MediaLookup<T> extends StatefulWidget {
  final Exercise exercise;
  final bool deferUntilVisible;
  final Future<T> Function() load;
  final Widget Function(BuildContext, AsyncSnapshot<T>, VoidCallback) builder;
  const _MediaLookup(
      {required this.exercise,
      required this.load,
      required this.builder,
      this.deferUntilVisible = false});
  @override
  State<_MediaLookup<T>> createState() => _MediaLookupState<T>();
}

class _MediaLookupState<T> extends State<_MediaLookup<T>> {
  Future<T>? _future;
  ScrollPosition? _position;
  Timer? _visibilityDelay;
  bool _visibilityScheduled = false;
  String _identity(Exercise e) =>
      '${e.id}:${e.externalSource}:${e.externalId}:${e.videoUrl}:${e.imageUrl}:${e.hasHostedMedia}';
  @override
  void initState() {
    super.initState();
    if (!widget.deferUntilVisible) _future = widget.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_scheduleVisibility);
      _position = position;
      _position?.addListener(_scheduleVisibility);
    }
    _scheduleVisibility();
  }

  void _scheduleVisibility() {
    if (!widget.deferUntilVisible || _future != null || _visibilityScheduled) {
      return;
    }
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (!mounted) return;
      if (!_isVisible()) {
        _visibilityDelay?.cancel();
        _visibilityDelay = null;
        return;
      }
      _visibilityDelay ??= Timer(const Duration(milliseconds: 180), () {
        _visibilityDelay = null;
        if (mounted && _future == null && _isVisible()) {
          setState(() {
            _future = widget.load();
          });
        }
      });
    });
  }

  bool _isVisible() {
    if (!TickerMode.valuesOf(context).enabled) return false;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final bounds = box.localToGlobal(Offset.zero) & box.size;
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    final visible =
        viewport is RenderBox && viewport.attached && viewport.hasSize
            ? viewport.localToGlobal(Offset.zero) & viewport.size
            : Offset.zero & MediaQuery.sizeOf(context);
    return !bounds.isEmpty && bounds.overlaps(visible);
  }

  @override
  void didUpdateWidget(covariant _MediaLookup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_identity(oldWidget.exercise) != _identity(widget.exercise)) {
      _visibilityDelay?.cancel();
      _visibilityDelay = null;
      _future = widget.deferUntilVisible ? null : widget.load();
      _scheduleVisibility();
    }
  }

  @override
  void dispose() {
    _visibilityDelay?.cancel();
    _position?.removeListener(_scheduleVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) => widget.builder(
          context,
          snapshot,
          () => setState(() {
                _future = widget.load();
              })));
}

class WorkoutDemonstrationPanel extends StatelessWidget {
  final Exercise exercise;
  final bool compact;
  const WorkoutDemonstrationPanel(
      {super.key, required this.exercise, this.compact = false});
  @override
  Widget build(BuildContext context) => _MediaLookup<WorkoutVideo?>(
      exercise: exercise,
      load: () => WorkoutVideoCatalog.forExercise(exercise),
      builder: (context, snapshot, reload) => snapshot.connectionState !=
              ConnectionState.done
          ? const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()))
          : snapshot.hasError
              ? Column(children: [
                  WorkoutIllustrationPanel(
                      exercise: exercise, compact: compact),
                  TextButton.icon(
                      onPressed: reload,
                      icon: const Icon(Icons.refresh),
                      label: const WorkoutLabel('Reload demonstration'))
                ])
              : snapshot.data == null
                  ? workoutMediaLocation(exercise.imageUrl) != null
                      ? Card(
                          child: WorkoutMediaImage(
                              location: exercise.imageUrl!,
                              height: compact ? 210 : 230,
                              semanticLabel: exercise.name))
                      : WorkoutIllustrationPanel(
                          exercise: exercise, compact: compact)
                  : WorkoutVideoPanel(video: snapshot.data!, compact: compact));
}

class WorkoutIllustrationPanel extends StatefulWidget {
  final Exercise exercise;
  final bool compact;
  const WorkoutIllustrationPanel(
      {super.key, required this.exercise, this.compact = false});
  @override
  State<WorkoutIllustrationPanel> createState() =>
      _WorkoutDemonstrationPanelState();
}

class _WorkoutDemonstrationPanelState extends State<WorkoutIllustrationPanel>
    with WidgetsBindingObserver {
  final _pages = PageController();
  late Future<WorkoutDemonstration?> _demonstration;
  Timer? _timer;
  int _index = 0, _frameCount = 0;
  bool _playing = false, _minimized = false;
  bool _autoplayInitialized = false, _savingSize = false;
  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _minimized = WorkoutService.preferences['demonstrationSize'] == 'mini';
    _demonstration = WorkoutDemonstrationCatalog.forExercise(widget.exercise);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_autoplayInitialized) {
      _autoplayInitialized = true;
      _playing = !_reduceMotion;
      if (_playing) _startTimer();
    } else if (_reduceMotion && _playing) {
      _playing = false;
      _timer?.cancel();
    }
  }

  Future<void> _toggleSize() async {
    if (_savingSize) return;
    final previous = _minimized;
    setState(() {
      _minimized = !previous;
      _savingSize = true;
    });
    try {
      final preferences = await WorkoutService.get('/preferences');
      final saved = await WorkoutService.put('/preferences',
          {...preferences, 'demonstrationSize': _minimized ? 'mini' : 'full'});
      WorkoutService.preferences = saved;
    } catch (error) {
      if (mounted) {
        setState(() => _minimized = previous);
        workoutError(context, error);
      }
    } finally {
      if (mounted) setState(() => _savingSize = false);
    }
  }

  @override
  void didUpdateWidget(covariant WorkoutIllustrationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exercise.externalSource != oldWidget.exercise.externalSource ||
        widget.exercise.externalId != oldWidget.exercise.externalId) {
      _timer?.cancel();
      _playing = !_reduceMotion;
      _minimized = WorkoutService.preferences['demonstrationSize'] == 'mini';
      _index = 0;
      _frameCount = 0;
      if (_pages.hasClients) _pages.jumpToPage(0);
      _demonstration = WorkoutDemonstrationCatalog.forExercise(widget.exercise);
      if (_playing) _startTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _playing) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled && !_reduceMotion) {
        _step(1);
      }
    });
  }

  void _step(int delta) {
    if (!_pages.hasClients || _frameCount == 0) return;
    final index = (_index + delta) % _frameCount;
    if (_reduceMotion) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(index,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _link(String value) async {
    try {
      if (!await launchUrl(Uri.parse(value))) throw Exception();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: WorkoutLabel('Unable to open link'.workoutTr(context))));
      }
    }
  }

  Future<void> _credits(WorkoutDemonstration demonstration) async {
    final frame = demonstration.frames[_index];
    await workoutSheet<void>(
        context: context,
        builder: (context) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const WorkoutLabel('Illustration credits',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  WorkoutLabel(demonstration.name),
                  WorkoutLabel('${frame['author']} · ${demonstration.license}'),
                  const WorkoutLabel('Original illustration, unmodified.'),
                  TextButton.icon(
                      onPressed: () => _link('${frame['sourceUrl']}'),
                      icon: const Icon(Icons.open_in_new),
                      label: const WorkoutLabel('Illustration source')),
                  TextButton.icon(
                      onPressed: () => _link(demonstration.licenseUrl),
                      icon: const Icon(Icons.description_outlined),
                      label: const WorkoutLabel('Illustration license')),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const WorkoutLabel('Done'))
                ]))));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WorkoutDemonstration?>(
      future: _demonstration,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton.icon(
              onPressed: () => setState(() => _demonstration =
                  WorkoutDemonstrationCatalog.forExercise(widget.exercise)),
              icon: const Icon(Icons.refresh),
              label: const WorkoutLabel('Reload demonstration'));
        }
        final demonstration = snapshot.data;
        if (demonstration == null) return const SizedBox.shrink();
        _frameCount = demonstration.frames.length;
        return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              if (!widget.compact)
                const Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 8),
                    child: WorkoutLabel('Demonstration',
                        style: TextStyle(fontWeight: FontWeight.w600))),
              if (!_minimized)
                SizedBox(
                    height: widget.compact ? 210 : 230,
                    child: ColoredBox(
                        color: Colors.white,
                        child: PageView.builder(
                            controller: _pages,
                            itemCount: _frameCount,
                            onPageChanged: (i) => setState(() => _index = i),
                            itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                    '${demonstration.frames[i]['asset']}',
                                    fit: BoxFit.contain,
                                    semanticLabel: widget.exercise.name))))),
              Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.compact)
                      TextButton(
                          onPressed: _savingSize ? null : _toggleSize,
                          child:
                              WorkoutLabel(_minimized ? 'Expand' : 'Minimize')),
                    IconButton(
                        tooltip:
                            'Previous demonstration frame'.workoutTr(context),
                        onPressed: () => _step(-1),
                        icon: const Icon(Icons.chevron_left)),
                    Text('${_index + 1} / $_frameCount'),
                    IconButton(
                        tooltip: 'Next demonstration frame'.workoutTr(context),
                        onPressed: () => _step(1),
                        icon: const Icon(Icons.chevron_right)),
                    IconButton(
                        tooltip: (_playing
                                ? 'Pause demonstration'
                                : 'Play demonstration')
                            .workoutTr(context),
                        onPressed: _reduceMotion
                            ? null
                            : () {
                                setState(() => _playing = !_playing);
                                _playing ? _startTimer() : _timer?.cancel();
                              },
                        icon: Icon(_playing ? Icons.pause : Icons.play_arrow))
                  ]),
              TextButton(
                  onPressed: () => _credits(demonstration),
                  child: Text(
                      '${demonstration.frames[_index]['author']} · ${demonstration.license}',
                      style: const TextStyle(fontSize: 12)))
            ]));
      });
}

class WorkoutExerciseThumbnail extends StatelessWidget {
  final Exercise exercise;
  const WorkoutExerciseThumbnail({super.key, required this.exercise});
  Future<(String?, bool)> _media() async {
    WorkoutVideo? video;
    try {
      video = await WorkoutVideoCatalog.forExercise(exercise, preview: true);
    } catch (_) {}
    if (video != null && video.poster.isNotEmpty) return (video.poster, true);
    final image = workoutMediaLocation(exercise.imageUrl);
    if (image != null) return (image, video != null);
    final demo = await WorkoutDemonstrationCatalog.forExercise(exercise);
    return (demo?.frames.firstOrNull?['asset'] as String?, video != null);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 44,
      height: 44,
      child: _MediaLookup<(String?, bool)>(
          exercise: exercise,
          deferUntilVisible: true,
          load: _media,
          builder: (context, snapshot, reload) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: snapshot.connectionState != ConnectionState.done
                  ? ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest)
                  : Stack(fit: StackFit.expand, children: [
                      if (snapshot.data?.$1 != null)
                        WorkoutMediaImage(
                            location: snapshot.data!.$1!,
                            semanticLabel: exercise.name)
                      else
                        ColoredBox(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Center(
                                child: WorkoutLabel('No demo yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 9)))),
                      if (snapshot.data?.$2 == true)
                        const Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(Icons.play_circle_fill, size: 18)),
                    ]))));
}

class WorkoutMediaKindLabel extends StatelessWidget {
  final Exercise exercise;
  const WorkoutMediaKindLabel({super.key, required this.exercise});
  Future<String> _kind() async {
    WorkoutVideo? video;
    try {
      video = await WorkoutVideoCatalog.localForExercise(exercise);
    } catch (_) {}
    if (video != null) return video.isGif ? 'GIF' : 'Video';
    if (exercise.hasHostedMedia == true) return 'GIF';
    if (workoutMediaLocation(exercise.imageUrl) != null) {
      return 'Illustrated demo';
    }
    if (await WorkoutDemonstrationCatalog.forExercise(exercise) != null) {
      return 'Illustrated demo';
    }
    return 'No demo yet';
  }

  @override
  Widget build(BuildContext context) => _MediaLookup<String>(
      exercise: exercise,
      load: _kind,
      builder: (context, snapshot, reload) => snapshot.data == null
          ? const SizedBox.shrink()
          : WorkoutLabel(snapshot.data!, style: const TextStyle(fontSize: 11)));
}
