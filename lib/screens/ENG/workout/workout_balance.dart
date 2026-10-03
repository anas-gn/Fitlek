import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';

class WorkoutBalanceCard extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  const WorkoutBalanceCard({super.key, required this.records});
  @override
  State<WorkoutBalanceCard> createState() => _WorkoutBalanceCardState();
}

class _WorkoutBalanceCardState extends State<WorkoutBalanceCard> {
  int? _anchor;
  bool _saving = false;
  Future<void> _save({int? anchor, List<Map<String, dynamic>>? targets}) async {
    setState(() => _saving = true);
    try {
      final prefs = await WorkoutService.put('/preferences', {
        ...WorkoutService.preferences,
        if (anchor != null) 'balanceAnchorID': anchor,
        if (targets != null) 'balanceTargets': targets
      });
      WorkoutService.preferences = prefs;
      if (mounted) setState(() => _anchor = anchor ?? _anchor);
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _target(Map<String, dynamic> r) async {
    final targets = workoutRows(WorkoutService.preferences['balanceTargets']);
    final old =
        targets.where((v) => v['exerciseID'] == r['exerciseID']).firstOrNull;
    final controller =
        TextEditingController(text: '${old?['targetPercent'] ?? 100}');
    final form = GlobalKey<FormState>();
    final saved = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: WorkoutLabel('${r['name']}'),
                content: Form(
                    key: form,
                    child: TextFormField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: 'Target ratio (%)'.workoutTr(context)),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return n == null || !n.isFinite || n < 1 || n > 500
                              ? 'Enter a value from 1 to 500'.workoutTr(context)
                              : null;
                        })),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const WorkoutLabel('Cancel')),
                  ElevatedButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const WorkoutLabel('Save'))
                ]));
    if (saved == true && mounted) {
      targets.removeWhere((v) => v['exerciseID'] == r['exerciseID']);
      targets.add({
        'exerciseID': r['exerciseID'],
        'targetPercent': double.parse(controller.text)
      });
      await _save(targets: targets);
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.records
        .where((r) => (workoutNumber(r['estimated1RM']) ?? 0) > 0)
        .toList();
    if (records.length < 2) return const SizedBox.shrink();
    final preferred =
        _anchor ?? workoutInt(WorkoutService.preferences['balanceAnchorID']);
    final anchor = records
            .where((r) => workoutInt(r['exerciseID']) == preferred)
            .firstOrNull ??
        records.first;
    final anchorID = workoutInt(anchor['exerciseID']),
        base = workoutNumber(anchor['estimated1RM'])!;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const WorkoutLabel('Structural balance',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const WorkoutLabel(
                  'Compare recorded estimated 1RM against an anchor lift. Set ratios with your coach for comparable exercise variants.'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                  initialValue: anchorID,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: 'Anchor exercise'.workoutTr(context)),
                  items: records
                      .map((r) => DropdownMenuItem(
                          value: workoutInt(r['exerciseID']),
                          child: WorkoutLabel('${r['name']}',
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: _saving ? null : (v) => _save(anchor: v)),
              for (final r in records
                  .where((r) => r['exerciseID'] != anchor['exerciseID']))
                Builder(builder: (context) {
                  final pct = workoutNumber(r['estimated1RM'])! / base * 100;
                  final target =
                      workoutRows(WorkoutService.preferences['balanceTargets'])
                          .where((v) => v['exerciseID'] == r['exerciseID'])
                          .firstOrNull;
                  return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(children: [
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: WorkoutLabel('${r['name']}'),
                            subtitle: WorkoutLabel(
                                'Anchor ratio: ${pct.toStringAsFixed(0)}%${target == null ? '' : ' · target ${target['targetPercent']}%'}'),
                            trailing: IconButton(
                                tooltip: 'Set target ratio'.workoutTr(context),
                                onPressed: _saving ? null : () => _target(r),
                                icon: const Icon(Icons.tune))),
                        if (target != null)
                          LinearProgressIndicator(
                              value: (pct /
                                      (workoutNumber(target['targetPercent']) ??
                                          100))
                                  .clamp(0, 1))
                      ]));
                }),
              if (_saving) const LinearProgressIndicator()
            ])));
  }
}
