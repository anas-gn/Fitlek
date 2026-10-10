import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import 'workout_ui.dart';
import '../../../services/workout_service.dart';

class WorkoutLineChart extends StatefulWidget {
  final List<double> values;
  final String label;
  final List<DateTime>? dates;
  final double? goal;
  final String unit;
  final bool invert;
  final bool compact;
  final Color? color;
  const WorkoutLineChart(
      {super.key,
      required this.values,
      required this.label,
      this.dates,
      this.goal,
      this.invert = false,
      this.compact = false,
      this.color,
      this.unit = ''});
  @override
  State<WorkoutLineChart> createState() => _WorkoutLineChartState();
}

class _WorkoutLineChartState extends State<WorkoutLineChart> {
  int? _selected;
  List<(DateTime, double)> get _points {
    final points = <(DateTime, double)>[];
    for (var i = 0; i < widget.values.length; i++) {
      if (!widget.values[i].isFinite) continue;
      points.add((
        widget.dates != null && i < widget.dates!.length
            ? widget.dates![i]
            : DateTime.utc(2000).add(Duration(days: i)),
        widget.values[i]
      ));
    }
    points.sort((a, b) => a.$1.compareTo(b.$1));
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    if (points.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(16),
          child: WorkoutLabel('No data for this period.'));
    }
    final selected = _selected == null
        ? null
        : points[_selected!.clamp(0, points.length - 1)];
    return Semantics(
        label:
            '${widget.label}: ${points.map((p) => '${workoutDate(p.$1)} ${workoutValue(p.$2)} ${widget.unit}').join(', ')}',
        child: Column(children: [
          if (selected != null)
            WorkoutLabel(
                '${widget.dates == null ? '' : '${workoutDate(selected.$1)} · '}${workoutValue(selected.$2)} ${widget.unit}',
                key: const ValueKey('workout-chart-reading'),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          SizedBox(
              height: widget.compact ? 120 : 150,
              width: double.infinity,
              child: LayoutBuilder(builder: (context, constraints) {
                void select(double x) {
                  final width = math.max(1.0, constraints.maxWidth - 56);
                  final fraction = ((x - 40) / width).clamp(0.0, 1.0);
                  final start = points.first.$1.millisecondsSinceEpoch;
                  final target = start +
                      fraction *
                          (points.last.$1.millisecondsSinceEpoch - start);
                  var nearest = 0;
                  for (var i = 1; i < points.length; i++) {
                    if ((points[i].$1.millisecondsSinceEpoch - target).abs() <
                        (points[nearest].$1.millisecondsSinceEpoch - target)
                            .abs()) {
                      nearest = i;
                    }
                  }
                  setState(() => _selected = nearest);
                }

                return MouseRegion(
                    onHover: (event) => select(event.localPosition.dx),
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (event) => select(event.localPosition.dx),
                        onHorizontalDragUpdate: (event) =>
                            select(event.localPosition.dx),
                        child: CustomPaint(
                            painter: _LinePainter(
                                points,
                                widget.color ??
                                    Theme.of(context).colorScheme.primary,
                                Theme.of(context).dividerColor,
                                Theme.of(context).colorScheme.onSurfaceVariant,
                                widget.goal,
                                _selected,
                                widget.invert,
                                widget.compact))));
              })),
          const SizedBox(height: 8),
          if (widget.compact && widget.dates != null)
            WorkoutLabel(
                MaterialLocalizations.of(context)
                    .formatMonthYear(points.last.$1),
                style: const TextStyle(fontSize: 11, color: Colors.grey))
          else
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: WorkoutLabel(
                      widget.dates == null
                          ? workoutValue(points.first.$2)
                          : workoutDate(points.first.$1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12))),
              Expanded(
                  child: WorkoutLabel(
                      widget.dates == null
                          ? workoutValue(points.last.$2)
                          : workoutDate(points.last.$1),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)))
            ])
        ]));
  }
}

class _LinePainter extends CustomPainter {
  final List<(DateTime, double)> values;
  final Color accent, line, textColor;
  final double? goal;
  final int? selected;
  final bool invert;
  final bool compact;
  _LinePainter(this.values, this.accent, this.line, this.textColor, this.goal,
      this.selected, this.invert, this.compact);
  @override
  void paint(Canvas canvas, Size size) {
    var low = values.map((p) => p.$2).reduce(math.min),
        high = values.map((p) => p.$2).reduce(math.max);
    if (goal != null && goal!.isFinite) {
      low = math.min(low, goal!);
      high = math.max(high, goal!);
    }
    final pad = high == low ? 1.0 : (high - low) * 0.12;
    if (!compact) {
      low -= pad;
      high += pad;
    }
    if (compact) {
      low = low.floorToDouble();
      high = high.ceilToDouble();
      if (high == low) high = low + 1;
    }
    final span = high - low;
    double y(double v) =>
        12 + (invert ? v - low : high - v) / span * (size.height - 24);
    void label(String value, Offset position, Color color) {
      final painter = TextPainter(
          text: TextSpan(
              text: value,
              style: TextStyle(
                  fontFamily: 'SirvyaWorkout', fontSize: 10, color: color)),
          textDirection: TextDirection.ltr)
        ..layout();
      painter.paint(canvas, position);
    }

    final intervals = compact ? 2 : 3;
    for (int i = 0; i <= intervals; i++) {
      final rowY = 12 + (size.height - 24) * i / intervals;
      canvas.drawLine(
          Offset(40, rowY),
          Offset(size.width - 16, rowY),
          Paint()
            ..color = line
            ..strokeWidth = 0.5);
      label(
          workoutValue(invert
              ? low + span * i / intervals
              : high - span * i / intervals),
          Offset(0, rowY - 6),
          textColor);
    }
    if (goal != null && goal!.isFinite) {
      for (double x = 40; x < size.width - 16; x += 11) {
        canvas.drawLine(
            Offset(x, y(goal!)),
            Offset(math.min(x + 6, size.width - 16), y(goal!)),
            Paint()
              ..color = Colors.amber
              ..strokeWidth = 1.5);
      }
      label(workoutValue(goal), Offset(size.width - 52, y(goal!) - 13),
          Colors.amber);
    }
    final first = values.first.$1.millisecondsSinceEpoch;
    final period = values.last.$1.millisecondsSinceEpoch - first;
    final points = List.generate(
        values.length,
        (i) => Offset(
            period == 0
                ? (size.width + 24) / 2
                : 40 +
                    (values[i].$1.millisecondsSinceEpoch - first) /
                        period *
                        (size.width - 56),
            y(values[i].$2)));
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (compact && points.length > 1) {
      final fill = Path.from(path)
        ..lineTo(points.last.dx, size.height - 12)
        ..lineTo(points.first.dx, size.height - 12)
        ..close();
      canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: .22),
                  accent.withValues(alpha: .02)
                ]).createShader(Offset.zero & size));
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
    if (selected != null && selected! < points.length) {
      final p = points[selected!];
      canvas.drawLine(Offset(p.dx, 8), Offset(p.dx, size.height - 8),
          Paint()..color = line);
      canvas.drawCircle(p, 5, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values ||
      old.accent != accent ||
      old.line != line ||
      old.goal != goal ||
      old.selected != selected ||
      old.invert != invert ||
      old.compact != compact ||
      old.textColor != textColor;
}

class WorkoutActivityGrid extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  final String metric;
  final int days;
  final DateTime? today;
  final void Function(DateTime)? onDay;
  const WorkoutActivityGrid(
      {super.key,
      required this.activity,
      this.metric = 'durationSeconds',
      this.days = 84,
      this.today,
      this.onDay});
  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now(),
        end = DateTime(now.year, now.month, now.day),
        start = days == 365
            ? end.subtract(Duration(days: end.weekday - 1 + 52 * 7))
            : end.subtract(Duration(days: days.clamp(1, 366) - 1)),
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
    final positive = visible.where((v) => v > 0).toList()..sort();
    double quartile(double fraction) => positive.isEmpty
        ? 0
        : positive[
            (fraction * positive.length).floor().clamp(0, positive.length - 1)];
    final q1 = quartile(.25), q2 = quartile(.5), q3 = quartile(.75);
    final theme = Theme.of(context).colorScheme;
    Color shade(int level) => level == 0
        ? theme.onSurface.withValues(alpha: .08)
        : theme.primary.withValues(alpha: .2 + level * .2);
    Widget square(int level) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: shade(level), borderRadius: BorderRadius.circular(2)));
    final weeks = (end.difference(calendarStart).inDays + 7) ~/ 7;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              const SizedBox(height: 18),
              for (var day = 0; day < 7; day++)
                SizedBox(
                    width: 30,
                    height: 13,
                    child: WorkoutLabel(
                        day == 0
                            ? 'Mon'
                            : day == 2
                                ? 'Wed'
                                : day == 4
                                    ? 'Fri'
                                    : '',
                        style: const TextStyle(fontSize: 9)))
            ]),
            for (var week = 0; week < weeks; week++)
              Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(children: [
                    SizedBox(
                        width: 10,
                        height: 18,
                        child: Stack(clipBehavior: Clip.none, children: [
                          if (calendarStart.add(Duration(days: week * 7)).day <=
                                  7 &&
                              week < weeks - 2)
                            Positioned(
                                left: 0,
                                top: 0,
                                width: 30,
                                child: WorkoutLabel(
                                    [
                                      'Jan',
                                      'Feb',
                                      'Mar',
                                      'Apr',
                                      'May',
                                      'Jun',
                                      'Jul',
                                      'Aug',
                                      'Sep',
                                      'Oct',
                                      'Nov',
                                      'Dec'
                                    ][calendarStart
                                            .add(Duration(days: week * 7))
                                            .month -
                                        1],
                                    style: const TextStyle(fontSize: 9)))
                        ])),
                    for (var day = 0; day < 7; day++)
                      Builder(builder: (context) {
                        final date =
                            calendarStart.add(Duration(days: week * 7 + day));
                        final key = date.toIso8601String().substring(0, 10),
                            value = totals[key] ?? 0;
                        if (date.isBefore(start)) {
                          return const SizedBox(width: 10, height: 13);
                        }
                        final level = !totals.containsKey(key)
                            ? 0
                            : value == 0
                                ? 1
                                : value >= q3
                                    ? 4
                                    : value >= q2
                                        ? 3
                                        : value >= q1
                                            ? 2
                                            : 1;
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Tooltip(
                                message:
                                    '${workoutDate(date)} · ${metric == 'volume' ? '${workoutValue(WorkoutService.displayWeight(value))} ${WorkoutService.unit}' : '${(value / 60).round()} min'}',
                                child: InkWell(
                                    onTap: onDay == null ||
                                            !totals.containsKey(key) ||
                                            date.isAfter(end)
                                        ? null
                                        : () => onDay!(date),
                                    child: Semantics(
                                        label:
                                            '${workoutDate(date)}: ${workoutValue(value)}',
                                        child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                                color: shade(level),
                                                border: date == end
                                                    ? Border.all(
                                                        color: theme.primary,
                                                        width: 1)
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        2)))))));
                      })
                  ]))
          ])),
      const SizedBox(height: 8),
      Align(
          alignment: Alignment.centerRight,
          child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                WorkoutLabel(metric == 'volume' ? 'Less volume' : 'Less time',
                    style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 5),
                for (var level = 0; level <= 4; level++)
                  Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: square(level)),
                WorkoutLabel(metric == 'volume' ? 'More volume' : 'More time',
                    style: const TextStyle(fontSize: 10))
              ]))
    ]);
  }
}
