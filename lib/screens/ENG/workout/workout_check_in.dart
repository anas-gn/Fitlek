import 'package:flutter/material.dart';
import '../../../services/apiService.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'workout_set_row.dart';

// Fixed slider bounds keep the thumb predictable throughout a drag.
class WorkoutWeightInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  const WorkoutWeightInput(
      {super.key, required this.controller, this.enabled = true});
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, text, _) {
            final maximum = WorkoutService.unit == 'lb' ? 660.0 : 300.0;
            final value = double.tryParse(text.text.replaceAll(',', '.')) ?? 70;
            void change(double n) => controller.text =
                workoutValue((n.clamp(1, maximum) * 10).round() / 10);
            return Column(children: [
              WorkoutNumberStepper(
                  controller: controller,
                  label: 'Body weight (${WorkoutService.unit})',
                  step: .1,
                  min: 1,
                  max: maximum,
                  enabled: enabled,
                  prominent: true,
                  onChanged: () {}),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final step in [-1.0, -.5, .5, 1.0])
                  ActionChip(
                      label: WorkoutLabel(
                          '${step > 0 ? '+' : ''}${workoutValue(step)}'),
                      onPressed: enabled ? () => change(value + step) : null)
              ]),
              Slider(
                  value: value.clamp(1, maximum),
                  min: 1,
                  max: maximum,
                  divisions: ((maximum - 1) * 2).round(),
                  onChanged: enabled ? change : null)
            ]);
          });
}

// null cancels the start; false explicitly skips weighing in.
Future<bool?> workoutBodyweightCheckIn(BuildContext context,
    {num? current,
    bool starting = false,
    List<Map<String, dynamic>> readings = const []}) async {
  final field = TextEditingController(
      text: current == null
          ? '70'
          : workoutValue(WorkoutService.displayWeight(current)));
  final recent = [...readings]
    ..sort((a, b) => '${b['recordedAt']}'.compareTo('${a['recordedAt']}'));
  bool saving = false;
  String? error;
  final saved = await workoutSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, update) {
            Future<void> save() async {
              final displayed =
                  double.tryParse(field.text.replaceAll(',', '.'));
              if (displayed == null ||
                  !displayed.isFinite ||
                  WorkoutService.storedWeight(displayed) < 1 ||
                  WorkoutService.storedWeight(displayed) > 500) {
                update(() => error = 'Enter a valid body weight');
                return;
              }
              update(() {
                saving = true;
                error = null;
              });
              try {
                final today = DateTime.now().toIso8601String().substring(0, 10);
                final existing = recent
                    .where((r) =>
                        '${r['recordedAt']}'.startsWith(today) &&
                        workoutInt(r['id']) > 0)
                    .firstOrNull;
                final body = {
                  'weight': WorkoutService.storedWeight(displayed),
                  'recordedAt': today,
                  if (existing?['note'] != null) 'note': existing!['note']
                };
                WorkoutService.checked(existing == null
                    ? await ApiService.post('/weight-history', body)
                    : await ApiService.put(
                        '/weight-history/${existing['id']}', body));
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  workoutError(context, e);
                  update(() => saving = false);
                }
              }
            }

            return SafeArea(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20,
                        20 + MediaQuery.viewInsetsOf(context).bottom),
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * .8),
                        child: SingleChildScrollView(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              WorkoutLabel(
                                  starting
                                      ? 'Quick check-in'
                                      : 'Log body weight',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              WorkoutLabel(
                                  starting
                                      ? 'Slide or tap to set your weight before training.'
                                      : 'Today · ${workoutDate(DateTime.now())}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                              const SizedBox(height: 16),
                              WorkoutWeightInput(
                                  controller: field, enabled: !saving),
                              if (error != null)
                                WorkoutLabel(error!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error)),
                              ElevatedButton(
                                  onPressed: saving ? null : save,
                                  child: WorkoutLabel(starting
                                      ? 'Save & start workout'
                                      : 'Save')),
                              if (starting) ...[
                                TextButton(
                                    onPressed: saving
                                        ? null
                                        : () => Navigator.pop(context, false),
                                    child: const WorkoutLabel(
                                        'Start without weighing in')),
                                TextButton(
                                    onPressed: saving
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: const WorkoutLabel(
                                        'Choose a different workout'))
                              ] else ...[
                                TextButton(
                                    onPressed: saving
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: const WorkoutLabel('Cancel')),
                                if (recent.isNotEmpty)
                                  const WorkoutLabel('Recent weigh-ins'),
                                for (final row in recent.take(3))
                                  ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: WorkoutLabel(
                                          workoutDate(row['recordedAt'])),
                                      subtitle: WorkoutLabel(
                                          '${workoutValue(WorkoutService.displayWeight(workoutNumber(row['weight']) ?? 0))} ${WorkoutService.unit}'),
                                      trailing: workoutInt(row['id']) == 0
                                          ? null
                                          : IconButton(
                                              tooltip: 'Delete weigh-in'
                                                  .workoutTr(context),
                                              onPressed: saving
                                                  ? null
                                                  : () async {
                                                      update(
                                                          () => saving = true);
                                                      try {
                                                        WorkoutService.checked(
                                                            await ApiService.delete(
                                                                '/weight-history/${row['id']}'));
                                                        if (context.mounted) {
                                                          update(() => recent
                                                              .remove(row));
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          workoutError(
                                                              context, e);
                                                        }
                                                      } finally {
                                                        if (context.mounted) {
                                                          update(() =>
                                                              saving = false);
                                                        }
                                                      }
                                                    },
                                              icon: const Icon(
                                                  Icons.delete_outline)))
                              ]
                            ])))));
          }));
  field.dispose();
  return saved;
}
