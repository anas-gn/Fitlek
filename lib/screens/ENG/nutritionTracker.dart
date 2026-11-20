import 'package:fitlek1/l10n/app_localizations.dart';
import 'nutritionGoal.dart';
import '../../components/nutrition_goal_card.dart';
import '../../components/meal_diary_actions.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/meal_visuals.dart';
import '../../services/meal_scan_service.dart';
import '../../services/nutrition_diary_service.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../components/meal_share_modal.dart';
import 'mealScanner.dart';

String _mealTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'breakfast':
      return l10n.mealScannerMealBreakfast;
    case 'lunch':
      return l10n.mealScannerMealLunch;
    case 'dinner':
      return l10n.mealScannerMealDinner;
    case 'snack':
      return l10n.mealScannerMealSnack;
    default:
      return mealTypeLabel(type);
  }
}

String _macroLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'calories':
      return l10n.nutritionGoalMacroCalories;
    case 'protein':
      return l10n.nutritionGoalMacroProtein;
    case 'carbs':
      return l10n.nutritionGoalMacroCarbs;
    case 'fat':
      return l10n.nutritionGoalMacroFat;
    default:
      return mealTypeLabel(key);
  }
}

class NutritionTrackerScreen extends StatefulWidget {
  final int clientID;
  final String token;
  final bool embedded;
  final NutritionDiaryService? service;
  final DateTime? initialDate;
  const NutritionTrackerScreen(
      {super.key,
      required this.clientID,
      required this.token,
      this.embedded = false,
      this.service,
      this.initialDate});
  @override
  State<NutritionTrackerScreen> createState() => _NutritionTrackerScreenState();
}

class _NutritionTrackerScreenState extends State<NutritionTrackerScreen>
    with AutomaticKeepAliveClientMixin {
  late final NutritionDiaryService _service;
  late DateTime _date;
  NutritionDay? _day;
  Map<String, double?> _goals = {};
  String? _error;
  bool _loading = false;
  int _request = 0;
  StreamSubscription<int>? _updates;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _date = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _service =
        widget.service ?? NutritionDiaryService(widget.clientID, widget.token);
    _load();
    _updates = NutritionDiaryService.changes.listen((id) {
      if (mounted && id == widget.clientID) _load();
    });
  }

  @override
  void dispose() {
    _updates?.cancel();
    if (widget.service == null) _service.close();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Future.wait([_service.day(_date), _service.goals()]);
      if (mounted && request == _request) {
        setState(() {
          _day = data[0] as NutritionDay;
          _goals = data[1] as Map<String, double?>;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error =
            AppLocalizations.of(context).nutritionTrackerSyncError);
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _select(DateTime date) {
    setState(() {
      _date = DateUtils.dateOnly(date);
      _day = null;
    });
    _load();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2000),
        lastDate: DateTime.now());
    if (value != null && mounted) _select(value);
  }

  String _label(DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);
  Future<void> _scan() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MealScannerScreen(
                clientID: widget.clientID,
                token: widget.token,
                diaryDate: _date)));
    if (mounted) await _load();
  }

  Future<void> _manual() async {
    final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => NutritionEntrySheet(date: _date, service: _service));
    if (saved == true && mounted) await _load();
  }

  Future<void> _targets() async {
    try {
      final data = await _service.goalPlan();
      if (!mounted) return;
      final initial =
          Map<String, dynamic>.from(data['plan'] ?? data['defaults'] ?? {})
            ..putIfAbsent('targets', () => _goals)
            ..['latestWeight'] = data['progress']?['currentWeight'];
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  NutritionGoalScreen(initial: initial, service: _service)));
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).nutritionTrackerGoalLoadError)));
      }
    }
  }

  Future<void> _open(ScannedMeal meal) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MealResultScreen(
                meal: meal,
                clientID: widget.clientID,
                token: widget.token,
                initiallySaved: true,
                service: _service)));
    if (mounted) await _load();
  }

  Future<void> _delete(ScannedMeal meal) async {
    final confirmed = await confirmMealDeletion(context, meal.name);
    if (confirmed != true) return;
    try {
      await _service.delete(meal);
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).nutritionTrackerMealRemoveError)));
      }
    }
  }

  Widget _card(Widget child) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: context.fitlek.card,
          border: Border.all(color: context.fitlek.border),
          borderRadius: BorderRadius.circular(24)),
      child: child);
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.fitlek, scheme = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final calories = _day?.total('calories') ?? 0;
    final goal = _goals['calories'];
    final showData = _day != null;
    final body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              Text(AppLocalizations.of(context).nutritionTrackerDailyDiary,
                  style: TextStyle(
                      color: c.textMuted,
                      letterSpacing: 2,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Row(children: [
                Expanded(
                    child: Text(AppLocalizations.of(context).nutritionTrackerFuelDay,
                        style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1))),
                IconButton(
                    tooltip: AppLocalizations.of(context).nutritionTrackerDailyTargetsTooltip,
                    onPressed: _targets,
                    icon: const Icon(Icons.tune_rounded))
              ]),
              const SizedBox(height: 16),
              Row(children: [
                IconButton(
                    tooltip: AppLocalizations.of(context).nutritionTrackerPrevDayTooltip,
                    onPressed: () =>
                        _select(_date.subtract(const Duration(days: 1))),
                    icon: const Icon(Icons.chevron_left_rounded)),
                Expanded(
                    child: TextButton.icon(
                        onPressed: _pickDate,
                        icon:
                            const Icon(Icons.calendar_today_outlined, size: 17),
                        label: Text(
                            DateUtils.isSameDay(_date, today)
                                ? '${AppLocalizations.of(context).nutritionTrackerToday} · ${_label(_date)}'
                                : _label(_date),
                            textAlign: TextAlign.center))),
                IconButton(
                    tooltip: AppLocalizations.of(context).nutritionTrackerNextDayTooltip,
                    onPressed: _date.isBefore(today)
                        ? () => _select(_date.add(const Duration(days: 1)))
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded))
              ]),
              if (!DateUtils.isSameDay(_date, today))
                Align(
                    alignment: Alignment.center,
                    child: TextButton(
                        onPressed: () => _select(today),
                        child: Text(AppLocalizations.of(context).nutritionTrackerBackToToday))),
              const SizedBox(height: 14),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _card(Column(children: [
                      Text(_error!, textAlign: TextAlign.center),
                      TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context).nutritionTrackerRetrySync))
                    ]))),
              if (showData) ...[
                _card(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(AppLocalizations.of(context).nutritionTrackerEnergyLogged,
                                  style: TextStyle(
                                      color: c.textMuted,
                                      fontSize: 10,
                                      letterSpacing: 1.8,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('${calories.round()}',
                                            key: const ValueKey(
                                                'daily-calories'),
                                            style: TextStyle(
                                                color: scheme.onSurface,
                                                fontSize: 50,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -2)),
                                        const SizedBox(width: 6),
                                        Text('kcal',
                                            style:
                                                TextStyle(color: c.textMuted))
                                      ])),
                              Text(AppLocalizations.of(context).nutritionTrackerMealsLogged(_day!.meals.length),
                                  style: TextStyle(
                                      color: c.textMuted, fontSize: 12))
                            ])),
                        const SizedBox(width: 12),
                        SizedBox(
                            width: 76,
                            height: 76,
                            child:
                                Stack(alignment: Alignment.center, children: [
                              SizedBox.expand(
                                  child: CircularProgressIndicator(
                                      value: goal != null && goal > 0
                                          ? (calories / goal).clamp(0, 1)
                                          : 0,
                                      strokeWidth: 7,
                                      backgroundColor: c.border,
                                      color: scheme.primary)),
                              Icon(Icons.local_fire_department_outlined,
                                  color: scheme.primary, size: 30)
                            ]))
                      ]),
                      const SizedBox(height: 16),
                      if (goal != null && goal > 0)
                        Text(
                            '${AppLocalizations.of(context).nutritionTrackerTargetSummary(goal.round())} · ${calories <= goal ? AppLocalizations.of(context).nutritionTrackerRemaining((goal - calories).round()) : AppLocalizations.of(context).nutritionTrackerAboveTarget((calories - goal).round())}',
                            style: TextStyle(color: c.textMuted, fontSize: 12))
                      else
                        TextButton(
                            onPressed: _targets,
                            child: Text(AppLocalizations.of(context).nutritionTrackerSetDailyTargets)),
                    ])),
                const SizedBox(height: 12),
                Row(children: [
                  for (final item in [
                    (AppLocalizations.of(context).nutritionGoalMacroProtein, 'protein', mealProtein),
                    (AppLocalizations.of(context).nutritionGoalMacroCarbs, 'carbs', mealCarbs),
                    (AppLocalizations.of(context).nutritionGoalMacroFat, 'fat', mealFat)
                  ])
                    Expanded(
                        child: Padding(
                            padding: EdgeInsets.only(
                                right: item.$2 == 'fat' ? 0 : 8),
                            child: _macro(item.$1, item.$2, item.$3)))
                ]),
              ],
              const SizedBox(height: 20),
              NutritionGoalCard(
                  clientID: widget.clientID,
                  token: widget.token,
                  service: _service),
              Row(children: [
                Expanded(
                    child: FilledButton.icon(
                        onPressed: _scan,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: Text(AppLocalizations.of(context).nutritionTrackerScanMeal))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _manual,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(AppLocalizations.of(context).nutritionTrackerAddManually)))
              ]),
              const SizedBox(height: 24),
              if (showData) ...[
                Text(AppLocalizations.of(context).nutritionTrackerMealsMoments,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 21,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                for (final type in mealTypes)
                  Padding(
                       padding: const EdgeInsets.only(bottom: 12),
                      child: _mealGroup(type)),
              ],
              const SizedBox(height: 6),
              Text(
                  AppLocalizations.of(context).nutritionTrackerEstimatesNotice,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: c.textMuted, fontSize: 11, height: 1.6)),
            ]));
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).nutritionTrackerDiaryTitle)), body: body);
  }

  Widget _macro(String title, String key, Color color) {
    final value = _day!.total(key), goal = _goals[key];
    final c = context.fitlek;
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: c.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('${value.toStringAsFixed(1)} g',
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? color
                          : Theme.of(context).colorScheme.primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: goal != null && goal > 0 ? (value / goal).clamp(0, 1) : 0,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: c.border,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 6),
          Text(
              goal != null && goal > 0
                  ? AppLocalizations.of(context).nutritionTrackerOfGrams(goal.round())
                  : AppLocalizations.of(context).nutritionTrackerNoTargetSet,
              style: TextStyle(color: c.textMuted, fontSize: 9))
        ]));
  }

  Widget _mealGroup(String type) {
    final meals = _day!.meals.where((meal) => meal.mealType == type).toList();
    final c = context.fitlek;
    return _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(
            switch (type) {
              'breakfast' => Icons.wb_twilight_rounded,
              'lunch' => Icons.wb_sunny_outlined,
              'dinner' => Icons.nights_stay_outlined,
              _ => Icons.apple_outlined
            },
            size: 19,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
            child: Text(_mealTypeLabel(AppLocalizations.of(context), type),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800))),
        Text(
            '${meals.fold<double>(0, (sum, meal) => sum + meal.total('calories')).round()} kcal',
            style: TextStyle(color: c.textMuted, fontSize: 12))
      ]),
      if (meals.isEmpty)
        Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(AppLocalizations.of(context).nutritionTrackerNothingLogged,
                style: TextStyle(color: c.textMuted, fontSize: 12))),
      for (final meal in meals)
        Padding(
            padding: const EdgeInsets.only(top: 14),
            child: InkWell(
                onTap: () => _open(meal),
                borderRadius: BorderRadius.circular(12),
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                          width: 52,
                          height: 58,
                          child: MealPhoto(
                              path: meal.photoPath, bytes: meal.photoBytes))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(meal.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(
                            '${meal.total('calories').round()} kcal · P ${meal.total('protein').toStringAsFixed(1)} g\nC ${meal.total('carbs').toStringAsFixed(1)} g · F ${meal.total('fat').toStringAsFixed(1)} g',
                            style: TextStyle(
                                color: c.textMuted, fontSize: 10, height: 1.6))
                      ])),
                  IconButton(
                      tooltip: AppLocalizations.of(context).nutritionTrackerShareMealTooltip(meal.name),
                      onPressed: () => showMealShareModal(context, meal),
                      icon: Icon(Icons.share_outlined,
                          size: 19, color: c.textMuted)),
                  IconButton(
                      tooltip: AppLocalizations.of(context).nutritionTrackerRemoveMealTooltip(meal.name),
                      onPressed: () => _delete(meal),
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 20, color: c.textMuted))
                ]))),
    ]));
  }
}

class NutritionEntrySheet extends StatefulWidget {
  final DateTime date;
  final NutritionDiaryService service;
  const NutritionEntrySheet(
      {super.key, required this.date, required this.service});
  @override
  State<NutritionEntrySheet> createState() => _NutritionEntrySheetState();
}

class _NutritionEntrySheetState extends State<NutritionEntrySheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _values = {
    for (final key in nutritionKeys) key: TextEditingController()
  };
  final _id = 'manual_${DateTime.now().microsecondsSinceEpoch}';
  String _type = 'lunch';
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    final category = await chooseMealCategory(context, initialType: _type);
    if (!mounted) return;
    if (category == null) {
      setState(() => _saving = false);
      return;
    }
    _type = category;
    final values = _values.map((key, value) =>
        MapEntry(key, double.parse(value.text.replaceAll(',', '.'))));
    final l10n = AppLocalizations.of(context);
    final meal = ScannedMeal(
        id: _id,
        name: _name.text.trim(),
        notes: l10n.nutritionTrackerManualNotes,
        confidence: 'manual',
        createdAt: DateTime.now(),
        mealDate: ScannedMeal.dayKey(widget.date),
        mealType: _type,
        portion: 1,
        photoPath: '',
        ingredients: [
          MealIngredient(
              name: _name.text.trim(),
              grams: 0,
              quantity: l10n.nutritionTrackerOneServing,
              calories: values['calories']!,
              protein: values['protein']!,
              carbs: values['carbs']!,
              fat: values['fat']!)
        ]);
    try {
      await widget.service.save(meal);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              l10n.nutritionTrackerSyncMealError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _sheet(
      context,
      Form(
          key: _form,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nutritionTrackerAddMealTitle,
                    style:
                        const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(l10n.nutritionTrackerAddMealSubtitle),
                const SizedBox(height: 20),
                TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    maxLength: 120,
                    decoration: InputDecoration(labelText: l10n.nutritionTrackerMealNameLabel),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.nutritionTrackerEnterMealName
                        : null),
                const SizedBox(height: 12),
                Text(
                    l10n.nutritionTrackerChooseMealTypeNotice,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                for (final key in nutritionKeys)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                          key: ValueKey('manual-$key'),
                          controller: _values[key],
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: '${_macroLabel(l10n, key)} (${key == 'calories' ? 'kcal' : 'g'})'),
                          validator: (value) => _validNumber(value,
                                  max: key == 'calories' ? 50000 : 10000)
                              ? null
                              : l10n.nutritionTrackerEnterValidNumber)),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: TextStyle(color: context.fitlek.error))),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? l10n.nutritionTrackerSaving : l10n.nutritionTrackerSaveMeal)))
              ])));
  }
}

bool _validNumber(String? value, {required double max}) {
  final number = double.tryParse((value ?? '').replaceAll(',', '.'));
  return number != null && number.isFinite && number >= 0 && number <= max;
}

Widget _sheet(BuildContext context, Widget child) => SafeArea(
    child: Padding(
        padding: EdgeInsets.fromLTRB(
            22, 24, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: SingleChildScrollView(child: child)));

class NutritionGoalsSheet extends StatefulWidget {
  final Map<String, double?> goals;
  final NutritionDiaryService service;
  const NutritionGoalsSheet(
      {super.key, required this.goals, required this.service});
  @override
  State<NutritionGoalsSheet> createState() => _NutritionGoalsSheetState();
}

class _NutritionGoalsSheetState extends State<NutritionGoalsSheet> {
  final _form = GlobalKey<FormState>();
  late final _values = {
    for (final key in nutritionKeys)
      key: TextEditingController(text: widget.goals[key]?.toString() ?? '')
  };
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.saveGoals(_values.map((key, value) => MapEntry(
          key,
          value.text.trim().isEmpty
              ? null
              : double.parse(value.text.replaceAll(',', '.')))));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppLocalizations.of(context).nutritionTrackerSaveTargetsError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _sheet(
      context,
      Form(
          key: _form,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nutritionTrackerDailyTargetsTitle,
                    style:
                        const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(l10n.nutritionTrackerSetTargetsSubtitle),
                const SizedBox(height: 22),
                for (final key in nutritionKeys)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                          controller: _values[key],
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: '${_macroLabel(l10n, key)} (${key == 'calories' ? 'kcal' : 'g'})'),
                          validator: (value) => value == null ||
                                  value.trim().isEmpty ||
                                  _validNumber(value,
                                      max: key == 'calories' ? 20000 : 2000)
                              ? null
                              : l10n.nutritionTrackerEnterValidDailyTarget)),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: context.fitlek.error)),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? l10n.nutritionTrackerSaving : l10n.nutritionTrackerSaveTargets)))
              ])));
  }
}
