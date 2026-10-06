import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/workout.dart';
import '../../../models/workout_demonstration.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';

class WorkoutDemonstrationPanel extends StatefulWidget {
  final Exercise exercise;
  final bool compact;
  const WorkoutDemonstrationPanel(
      {super.key, required this.exercise, this.compact = false});
  @override
  State<WorkoutDemonstrationPanel> createState() =>
      _WorkoutDemonstrationPanelState();
}

class _WorkoutDemonstrationPanelState extends State<WorkoutDemonstrationPanel>
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
  void didUpdateWidget(covariant WorkoutDemonstrationPanel oldWidget) {
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
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 44,
      height: 44,
      child: FutureBuilder<WorkoutDemonstration?>(
          future: WorkoutDemonstrationCatalog.forExercise(exercise),
          builder: (context, result) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: result.data?.frames.isNotEmpty == true
                  ? Image.asset('${result.data!.frames.first['asset']}',
                      fit: BoxFit.contain)
                  : ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                          exercise.type == 'cardio'
                              ? Icons.directions_run
                              : exercise.isTimed
                                  ? Icons.timer_outlined
                                  : Icons.fitness_center,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20)))));
}
