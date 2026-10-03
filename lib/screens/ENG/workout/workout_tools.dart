import 'package:flutter/material.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';

class PlateResult {
  final double achieved;
  final List<double> perSide;
  const PlateResult(this.achieved, this.perSide);
}

// Bounded inventory, in 10 gram increments; each entry counts individual plates.
PlateResult calculatePlates(
    double target, double bar, List<Map<String, dynamic>> inventory) {
  if (!target.isFinite || !bar.isFinite || bar < 0 || target < bar) {
    return PlateResult(bar, []);
  }
  final limit = ((target - bar) * 50).floor();
  final possibilities = <int, List<double>>{0: []};
  final sorted = inventory.toList()
    ..sort((a, b) => (b['weight'] as num).compareTo(a['weight'] as num));
  for (final plate in sorted) {
    final weight = (plate['weight'] as num).toDouble(),
        pairs = (plate['count'] as num).toInt() ~/ 2;
    if (weight <= 0 || !weight.isFinite || pairs < 1) continue;
    final units = (weight * 100).round();
    for (int n = 0; n < pairs; n++) {
      for (final entry in possibilities.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key))) {
        final next = entry.key + units;
        if (next <= limit &&
            (!possibilities.containsKey(next) ||
                possibilities[next]!.length > entry.value.length + 1)) {
          possibilities[next] = [...entry.value, weight];
        }
      }
    }
  }
  final best = possibilities.keys.reduce((a, b) => a > b ? a : b);
  return PlateResult(bar + best / 50, possibilities[best]!);
}

List<(double, int)> workoutWarmups(double target, {double bar = 20}) {
  if (target <= 0) return [];
  final loads = <double>{
    if (bar <= target) bar,
    for (final p in [0.4, 0.6, 0.8]) (target * p / 2.5).floor() * 2.5
  }..removeWhere((v) => v <= 0 || v >= target);
  final sorted = loads.toList()..sort();
  return [
    for (int i = 0; i < sorted.length; i++)
      (
        sorted[i],
        i == 0
            ? 8
            : i == 1
                ? 5
                : 3
      )
  ];
}

class WorkoutToolsScreen extends StatefulWidget {
  final double initialWeight;
  const WorkoutToolsScreen({super.key, this.initialWeight = 60});
  @override
  State<WorkoutToolsScreen> createState() => _WorkoutToolsScreenState();
}

class _WorkoutToolsScreenState extends State<WorkoutToolsScreen> {
  late final TextEditingController _weight, _bar;
  final _reps = TextEditingController(text: '5');
  List<Map<String, dynamic>> _inventory = [];
  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
        text: workoutValue(WorkoutService.displayWeight(widget.initialWeight)));
    _bar = TextEditingController(
        text: workoutValue(WorkoutService.displayWeight(
            WorkoutService.preferences['barWeight'] ?? 20)));
    _inventory = [
      for (final row in (WorkoutService.preferences['plates'] as List? ??
          [
            for (final v in [25, 20, 15, 10, 5, 2.5, 1.25])
              {'weight': v, 'count': 4}
          ]))
        Map<String, dynamic>.from(row)
    ];
  }

  @override
  void dispose() {
    _weight.dispose();
    _bar.dispose();
    _reps.dispose();
    super.dispose();
  }

  double _kg(TextEditingController c) => WorkoutService.storedWeight(
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0);
  Future<void> _inventoryDialog() async {
    final field = TextEditingController(
        text: _inventory
            .map((p) =>
                '${workoutValue(WorkoutService.displayWeight(p['weight']))}:${p['count']}')
            .join(', '));
    final form = GlobalKey<FormState>();
    List<Map<String, dynamic>> parse() {
      final entries = field.text.split(',');
      if (entries.length > 20) throw const FormatException();
      return entries.map((e) {
        final pieces = e.trim().split(':');
        if (pieces.length != 2) throw const FormatException();
        final w = double.parse(pieces[0]), n = int.parse(pieces[1]);
        if (w <= 0 || !w.isFinite || w > 100 || n < 0 || n > 40) {
          throw const FormatException();
        }
        return <String, dynamic>{
          'weight': WorkoutService.storedWeight(w),
          'count': n
        };
      }).toList();
    }

    final accepted = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const WorkoutLabel('Plate inventory'),
                content: Form(
                    key: form,
                    child: TextFormField(
                        controller: field,
                        maxLines: 4,
                        decoration: InputDecoration(
                            labelText: (('Load:count, separated by commas'))
                                .workoutTr(context)),
                        validator: (_) {
                          try {
                            parse();
                            return null;
                          } catch (_) {
                            return (((('Enter positive loads and counts from 0 to 40')
                                .workoutTr(context))));
                          }
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
    if (accepted != true || !mounted) return;
    final inventory = parse();
    try {
      final prefs = await WorkoutService.put('/preferences', {
        ...WorkoutService.preferences,
        'plates': inventory,
        'barWeight': _kg(_bar)
      });
      WorkoutService.preferences = prefs;
      if (mounted) setState(() => _inventory = inventory);
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Widget _field(TextEditingController c, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: (label).workoutTr(context)),
          onChanged: (_) => setState(() {})));
  @override
  Widget build(BuildContext context) {
    final weight = _kg(_weight),
        bar = _kg(_bar),
        reps = int.tryParse(_reps.text) ?? 0;
    final valid = weight > 0 && weight <= 2000 && bar >= 0 && bar <= 100;
    final plates = calculatePlates(valid ? weight : 0, bar, _inventory);
    final oneRM = valid && reps >= 1 && reps <= 12
        ? weight * (reps == 1 ? 1 : 1 + reps / 30)
        : null;
    return WorkoutScaffold(
        appBar: AppBar(title: const WorkoutLabel('Training tools')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          _field(_weight, 'Weight (${WorkoutService.unit})'),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const WorkoutLabel('Plate calculator',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _field(_bar, 'Bar weight (${WorkoutService.unit})'),
                        if (valid && weight >= bar) ...[
                          WorkoutLabel(
                              'Achievable load: ${workoutValue(WorkoutService.displayWeight(plates.achieved))} ${WorkoutService.unit}'),
                          const SizedBox(height: 12),
                          const WorkoutLabel('Each side'),
                          Wrap(
                              spacing: 6,
                              children: plates.perSide
                                  .map((w) => Chip(
                                      label: WorkoutLabel(
                                          '${workoutValue(WorkoutService.displayWeight(w))} ${WorkoutService.unit}')))
                                  .toList()),
                          if ((plates.achieved - weight).abs() > 0.02)
                            const WorkoutLabel(
                                'Your inventory cannot make the exact load.')
                        ] else
                          const WorkoutLabel(
                              'Enter a target at least as heavy as the bar.'),
                        TextButton.icon(
                            onPressed: _inventoryDialog,
                            icon: const Icon(Icons.tune),
                            label: const WorkoutLabel('Plate inventory'))
                      ]))),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const WorkoutLabel('Estimated 1RM',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _field(_reps, 'Repetitions'),
                        if (oneRM != null)
                          WorkoutMetric(
                              '${workoutValue(WorkoutService.displayWeight(oneRM))} ${WorkoutService.unit}',
                              'Estimated 1RM'),
                        const WorkoutLabel(
                            'For loaded resistance exercises and 1–12 repetitions. This is an estimate.')
                      ]))),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const WorkoutLabel('Warm-up ramp',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600)),
                        ...workoutWarmups(valid ? weight : 0, bar: bar).map(
                            (v) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: WorkoutLabel(
                                    '${workoutValue(WorkoutService.displayWeight(v.$1))} ${WorkoutService.unit} × ${v.$2}'))),
                        const WorkoutLabel(
                            'Adjust warm-ups to your exercise and readiness.')
                      ])))
        ]));
  }
}
