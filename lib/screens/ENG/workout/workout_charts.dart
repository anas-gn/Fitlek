import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import 'workout_ui.dart';

class WorkoutLineChart extends StatelessWidget {
  final List<double> values;
  final String label;
  const WorkoutLineChart(
      {super.key, required this.values, required this.label});
  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(16),
          child: WorkoutLabel('No data for this period.'));
    }
    return Semantics(
        label: '$label: ${values.map(workoutValue).join(', ')}',
        child: Column(children: [
          SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                  painter: _LinePainter(
                      values,
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).dividerColor))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            WorkoutLabel(workoutValue(values.first),
                style: const TextStyle(fontSize: 12)),
            WorkoutLabel(workoutValue(values.last),
                style: const TextStyle(fontSize: 12))
          ])
        ]));
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final Color accent, line;
  _LinePainter(this.values, this.accent, this.line);
  @override
  void paint(Canvas canvas, Size size) {
    final low = values.reduce(math.min),
        high = values.reduce(math.max),
        span = high == low ? math.max(high * 0.1, 1) : high - low;
    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = line
            ..strokeWidth = 0.5);
    }
    final points = List.generate(
        values.length,
        (i) => Offset(
            values.length == 1
                ? size.width / 2
                : i * size.width / (values.length - 1),
            size.height - 8 - (values[i] - low) / span * (size.height - 16)));
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    for (final p in points) {
      canvas.drawCircle(p, 3, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.accent != accent;
}

class WorkoutActivityGrid extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  final String metric;
  final int days;
  const WorkoutActivityGrid(
      {super.key,
      required this.activity,
      this.metric = 'durationSeconds',
      this.days = 84});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(),
        end = DateTime(now.year, now.month, now.day),
        start = end.subtract(Duration(days: days.clamp(1, 366) - 1)),
        calendarStart = start.subtract(Duration(days: start.weekday - 1));
    final totals = <String, double>{};
    for (final a in activity) {
      totals['${a['date']}'] =
          (totals['${a['date']}'] ?? 0) + (workoutNumber(a[metric]) ?? 0);
    }
    final visible = totals.entries
        .where((e) =>
            e.key.compareTo(start.toIso8601String().substring(0, 10)) >= 0 &&
            e.key.compareTo(end.toIso8601String().substring(0, 10)) <= 0)
        .map((e) => e.value)
        .toList();
    final maxValue =
        visible.isEmpty ? 1.0 : math.max(1.0, visible.reduce(math.max));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      WorkoutLabel('Activity · last $days days',
          style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 12),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                  (end.difference(calendarStart).inDays + 7) ~/ 7,
                  (week) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Column(
                          children: List.generate(7, (day) {
                        final date = calendarStart
                                .add(Duration(days: week * 7 + day)),
                            key = date.toIso8601String().substring(0, 10),
                            value = totals[key] ?? 0;
                        if (date.isBefore(start) || date.isAfter(end)) {
                          return const SizedBox(width: 16, height: 20);
                        }
                        return Tooltip(
                            message:
                                '${workoutDate(date)} · ${metric == 'volume' ? '${workoutValue(value)} kg' : '${(value / 60).round()} min'}',
                            child: Semantics(
                                label:
                                    '${workoutDate(date)}: ${workoutValue(value)}',
                                child: Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: value > 0
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(
                                                    alpha: 0.25 +
                                                        0.75 * value / maxValue)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.08)))));
                      }))))))
    ]);
  }
}
