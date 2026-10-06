import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'workout_charts.dart';
import 'workout_check_in.dart';

// Training measurements use the existing historical weight API, in stored kg.
List<Map<String, dynamic>> workoutWeightReadings(dynamic rows) {
  final result = workoutRows(rows)
      .where((r) =>
          workoutNumber(r['weight'])?.isFinite == true &&
          DateTime.tryParse('${r['recordedAt']}') != null)
      .toList();
  // Existing profile history can have several weigh-ins on one day. Show its
  // latest reading without deleting those historical records.
  final byDay = <String, Map<String, dynamic>>{};
  for (final row in result) {
    final day = DateTime.parse('${row['recordedAt']}')
        .toIso8601String()
        .substring(0, 10);
    final previous = byDay[day];
    if (previous == null ||
        workoutInt(row['id']) > workoutInt(previous['id']) ||
        workoutInt(row['id']) == workoutInt(previous['id']) &&
            '${row['createdAt'] ?? row['recordedAt']}'.compareTo(
                    '${previous['createdAt'] ?? previous['recordedAt']}') >
                0) {
      byDay[day] = row;
    }
  }
  final daily = byDay.values.toList()
    ..sort((a, b) => '${a['recordedAt']}'.compareTo('${b['recordedAt']}'));
  return daily;
}

bool? workoutWeightMovesTowardGoal(
        double previous, double current, double? goal) =>
    goal == null || current == previous
        ? null
        : (current - goal).abs() < (previous - goal).abs();

class WorkoutBodyweightCard extends StatelessWidget {
  final List<Map<String, dynamic>> readings;
  final double? goal;
  final Future<void> Function()? reload;
  final Widget? controls;
  final int? limit;
  const WorkoutBodyweightCard(
      {super.key,
      required this.readings,
      this.goal,
      this.reload,
      this.controls,
      this.limit = 30});

  Future<void> _goal(BuildContext context) async {
    final field = TextEditingController(
        text: goal == null
            ? ''
            : workoutValue(WorkoutService.displayWeight(goal!)));
    final form = GlobalKey<FormState>();
    var saving = false;
    await workoutDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, update) {
              Future<void> save(double? value) async {
                update(() => saving = true);
                try {
                  final preferences = await WorkoutService.get('/preferences');
                  final result = await WorkoutService.put('/preferences',
                      {...preferences, 'bodyweightGoal': value});
                  WorkoutService.preferences = result;
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  if (context.mounted) {
                    workoutError(context, error);
                    update(() => saving = false);
                  }
                }
              }

              return AlertDialog(
                  title: const WorkoutLabel('Body weight goal'),
                  content: Form(
                      key: form,
                      child: TextFormField(
                          controller: field,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Body weight (${WorkoutService.unit})'
                                  .workoutTr(context)),
                          validator: (text) {
                            final n = double.tryParse(
                                (text ?? '').replaceAll(',', '.'));
                            return n == null ||
                                    !n.isFinite ||
                                    WorkoutService.storedWeight(n) < 1 ||
                                    WorkoutService.storedWeight(n) > 500
                                ? 'Enter a valid body weight'.workoutTr(context)
                                : null;
                          })),
                  actions: [
                    if (goal != null)
                      TextButton(
                          onPressed: saving ? null : () => save(null),
                          child: const WorkoutLabel('Remove goal')),
                    TextButton(
                        onPressed: saving ? null : () => Navigator.pop(context),
                        child: const WorkoutLabel('Cancel')),
                    ElevatedButton(
                        onPressed: saving
                            ? null
                            : () {
                                if (form.currentState!.validate()) {
                                  save(WorkoutService.storedWeight(double.parse(
                                      field.text.replaceAll(',', '.'))));
                                }
                              },
                        child: const WorkoutLabel('Save'))
                  ]);
            }));
    field.dispose();
    await reload?.call();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = workoutWeightReadings(readings);
    final latest = sorted.lastOrNull;
    final weight = workoutNumber(latest?['weight']);
    final previous = sorted.length > 1
        ? workoutNumber(sorted[sorted.length - 2]['weight'])
        : null;
    final delta = weight == null || previous == null ? null : weight - previous;
    final toward = weight == null || previous == null
        ? null
        : workoutWeightMovesTowardGoal(previous, weight, goal);
    final recent = sorted
        .skip(
            (sorted.length - (limit ?? sorted.length)).clamp(0, sorted.length))
        .toList();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                    child: WorkoutLabel('Body weight',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600))),
                TextButton.icon(
                    onPressed: reload == null ? null : () => _goal(context),
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: WorkoutLabel(goal == null
                        ? 'Goal'
                        : workoutValue(WorkoutService.displayWeight(goal!)))),
                TextButton.icon(
                    onPressed: reload == null
                        ? null
                        : () async {
                            await workoutBodyweightCheckIn(context,
                                current: weight, readings: sorted);
                            await reload?.call();
                          },
                    icon: const Icon(Icons.add, size: 16),
                    label: const WorkoutLabel('Log'))
              ]),
              if (controls != null) controls!,
              if (weight == null)
                const WorkoutLabel(
                    'Log your body weight to begin tracking your progress.')
              else ...[
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      WorkoutLabel(
                          '${workoutValue(WorkoutService.displayWeight(weight))} ${WorkoutService.unit}',
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w600)),
                      if (delta != null && delta != 0)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                              delta > 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                              color: toward == null
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : toward
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.orange),
                          WorkoutLabel(
                              workoutValue(
                                  WorkoutService.displayWeight(delta.abs())),
                              style: TextStyle(
                                  color: toward == null
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                      : toward
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.orange))
                        ]),
                      WorkoutLabel(workoutDate(latest!['recordedAt']),
                          style: const TextStyle(fontSize: 12))
                    ]),
                if (goal != null)
                  WorkoutLabel(
                      (weight - goal!).abs() < 0.05
                          ? 'Goal reached'
                          : '${workoutValue(WorkoutService.displayWeight((weight - goal!).abs()))} ${WorkoutService.unit} ${goal! > weight ? 'to gain' : 'to lose'}',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.amber)),
                const SizedBox(height: 8),
                WorkoutLineChart(
                    label: 'Body weight',
                    values: recent
                        .map((r) => WorkoutService.displayWeight(
                            workoutNumber(r['weight'])!))
                        .toList(),
                    dates: recent
                        .map((r) => DateTime.parse('${r['recordedAt']}'))
                        .toList(),
                    goal: goal == null
                        ? null
                        : WorkoutService.displayWeight(goal!),
                    unit: WorkoutService.unit)
              ]
            ])));
  }
}
