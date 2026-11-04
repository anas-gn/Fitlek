import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/ENG/nutritionGoal.dart';
import '../services/nutrition_diary_service.dart';
import '../theme/fitlek_theme_extension.dart';

class NutritionGoalCard extends StatefulWidget {
  final int clientID;
  final String token;
  final NutritionDiaryService? service;
  const NutritionGoalCard(
      {super.key, required this.clientID, required this.token, this.service});
  @override
  State<NutritionGoalCard> createState() => _NutritionGoalCardState();
}

class _NutritionGoalCardState extends State<NutritionGoalCard> {
  late final NutritionDiaryService _service;
  StreamSubscription<int>? _updates;
  Map<String, dynamic>? _data;
  bool _loading = true, _failed = false;
  @override
  void initState() {
    super.initState();
    _service =
        widget.service ?? NutritionDiaryService(widget.clientID, widget.token);
    _load();
    _updates = NutritionDiaryService.changes.listen((id) {
      if (id == widget.clientID) _load();
    });
  }

  @override
  void dispose() {
    _updates?.cancel();
    if (widget.service == null) _service.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _service.goalPlan();
      if (mounted) {
        setState(() {
          _data = data;
          _failed = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _edit() async {
    final plan = (_data?['plan'] as Map?)?.cast<String, dynamic>() ??
        (_data?['defaults'] as Map?)?.cast<String, dynamic>();
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => NutritionGoalScreen(
                initial: plan == null
                    ? null
                    : {
                        ...plan,
                        'latestWeight': _data?['progress']?['currentWeight']
                      },
                service: _service)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fitlek, cs = Theme.of(context).colorScheme;
    final plan = (_data?['plan'] as Map?)?.cast<String, dynamic>(),
        progress = (_data?['progress'] as Map?)?.cast<String, dynamic>() ?? {};
    final status = plan?['status'];
    return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.flag_outlined, color: cs.primary),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('My nutrition goal',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            if (!_loading && !_failed)
              TextButton(
                  onPressed: _edit,
                  child: Text(plan == null ? 'Set goal' : 'Edit'))
          ]),
          if (_loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2))
          else if (_failed)
            TextButton(
                onPressed: _load,
                child: const Text('Could not load your goal · Retry'))
          else if (plan == null)
            Text(
                'Choose your goal and optional reminders. Start with balanced habits or set a personal weight goal.',
                style: TextStyle(color: c.textMuted, fontSize: 12, height: 1.5))
          else ...[
            const SizedBox(height: 10),
            Text(nutritionGoalLabels[plan['goalType']] ?? 'Your personal goal',
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(
                status == 'achieved'
                    ? 'Goal reached · Choose a new goal when ready'
                    : status == 'paused'
                        ? 'Paused · Resume whenever you like'
                        : plan['reminders']['enabled'] == true
                            ? 'Active · Reminders follow your preferences'
                            : 'Active · Reminders off',
                style: TextStyle(
                    color: status == 'achieved' ? c.success : c.textMuted,
                    fontSize: 12)),
            if (progress['targetWeight'] != null) ...[
              const SizedBox(height: 16),
              Text(
                  '${progress['currentWeight'] ?? '—'} kg → ${progress['targetWeight']} kg',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 9),
              LinearProgressIndicator(
                  value: ((progress['percent'] as num?)?.toDouble() ?? 0) / 100,
                  backgroundColor: c.border,
                  borderRadius: BorderRadius.circular(5)),
              const SizedBox(height: 7),
              Text(
                  (progress['measurements'] as num? ?? 0) == 0
                      ? 'Add a recent weigh-in to track your goal.'
                      : 'Based on your saved weigh-ins. Completion uses recent check-ins, not a promised date.',
                  style:
                      TextStyle(color: c.textMuted, fontSize: 10, height: 1.5)),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            NutritionReviewScreen(service: _service))),
                icon: const Icon(Icons.insights_outlined, size: 18),
                label: const Text('Monthly & yearly progress')),
          ],
        ]));
  }
}

class NutritionReviewScreen extends StatefulWidget {
  final NutritionDiaryService service;
  final bool ownsService, initialYearly;
  final DateTime? initialDate;
  const NutritionReviewScreen(
      {super.key,
      required this.service,
      this.ownsService = false,
      this.initialYearly = false,
      this.initialDate});
  @override
  State<NutritionReviewScreen> createState() => _NutritionReviewScreenState();
}

class _NutritionReviewScreenState extends State<NutritionReviewScreen> {
  bool _year = false, _loading = true;
  DateTime _date = DateTime.now();
  Map<String, dynamic>? _data;
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _year = widget.initialYearly;
    _date = widget.initialDate ?? DateTime.now();
    _load();
  }

  @override
  void dispose() {
    if (widget.ownsService) widget.service.close();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    final from =
            _year ? DateTime(_date.year) : DateTime(_date.year, _date.month),
        to = _year
            ? DateTime(_date.year + 1)
            : DateTime(_date.year, _date.month + 1);
    try {
      final data = await widget.service.review(from, to);
      if (mounted && request == _request) setState(() => _data = data);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'Could not load this review. Try again.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _shift(int amount) {
    setState(() => _date = _year
        ? DateTime(_date.year + amount)
        : DateTime(_date.year, _date.month + amount));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fitlek,
        averages = (_data?['dailyAverages'] as Map?) ?? {};
    final now = DateTime.now();
    return Scaffold(
        appBar: AppBar(title: const Text('Your progress review')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Monthly')),
                ButtonSegment(value: true, label: Text('Yearly'))
              ],
              selected: {
                _year
              },
              onSelectionChanged: (values) {
                setState(() => _year = values.single);
                _load();
              }),
          const SizedBox(height: 20),
          Row(children: [
            IconButton(
                tooltip: 'Previous period',
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left)),
            Expanded(
                child: Text(
                    _year
                        ? '${_date.year}'
                        : MaterialLocalizations.of(context)
                            .formatMonthYear(_date),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800))),
            IconButton(
                tooltip: 'Next period',
                onPressed: (_year
                        ? _date.year < now.year
                        : DateTime(_date.year, _date.month)
                            .isBefore(DateTime(now.year, now.month)))
                    ? () => _shift(1)
                    : null,
                icon: const Icon(Icons.chevron_right))
          ]),
          if (_loading)
            const LinearProgressIndicator()
          else if (_error != null)
            TextButton(onPressed: _load, child: Text(_error!))
          else if (_data != null) ...[
            const SizedBox(height: 24),
            Text('${_data!['loggedDays']} days logged',
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${_data!['meals']} saved meals',
                style: TextStyle(color: c.textMuted)),
            const SizedBox(height: 24),
            const Text('Daily averages',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'Only days with saved meals are included. Unlogged days are not treated as zero intake.',
                style:
                    TextStyle(color: c.textMuted, fontSize: 12, height: 1.5)),
            const SizedBox(height: 18),
            for (final key in nutritionKeys)
              Card(
                  child: ListTile(
                      title: Text(mealTypeLabel(key)),
                      trailing: Text(
                          (_data!['loggedDays'] as num? ?? 0) == 0
                              ? '—'
                              : '${((averages[key] as num?) ?? 0).toStringAsFixed(key == 'calories' ? 0 : 1)} ${key == 'calories' ? 'kcal' : 'g'}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)))),
            const SizedBox(height: 18),
            if ((_data!['weight'] as Map?)?['first'] != null)
              Card(
                  child: ListTile(
                      title: const Text('Weight check-ins'),
                      subtitle: Text(
                          '${_data!['weight']['checkIns']} check-ins in this period'),
                      trailing: Text(
                          '${_data!['weight']['first']} to ${_data!['weight']['latest']} kg',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)))),
            Text(
                'This is your logged history, not a complete measure of your intake. Small, consistent check-ins can help you understand your routine.',
                style:
                    TextStyle(color: c.textMuted, fontSize: 12, height: 1.5)),
          ],
        ]));
  }
}
