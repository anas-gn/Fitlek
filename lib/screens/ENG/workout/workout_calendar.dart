import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'workout_progress.dart';

Future<bool> workoutOpenRecordedDate(BuildContext context, DateTime date,
    List<Map<String, dynamic>> activity) async {
  final key = date.toIso8601String().substring(0, 10);
  final rows = activity
      .where((a) =>
          '${a['date']}'.startsWith(key) && workoutInt(a['sessionID']) > 0)
      .toList();
  if (rows.isEmpty) return false;
  final id = rows.length == 1
      ? workoutInt(rows.single['sessionID'])
      : await workoutSheet<int>(
          context: context,
          builder: (sheetContext) => SafeArea(
                  child: ListView(shrinkWrap: true, children: [
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: WorkoutLabel(workoutDate(date),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600))),
                for (final row in rows)
                  ListTile(
                      title: WorkoutLabel('${row['name'] ?? 'Workout'}'),
                      subtitle: WorkoutLabel(
                          '${(workoutInt(row['durationSeconds']) / 60).round()} min · ${row['setCount'] ?? 0} sets'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(
                          sheetContext, workoutInt(row['sessionID'])))
              ])));
  if (id != null && context.mounted) {
    await Navigator.push(context,
        WorkoutRoute(builder: (_) => WorkoutHistoryDetail(sessionID: id)));
  }
  return true;
}

// Calendar uses dates returned by the training API in the user's workout zone.
Future<DateTime?> workoutCalendar(BuildContext context,
        {required List<Map<String, dynamic>> activity,
        DateTime? initialDate,
        DateTime? today,
        bool Function(DateTime)? planned,
        Set<String> overrides = const {}}) =>
    workoutSheet<DateTime>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _WorkoutCalendar(
            activity: activity,
            initialDate: initialDate,
            today: today,
            planned: planned,
            overrides: overrides));

class _WorkoutCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> activity;
  final DateTime? initialDate;
  final DateTime? today;
  final bool Function(DateTime)? planned;
  final Set<String> overrides;
  const _WorkoutCalendar(
      {required this.activity,
      this.initialDate,
      this.today,
      this.planned,
      this.overrides = const {}});
  @override
  State<_WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<_WorkoutCalendar> {
  late DateTime _month;
  String _key(DateTime date) => date.toIso8601String().substring(0, 10);
  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? widget.today ?? DateTime.now();
    _month = DateTime(date.year, date.month);
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final now = widget.today ?? DateTime.now(), offset = _month.weekday - 1;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final counts = <String, int>{};
    for (final row in widget.activity) {
      final key = '${row['date']}'.substring(0, 10);
      counts[key] = (counts[key] ?? 0) + workoutInt(row['count'] ?? 1);
    }
    final monthRows = widget.activity
        .where(
            (row) => '${row['date']}'.startsWith(_key(_month).substring(0, 7)))
        .toList();
    final monthCount = monthRows.fold<int>(
        0, (total, row) => total + workoutInt(row['count'] ?? 1));
    final seconds = monthRows.fold<int>(
        0, (total, row) => total + workoutInt(row['durationSeconds']));
    final volume = monthRows.fold<double>(
        0, (total, row) => total + (workoutNumber(row['volume']) ?? 0));
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .8),
            child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        IconButton(
                            tooltip: 'Previous month'.workoutTr(context),
                            onPressed: () => setState(() => _month =
                                DateTime(_month.year, _month.month - 1)),
                            icon: const Icon(Icons.chevron_left)),
                        Expanded(
                            child: WorkoutLabel(
                                '${months[_month.month - 1]} ${_month.year}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600))),
                        IconButton(
                            tooltip: 'Next month'.workoutTr(context),
                            onPressed: () => setState(() => _month =
                                DateTime(_month.year, _month.month + 1)),
                            icon: const Icon(Icons.chevron_right))
                      ]),
                      WorkoutLabel(
                          monthCount == 0
                              ? 'No workouts this month'
                              : '$monthCount ${monthCount == 1 ? 'workout' : 'workouts'} · ${seconds ~/ 60} min · ${workoutValue(WorkoutService.displayWeight(volume))} ${WorkoutService.unit}',
                          style: TextStyle(
                              fontSize: 12, color: colors.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Row(children: [
                        for (final day in WorkoutText.weekdays)
                          Expanded(
                              child: WorkoutLabel(day.substring(0, 2),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12)))
                      ]),
                      const SizedBox(height: 8),
                      GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7),
                          itemCount: ((offset + days + 6) ~/ 7) * 7,
                          itemBuilder: (context, index) {
                            final number = index - offset + 1;
                            if (number < 1 || number > days) {
                              return const SizedBox.shrink();
                            }
                            final date =
                                    DateTime(_month.year, _month.month, number),
                                count = counts[_key(date)] ?? 0;
                            final today = _key(date) ==
                                _key(DateTime(now.year, now.month, now.day));
                            final planned = widget.planned?.call(date) ?? false;
                            final rescheduled =
                                widget.overrides.contains(_key(date));
                            return InkWell(
                                key: ValueKey('calendar-${_key(date)}'),
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => Navigator.pop(context, date),
                                child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: today
                                            ? Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary)
                                            : null,
                                        color: count > 0
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: .15)
                                            : null),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          WorkoutLabel('$number'),
                                          if (count > 0 || planned)
                                            Container(
                                                width: 5,
                                                height: 5,
                                                margin: const EdgeInsets.only(
                                                    top: 3),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: count > 0
                                                        ? colors.primary
                                                        : rescheduled
                                                            ? Colors.orange
                                                            : colors
                                                                .onSurfaceVariant))
                                        ])));
                          }),
                      const SizedBox(height: 12),
                      Wrap(
                          spacing: 14,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final item in <(String, Color)>[
                              ('Trained', colors.primary),
                              ('Planned', colors.onSurfaceVariant),
                              ('Rescheduled', Colors.orange)
                            ])
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: item.$2)),
                                const SizedBox(width: 5),
                                WorkoutLabel(item.$1,
                                    style: const TextStyle(fontSize: 12))
                              ])
                          ]),
                      const SizedBox(height: 10),
                      const WorkoutLabel(
                          'Select a date to view training or change that day’s workout.',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center)
                    ])))));
  }
}
