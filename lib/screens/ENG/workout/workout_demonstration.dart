import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/workout.dart';
import '../../../models/workout_demonstration.dart';
import 'workout_ui.dart';

class WorkoutDemonstrationPanel extends StatefulWidget {
  final Exercise exercise;
  const WorkoutDemonstrationPanel({super.key, required this.exercise});
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
  bool _playing = false;
  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _demonstration = WorkoutDemonstrationCatalog.forExercise(widget.exercise);
  }

  @override
  void didUpdateWidget(covariant WorkoutDemonstrationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exercise.externalSource != oldWidget.exercise.externalSource ||
        widget.exercise.externalId != oldWidget.exercise.externalId) {
      _timer?.cancel();
      _playing = false;
      _index = 0;
      _frameCount = 0;
      if (_pages.hasClients) _pages.jumpToPage(0);
      _demonstration = WorkoutDemonstrationCatalog.forExercise(widget.exercise);
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
              const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 8),
                  child: WorkoutLabel('Demonstration',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              SizedBox(
                  height: 230,
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
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    tooltip: 'Previous demonstration frame'.workoutTr(context),
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
