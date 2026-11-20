import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../screens/ENG/nutritionGoal.dart';
import '../services/nutrition_diary_service.dart';
import '../theme/fitlek_theme_extension.dart';

String _localizedNutritionKeyLabel(AppLocalizations l10n, String key) =>
    switch (key) {
      'calories' => l10n.mealShareCardCalories,
      'protein' => l10n.mealShareCardProtein,
      'carbs' => l10n.mealShareCardCarbs,
      'fat' => l10n.mealShareCardFat,
      _ => mealTypeLabel(key),
    };

String _localizedNutritionGoalLabel(AppLocalizations l10n, Object? goalType) =>
    switch (goalType) {
      'balanced' => l10n.nutritionGoalLabelBalanced,
      'lose' => l10n.nutritionGoalLabelLose,
      'gain' => l10n.nutritionGoalLabelGain,
      'maintain' => l10n.nutritionGoalLabelMaintain,
      _ => nutritionGoalLabels[goalType] ?? l10n.nutritionGoalCardPersonalGoal,
    };

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
    final l10n = AppLocalizations.of(context);
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
            Expanded(
                child: Text(l10n.nutritionGoalCardTitle,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800))),
            if (!_loading && !_failed)
              TextButton(
                  onPressed: _edit,
                  child: Text(plan == null
                      ? l10n.nutritionGoalCardSetGoal
                      : l10n.nutritionGoalCardEdit))
          ]),
          if (_loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2))
          else if (_failed)
            TextButton(
                onPressed: _load,
                child: Text(l10n.nutritionGoalCardLoadFailedRetry))
          else if (plan == null)
            Text(l10n.nutritionGoalCardEmptyPrompt,
                style: TextStyle(color: c.textMuted, fontSize: 12, height: 1.5))
          else ...[
            const SizedBox(height: 10),
            Text(_localizedNutritionGoalLabel(l10n, plan['goalType']),
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(
                status == 'achieved'
                    ? l10n.nutritionGoalCardStatusAchieved
                    : status == 'paused'
                        ? l10n.nutritionGoalCardStatusPaused
                        : plan['reminders']['enabled'] == true
                            ? l10n.nutritionGoalCardStatusActiveRemindersOn
                            : l10n.nutritionGoalCardStatusActiveRemindersOff,
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
                      ? l10n.nutritionGoalCardAddWeighInHint
                      : l10n.nutritionGoalCardBasedOnWeighIns,
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
                label: Text(l10n.nutritionGoalCardProgressButton)),
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
        setState(
            () => _error = AppLocalizations.of(context).nutritionReviewLoadError);
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
    final l10n = AppLocalizations.of(context);
    final c = context.fitlek,
        averages = (_data?['dailyAverages'] as Map?) ?? {};
    final now = DateTime.now();
    return Scaffold(
        appBar: AppBar(title: Text(l10n.nutritionReviewTitle)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false, label: Text(l10n.nutritionReviewMonthly)),
                ButtonSegment(
                    value: true, label: Text(l10n.nutritionReviewYearly))
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
                tooltip: l10n.nutritionReviewPreviousPeriod,
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
                tooltip: l10n.nutritionReviewNextPeriod,
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
            Text(
                l10n.nutritionReviewDaysLogged(
                    (_data!['loggedDays'] as num? ?? 0).toInt()),
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                l10n.nutritionReviewSavedMeals(
                    (_data!['meals'] as num? ?? 0).toInt()),
                style: TextStyle(color: c.textMuted)),
            const SizedBox(height: 24),
            Text(l10n.nutritionReviewDailyAveragesTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(l10n.nutritionReviewDailyAveragesSubtitle,
                style:
                    TextStyle(color: c.textMuted, fontSize: 12, height: 1.5)),
            const SizedBox(height: 18),
            for (final key in nutritionKeys)
              Card(
                  child: ListTile(
                      title: Text(_localizedNutritionKeyLabel(l10n, key)),
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
                      title: Text(l10n.nutritionReviewWeightCheckInsTitle),
                      subtitle: Text(l10n.nutritionReviewWeightCheckInsSubtitle(
                          (_data!['weight']['checkIns'] as num? ?? 0).toInt())),
                      trailing: Text(
                          l10n.nutritionReviewWeightRange(
                              '${_data!['weight']['first']}',
                              '${_data!['weight']['latest']}'),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)))),
            Text(l10n.nutritionReviewFooterDisclaimer,
                style:
                    TextStyle(color: c.textMuted, fontSize: 12, height: 1.5)),
          ],
        ]));
  }
}
