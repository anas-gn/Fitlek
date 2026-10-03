import 'package:flutter/material.dart';
import '../../../services/apiService.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';

Future<bool> workoutBodyweightCheckIn(BuildContext context,
    {num? current}) async {
  final field = TextEditingController(
      text: current == null
          ? ''
          : workoutValue(WorkoutService.displayWeight(current)));
  final form = GlobalKey<FormState>();
  bool saving = false;
  final saved = await workoutDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
                  title: const WorkoutLabel('Body weight check-in'),
                  content: Form(
                      key: form,
                      child: TextFormField(
                          controller: field,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: 'Body weight (${WorkoutService.unit})'
                                  .workoutTr(context)),
                          validator: (v) {
                            final n = double.tryParse((v ?? '').replaceAll(
                                (',').workoutTr(context),
                                ('.').workoutTr(context)));
                            return n == null ||
                                    !n.isFinite ||
                                    WorkoutService.storedWeight(n) < 1 ||
                                    WorkoutService.storedWeight(n) > 500
                                ? 'Enter a valid body weight'.workoutTr(context)
                                : null;
                          })),
                  actions: [
                    TextButton(
                        onPressed:
                            saving ? null : () => Navigator.pop(context, false),
                        child: const WorkoutLabel('Skip')),
                    ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                update(() => saving = true);
                                try {
                                  WorkoutService.checked(
                                      await ApiService.post('/weight-history', {
                                    'weight': WorkoutService.storedWeight(
                                        double.parse(
                                            field.text.replaceAll(',', '.')))
                                  }));
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    workoutError(context, e);
                                    update(() => saving = false);
                                  }
                                }
                              },
                        child: const WorkoutLabel('Save'))
                  ])));
  field.dispose();
  return saved == true;
}
