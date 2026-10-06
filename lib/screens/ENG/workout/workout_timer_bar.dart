import 'package:flutter/material.dart';
import 'workout_ui.dart';

class WorkoutTimerDisplay {
  final bool work, paused, busy;
  final int remaining, total;
  final String label;
  final VoidCallback cancel, done;
  final void Function(int)? adjust;
  final VoidCallback? pause;
  const WorkoutTimerDisplay(
      {required this.work,
      required this.remaining,
      required this.total,
      required this.label,
      required this.cancel,
      required this.done,
      this.adjust,
      this.pause,
      this.paused = false,
      this.busy = false});
}

class WorkoutTimerController extends ValueNotifier<WorkoutTimerDisplay?> {
  bool _disposed = false;
  WorkoutTimerController() : super(null);
  void publish(WorkoutTimerDisplay? display) {
    if (!_disposed) value = display;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// The module shell presents the one active timer above its navigation, even
// when another training page covers the active-workout route.
class WorkoutTimerHost extends InheritedWidget {
  final WorkoutTimerController timer;
  const WorkoutTimerHost(
      {super.key, required this.timer, required super.child});
  static WorkoutTimerController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkoutTimerHost>()?.timer;
  @override
  bool updateShouldNotify(WorkoutTimerHost oldWidget) =>
      oldWidget.timer != timer;
}

class WorkoutTimerBar extends StatelessWidget {
  final WorkoutTimerDisplay timer;
  const WorkoutTimerBar({super.key, required this.timer});
  @override
  Widget build(BuildContext context) {
    final color =
        timer.work ? Colors.blue : Theme.of(context).colorScheme.primary;
    return SafeArea(
        top: false,
        bottom: false,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        WorkoutLabel(workoutClock(timer.remaining),
                            key: const ValueKey('workout-timer-clock'),
                            style: TextStyle(
                                fontSize: 28,
                                color: color,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              WorkoutLabel(
                                  timer.work
                                      ? timer.label
                                      : timer.paused
                                          ? 'Rest paused'
                                          : 'Rest',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 5),
                              LinearProgressIndicator(
                                  value: timer.total == 0
                                      ? 0
                                      : (timer.remaining / timer.total)
                                          .clamp(0, 1),
                                  color: color)
                            ]))
                      ]),
                      Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: timer.work
                              ? [
                                  TextButton(
                                      onPressed:
                                          timer.busy ? null : timer.cancel,
                                      child: const WorkoutLabel('Cancel')),
                                  FilledButton(
                                      onPressed: timer.busy ? null : timer.done,
                                      child: const WorkoutLabel('Done'))
                                ]
                              : [
                                  TextButton.icon(
                                      onPressed: () => timer.adjust?.call(-15),
                                      icon: const Icon(Icons.remove, size: 16),
                                      label: const WorkoutLabel('15s')),
                                  TextButton.icon(
                                      onPressed: () => timer.adjust?.call(15),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const WorkoutLabel('15s')),
                                  if (timer.pause != null)
                                    IconButton(
                                        tooltip:
                                            (timer.paused ? 'Resume' : 'Pause')
                                                .workoutTr(context),
                                        onPressed: timer.pause,
                                        icon: Icon(
                                            timer.paused
                                                ? Icons.play_arrow
                                                : Icons.pause,
                                            size: 18)),
                                  TextButton(
                                      onPressed: timer.cancel,
                                      child: const WorkoutLabel('Skip'))
                                ])
                    ])))));
  }
}
