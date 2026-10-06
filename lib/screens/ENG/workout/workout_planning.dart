import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import 'workout_ui.dart';

typedef WorkoutRoutineChoice = ({String action, List<int> dayIDs});

// A routine or rest-day tap commits the choice. Multiple routines remain a
// native Coach/Client option, behind an explicit combined-workout control.
Future<WorkoutRoutineChoice?> workoutRoutineChoice(BuildContext context,
    {required String title,
    required List<WorkoutDay> routines,
    required Iterable<int> selected,
    String? weeklyContext,
    bool changed = false,
    bool allowMove = false,
    bool allowStart = false}) {
  final chosen = selected.toSet();
  final dateOnly = weeklyContext != null;
  return workoutSheet<WorkoutRoutineChoice>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(builder: (sheet, update) {
            void close(String action, Iterable<int> ids) =>
                Navigator.pop(sheet, (action: action, dayIDs: ids.toList()));
            Widget rest() => ListTile(
                leading: const Icon(Icons.nights_stay_outlined),
                title: WorkoutLabel(
                    dateOnly ? 'Rest / skip this day' : 'Rest day'),
                trailing: chosen.isEmpty
                    ? Icon(Icons.check,
                        color: Theme.of(sheet).colorScheme.primary)
                    : null,
                onTap: () => close('save', const []));
            return SafeArea(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(sheet).height * .8),
                    child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(20),
                        children: [
                          WorkoutLabel(title,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          if (weeklyContext != null) ...[
                            const SizedBox(height: 8),
                            WorkoutLabel('Weekly plan: $weeklyContext',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(sheet)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            if (changed)
                              const WorkoutLabel('Changed for this day'),
                            const WorkoutLabel(
                                'Changes here apply only to this date.',
                                style: TextStyle(fontSize: 13)),
                          ],
                          const SizedBox(height: 12),
                          Card(
                              margin: EdgeInsets.zero,
                              child: Column(children: [
                                if (!dateOnly) rest(),
                                for (final routine in routines) ...[
                                  if (!dateOnly || routine != routines.first)
                                    const Divider(height: 1, indent: 16),
                                  ListTile(
                                      leading: Icon(workoutRoutineIcons[
                                              routine.configuration['icon']] ??
                                          Icons.fitness_center),
                                      title: WorkoutLabel(routine.name),
                                      subtitle: WorkoutLabel(
                                          '${routine.exercises.length} exercises'),
                                      trailing: chosen.contains(routine.id)
                                          ? Icon(Icons.check,
                                              color: Theme.of(sheet)
                                                  .colorScheme
                                                  .primary)
                                          : null,
                                      onTap: () => close('save', [routine.id])),
                                ],
                                if (dateOnly) ...[
                                  const Divider(height: 1, indent: 16),
                                  rest(),
                                  if (changed) ...[
                                    const Divider(height: 1, indent: 16),
                                    ListTile(
                                        leading: const Icon(Icons.restore),
                                        title: const WorkoutLabel(
                                            'Back to weekly plan'),
                                        onTap: () => close('reset', chosen)),
                                  ]
                                ]
                              ])),
                          if (allowMove && chosen.isNotEmpty)
                            TextButton.icon(
                                onPressed: () => close('move', chosen),
                                icon:
                                    const Icon(Icons.event_available_outlined),
                                label: const WorkoutLabel('Move workout')),
                          if (!dateOnly ||
                              routines.length > 1 ||
                              chosen.length > 1 ||
                              allowStart)
                            ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                initiallyExpanded: chosen.length > 1,
                                title: const WorkoutLabel(
                                    'More planning options',
                                    style: TextStyle(fontSize: 13)),
                                children: [
                                  const WorkoutLabel('Combine routines'),
                                  for (final routine in routines)
                                    CheckboxListTile(
                                        title: WorkoutLabel(routine.name),
                                        value: chosen.contains(routine.id),
                                        onChanged: (value) => update(() {
                                              if (value == true) {
                                                chosen.add(routine.id);
                                              } else {
                                                chosen.remove(routine.id);
                                              }
                                            })),
                                  ElevatedButton(
                                      onPressed: () => close('save', chosen),
                                      child:
                                          const WorkoutLabel('Save schedule')),
                                  if (!dateOnly)
                                    TextButton(
                                        onPressed: () => close('reset', chosen),
                                        child: const WorkoutLabel(
                                            'Use routine schedule')),
                                  if (allowStart)
                                    TextButton(
                                        onPressed: () => close('start', chosen),
                                        child: const WorkoutLabel(
                                            'Start selected routines')),
                                ]),
                        ])));
          }));
}
