import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../../services/nutrition_diary_service.dart';
import '../../theme/fitlek_theme_extension.dart';

const nutritionGoalLabels = {
  'balanced': 'Build balanced habits',
  'lose': 'Lose weight gradually',
  'gain': 'Gain weight gradually',
  'maintain': 'Maintain my weight'
};

String _localizedGoalLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'balanced':
      return l10n.nutritionGoalTypeBalanced;
    case 'lose':
      return l10n.nutritionGoalTypeLose;
    case 'gain':
      return l10n.nutritionGoalTypeGain;
    case 'maintain':
      return l10n.nutritionGoalTypeMaintain;
    default:
      return nutritionGoalLabels[key] ?? key;
  }
}

String _localizedMacroLabel(AppLocalizations l10n, String key) {
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
const _zones = [
  'Africa/Casablanca',
  'Europe/Paris',
  'Europe/London',
  'Europe/Madrid',
  'Europe/Berlin',
  'America/Toronto',
  'America/New_York',
  'America/Los_Angeles',
  'Asia/Dubai',
  'Asia/Riyadh',
  'Asia/Tokyo',
  'Australia/Sydney',
  'UTC'
];

double? maintenanceCalories(
    {required double? age,
    required double? height,
    required double? weight,
    required String? sex,
    required String activity,
    required bool eligible}) {
  if (!eligible ||
      age == null ||
      age < 18 ||
      age > 80 ||
      height == null ||
      weight == null ||
      !['male', 'female'].contains(sex)) {
    return null;
  }
  final resting =
      10 * weight + 6.25 * height - 5 * age + (sex == 'male' ? 5 : -161);
  final estimate = resting *
      ({
            'low': 1.2,
            'light': 1.375,
            'moderate': 1.55,
            'high': 1.725
          }[activity] ??
          1.375);
  return estimate >= 1500 && estimate <= 4500
      ? (estimate / 50).round() * 50.0
      : null;
}

class RecommendedTargets {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double tdee;
  final double bmr;
  final double diff;
  final String note;

  const RecommendedTargets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.tdee,
    required this.bmr,
    required this.diff,
    required this.note,
  });
}

RecommendedTargets? calculateRecommendedTargets({
  required double? age,
  required double? height,
  required double? weight,
  required String? sex,
  required String activity,
  required String goalType,
  String macroSplit = 'balanced',
}) {
  if (age == null ||
      age < 15 ||
      age > 95 ||
      height == null ||
      height < 100 ||
      height > 260 ||
      weight == null ||
      weight < 30 ||
      weight > 350) {
    return null;
  }

  final isMale = sex?.toLowerCase() == 'male';
  final sexOffset = isMale ? 5.0 : -161.0;
  final bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) + sexOffset;

  final activityMultiplier = const {
    'low': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'high': 1.725,
  }[activity] ?? 1.375;

  final tdee = bmr * activityMultiplier;

  double targetCalories = tdee;
  double diff = 0.0;
  String note;

  if (goalType == 'lose') {
    diff = -400.0;
    targetCalories = tdee - 400.0;
    final floor = isMale ? 1500.0 : 1200.0;
    if (targetCalories < floor) {
      targetCalories = floor;
      diff = targetCalories - tdee;
    }
    note = 'Healthy deficit (~400 kcal) for steady, sustainable fat loss (~0.4 kg/week).';
  } else if (goalType == 'gain') {
    diff = 350.0;
    targetCalories = tdee + 350.0;
    note = 'Controlled surplus (+350 kcal) to support clean muscle hypertrophy with minimal fat gain.';
  } else {
    diff = 0.0;
    targetCalories = tdee;
    note = 'Maintenance energy to stabilize body weight and build consistent healthy habits.';
  }

  targetCalories = (targetCalories / 25).round() * 25.0;

  double pGrams;
  double fGrams;
  double cGrams;

  switch (macroSplit) {
    case 'high_protein':
      pGrams = (targetCalories * 0.35) / 4.0;
      fGrams = (targetCalories * 0.25) / 9.0;
      cGrams = (targetCalories * 0.40) / 4.0;
      break;

    case 'low_carb':
      pGrams = (targetCalories * 0.30) / 4.0;
      fGrams = (targetCalories * 0.50) / 9.0;
      cGrams = (targetCalories * 0.20) / 4.0;
      break;

    case 'balanced':
    default:
      final pPerKg = (goalType == 'lose' || goalType == 'gain') ? 1.7 : 1.4;
      pGrams = weight * pPerKg;
      final minP = (targetCalories * 0.20) / 4.0;
      final maxP = (targetCalories * 0.32) / 4.0;
      if (pGrams < minP) pGrams = minP;
      if (pGrams > maxP) pGrams = maxP;

      fGrams = (targetCalories * 0.28) / 9.0;
      final rem = targetCalories - (pGrams * 4.0) - (fGrams * 9.0);
      cGrams = (rem > 0 ? rem : 0) / 4.0;
      break;
  }

  return RecommendedTargets(
    calories: targetCalories,
    protein: pGrams.roundToDouble(),
    carbs: cGrams.roundToDouble(),
    fat: fGrams.roundToDouble(),
    tdee: (tdee / 25).round() * 25.0,
    bmr: bmr.roundToDouble(),
    diff: diff,
    note: note,
  );
}

class NutritionGoalScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final NutritionDiaryService? service;
  final bool signup;
  const NutritionGoalScreen(
      {super.key, this.initial, this.service, this.signup = false});
  @override
  State<NutritionGoalScreen> createState() => _NutritionGoalScreenState();
}

class _NutritionGoalScreenState extends State<NutritionGoalScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late String _type, _activity, _zone, _diet, _status;
  String? _sex;
  String _macroSplit = 'balanced';
  bool _eligible = false,
      _enabled = false,
      _calorieAlerts = true,
      _monthly = true,
      _yearly = true,
      _weekly = true,
      _ideas = false,
      _saving = false;
  bool _restart = false;
  late Map<String, int> _times;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.initial ?? {};
    final targets = Map<String, dynamic>.from(p['targets'] ?? {}),
        reminders = Map<String, dynamic>.from(p['reminders'] ?? {});
    _fields = {
      for (final key in [
        'age',
        'height',
        'currentWeight',
        'targetWeight',
        ...nutritionKeys
      ])
        key: TextEditingController(
            text:
                '${nutritionKeys.contains(key) ? targets[key] ?? '' : p[key] ?? ''}')
    };
    _type = p['goalType'] ?? 'balanced';
    _activity = p['activity'] ?? 'light';
    _zone = p['timeZone'] ?? 'Africa/Casablanca';
    _diet = p['diet'] ?? 'balanced';
    _status = p['status'] ?? 'active';
    _sex = p['formulaSex'];
    _macroSplit = p['macroSplit'] ?? 'balanced';
    _eligible = p['estimateEligible'] == true;
    _enabled = reminders['enabled'] == true;
    _calorieAlerts = reminders['calorieAlerts'] != false;
    _monthly = reminders['monthly'] != false;
    _yearly = reminders['yearly'] != false;
    _weekly = reminders['weekly'] != false;
    _ideas = reminders['mealIdeas'] == true;
    _times = {
      for (final item in {
        'breakfast': 540,
        'lunch': 840,
        'dinner': 1200,
        'quietStart': 1320,
        'quietEnd': 480
      }.entries)
        item.key: (reminders[item.key] as num?)?.toInt() ?? item.value
    };
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _value(String key) =>
      double.tryParse(_fields[key]!.text.replaceAll(',', '.'));
  bool get _adult => (_value('age') ?? 0) >= 18;
  bool get _minor => _value('age') != null && _value('age')! < 18;
  bool get _weightGoal => ['lose', 'gain'].contains(_type);
  Map<String, dynamic> _data() => {
        'goalType': _type,
        'age': _value('age'),
        'height': _minor ? null : _value('height'),
        'currentWeight': _minor ? null : _value('currentWeight'),
        'targetWeight': _weightGoal ? _value('targetWeight') : null,
        'activity': _activity,
        'formulaSex': _sex,
        'macroSplit': _macroSplit,
        'estimateEligible': _eligible,
        'diet': _diet,
        'timeZone': _zone,
        'status': _status,
        'restart': _restart,
        'targets': {
          for (final key in nutritionKeys) key: _minor ? null : _value(key)
        },
        'reminders': {
          'enabled': _enabled,
          'calorieAlerts': _adult && _calorieAlerts,
          'monthly': _monthly,
          'yearly': _yearly,
          'weekly': _weekly,
          'mealIdeas': _adult && _ideas,
          ..._times
        },
      };
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    if (_weightGoal && !_adult) {
      setState(() => _error = l10n.nutritionGoalAdultWeightError);
      return;
    }
    final current = _value('currentWeight'),
        target = _value('targetWeight'),
        height = _value('height');
    if (_weightGoal &&
        ((target! / (height! / 100) / (height / 100)) < 18.5 ||
            (_type == 'lose' ? target >= current! : target <= current!))) {
      setState(() => _error = l10n.nutritionGoalTargetDirectionError);
      return;
    }
    final data = _data();
    setState(() {
      _saving = true;
      _error = null;
    });
    if (widget.signup) {
      Navigator.pop(context, data);
      return;
    }
    try {
      await widget.service!.savePlan(data);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _time(String key) async {
    final value = _times[key]!;
    final selected = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60));
    if (selected != null && mounted) {
      setState(() => _times[key] = selected.hour * 60 + selected.minute);
    }
  }

  Widget _number(String key, String label,
          {bool required = false, double min = 0, double max = 500}) {
    final l10n = AppLocalizations.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          key: ValueKey('goal-$key'),
          controller: _fields[key],
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
          validator: (raw) {
            if (raw == null || raw.trim().isEmpty) {
              return required ? l10n.nutritionGoalFieldRequired(label) : null;
            }
            final value = double.tryParse(raw.replaceAll(',', '.'));
            return value == null ||
                    !value.isFinite ||
                    value < min ||
                    value > max ||
                    (key == 'age' && value != value.roundToDouble())
                ? l10n.nutritionGoalFieldInvalid(label)
                : null;
          },
        ));
  }
  Widget _section(String title, String subtitle, List<Widget> children) =>
      Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: context.fitlek.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: context.fitlek.border)),
          child: Material(
              color: Colors.transparent,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: TextStyle(
                            color: context.fitlek.textMuted,
                            fontSize: 12,
                            height: 1.5)),
                    const SizedBox(height: 18),
                    ...children
                  ])));
  Widget _switch(String title, bool value, ValueChanged<bool> change,
          {String? subtitle}) =>
      SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle, style: const TextStyle(fontSize: 11)),
          value: value,
          onChanged: _saving ? null : change);

  Widget _macroStatBadge(
    BuildContext context,
    String label,
    String value,
    String unit,
    String caption, {
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  unit,
                  style: TextStyle(
                      fontSize: 9,
                      color: color.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            caption,
            style: TextStyle(fontSize: 9, color: context.fitlek.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _localizedRecommendedNote(AppLocalizations l10n) {
    switch (_type) {
      case 'lose':
        return l10n.nutritionGoalNoteLose;
      case 'gain':
        return l10n.nutritionGoalNoteGain;
      default:
        return l10n.nutritionGoalNoteMaintain;
    }
  }

  Widget _buildSmartTargetsCard(
      BuildContext context, RecommendedTargets? rec) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    if (rec == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.fitlek.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.fitlek.border),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.nutritionGoalCompleteProfilePrompt,
                style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final styleOptions = [
      ('balanced', l10n.nutritionGoalStyleBalanced),
      ('high_protein', l10n.nutritionGoalStyleHighProtein),
      ('low_carb', l10n.nutritionGoalStyleLowCarb),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nutritionGoalRecommendedTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _localizedRecommendedNote(l10n),
                      style: TextStyle(
                        color: context.fitlek.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Macro Grid
          Row(
            children: [
              Expanded(
                child: _macroStatBadge(
                  context,
                  l10n.nutritionGoalMacroCalories,
                  '${rec.calories.round()}',
                  l10n.nutritionGoalUnitKcalPerDay,
                  rec.diff < 0
                      ? l10n.nutritionGoalDeficitBadge(rec.diff.round())
                      : rec.diff > 0
                          ? l10n.nutritionGoalSurplusBadge(rec.diff.round())
                          : l10n.nutritionGoalMaintenanceBadge,
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _macroStatBadge(
                  context,
                  l10n.nutritionGoalMacroProtein,
                  '${rec.protein.round()}g',
                  '${((rec.protein * 4 / rec.calories) * 100).round()}%',
                  l10n.nutritionGoalCaptionMuscleRecovery,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _macroStatBadge(
                  context,
                  l10n.nutritionGoalMacroCarbs,
                  '${rec.carbs.round()}g',
                  '${((rec.carbs * 4 / rec.calories) * 100).round()}%',
                  l10n.nutritionGoalCaptionDailyEnergy,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _macroStatBadge(
                  context,
                  l10n.nutritionGoalMacroFat,
                  '${rec.fat.round()}g',
                  '${((rec.fat * 9 / rec.calories) * 100).round()}%',
                  l10n.nutritionGoalCaptionHormoneHealth,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dietary Style selector
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                l10n.nutritionGoalDietaryStyleLabel,
                style: TextStyle(
                  color: context.fitlek.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ...styleOptions.map((opt) {
                final isSelected = _macroSplit == opt.$1;
                return ChoiceChip(
                  label: Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.black87 : null,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onSelected: (val) {
                    if (val) setState(() => _macroSplit = opt.$1);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 14),

          // 1-Tap Apply Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              key: const ValueKey('apply-recommended-targets-btn'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: Text(
                l10n.nutritionGoalApplyRecommendedBtn,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              onPressed: () {
                setState(() {
                  _fields['calories']!.text =
                      rec.calories.round().toString();
                  _fields['protein']!.text = rec.protein.round().toString();
                  _fields['carbs']!.text = rec.carbs.round().toString();
                  _fields['fat']!.text = rec.fat.round().toString();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: context.fitlek.card,
                    content: Text(
                      l10n.nutritionGoalAppliedToast(
                          rec.calories.round(),
                          rec.protein.round(),
                          rec.carbs.round(),
                          rec.fat.round()),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final estimate = maintenanceCalories(
        age: _value('age'),
        height: _value('height'),
        weight: (_restart || widget.signup)
            ? _value('currentWeight')
            : (widget.initial?['latestWeight'] as num?)?.toDouble() ??
                _value('currentWeight'),
        sex: _sex,
        activity: _activity,
        eligible: _eligible);
    final recommended = calculateRecommendedTargets(
        age: _value('age'),
        height: _value('height'),
        weight: (_restart || widget.signup)
            ? _value('currentWeight')
            : (widget.initial?['latestWeight'] as num?)?.toDouble() ??
                _value('currentWeight'),
        sex: _sex,
        activity: _activity,
        goalType: _type,
        macroSplit: _macroSplit);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.signup
                ? l10n.nutritionGoalTitleSignup
                : l10n.nutritionGoalTitle),
            actions: [
              if (widget.signup)
                TextButton(
                  key: const ValueKey('skip-goal-signup-btn'),
                  onPressed: () =>
                      Navigator.pop(context, const {'skipped': true}),
                  child: Text(l10n.nutritionGoalSkipForNow,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ]),
        body: Form(
            key: _form,
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.nutritionGoalHeaderTitle,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 8),
                      Text(l10n.nutritionGoalHeaderSubtitle,
                          style: TextStyle(
                              color: context.fitlek.textMuted, height: 1.5)),
                      const SizedBox(height: 22),
                      _section(
                          l10n.nutritionGoalSectionWhatMattersTitle,
                          l10n.nutritionGoalSectionWhatMattersSub,
                          [
                            DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _type,
                                decoration: InputDecoration(
                                    labelText: l10n.nutritionGoalMyGoalLabel),
                                items: [
                                  for (final entry
                                      in nutritionGoalLabels.entries)
                                    DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(
                                            _localizedGoalLabel(
                                                l10n, entry.key),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 13)))
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() {
                                          _type = value!;
                                          if (_status == 'achieved') {
                                            _status = 'active';
                                          }
                                        })),
                            const SizedBox(height: 18),
                            _number('age', l10n.nutritionGoalAgeLabel,
                                required: _weightGoal, min: 13, max: 100),
                            if (!_minor)
                              _number('height', l10n.nutritionGoalHeightLabel,
                                  required: _weightGoal, min: 1, max: 300),
                            if (!_minor)
                              _number('currentWeight',
                                  l10n.nutritionGoalStartingWeightLabel,
                                  required: _weightGoal, min: 1, max: 500),
                            if (_weightGoal)
                              _number('targetWeight',
                                  l10n.nutritionGoalTargetWeightLabel,
                                  required: true, min: 25, max: 500),
                            if (!_minor)
                              DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _sex,
                                  decoration: InputDecoration(
                                      labelText: l10n
                                          .nutritionGoalBiologicalSexLabel),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'male',
                                        child: Text(l10n.nutritionGoalSexMale)),
                                    DropdownMenuItem(
                                        value: 'female',
                                        child:
                                            Text(l10n.nutritionGoalSexFemale))
                                  ],
                                  onChanged: _saving
                                      ? null
                                      : (value) =>
                                          setState(() => _sex = value)),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _activity,
                                decoration: InputDecoration(
                                    labelText:
                                        l10n.nutritionGoalUsualActivityLabel),
                                items: [
                                  for (final entry in {
                                    'low': l10n.nutritionGoalActivityLow,
                                    'light': l10n.nutritionGoalActivityLight,
                                    'moderate':
                                        l10n.nutritionGoalActivityModerate,
                                    'high': l10n.nutritionGoalActivityHigh
                                  }.entries)
                                    DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis))
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) =>
                                        setState(() => _activity = value!)),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _diet,
                                decoration: InputDecoration(
                                    labelText:
                                        l10n.nutritionGoalFoodPreferenceLabel),
                                items: [
                                  for (final entry in {
                                    'balanced': l10n.nutritionGoalDietBalanced,
                                    'vegetarian':
                                        l10n.nutritionGoalDietVegetarian,
                                    'vegan': l10n.nutritionGoalDietVegan,
                                    'halal': l10n.nutritionGoalDietHalal
                                  }.entries)
                                    DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis))
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) =>
                                        setState(() => _diet = value!)),
                          ]),
                      if (!_minor)
                        _section(
                            l10n.nutritionGoalSectionDailyTargetsTitle,
                            l10n.nutritionGoalSectionDailyTargetsSub,
                            [
                              _buildSmartTargetsCard(context, recommended),
                              const SizedBox(height: 8),
                              for (final key in nutritionKeys)
                                _number(key,
                                    '${_localizedMacroLabel(l10n, key)} (${key == 'calories' ? 'kcal' : 'g'})',
                                    max: key == 'calories' ? 20000 : 2000),
                              ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                      l10n.nutritionGoalEstimateMaintenanceTitle,
                                      style: const TextStyle(fontSize: 14)),
                                  children: [
                                    Text(
                                        l10n.nutritionGoalEstimateMaintenanceSub,
                                        style: const TextStyle(
                                            fontSize: 12, height: 1.5)),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _sex,
                                        decoration: InputDecoration(
                                            labelText: l10n
                                                .nutritionGoalSexEstimateLabel),
                                        items: [
                                          DropdownMenuItem(
                                              value: 'male',
                                              child: Text(
                                                  l10n.nutritionGoalSexMale)),
                                          DropdownMenuItem(
                                              value: 'female',
                                              child: Text(
                                                  l10n.nutritionGoalSexFemale))
                                        ],
                                        onChanged: _saving
                                            ? null
                                            : (value) =>
                                                setState(() => _sex = value)),
                                    _switch(
                                        l10n.nutritionGoalGeneralEstimatesSuitable,
                                        _eligible,
                                        (value) =>
                                            setState(() => _eligible = value),
                                        subtitle: l10n
                                            .nutritionGoalGeneralEstimatesSub),
                                    if (estimate != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Column(children: [
                                            Text(
                                                l10n.nutritionGoalAboutMaintenanceKcal(
                                                    estimate.round()),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            const SizedBox(height: 8),
                                            if (!_weightGoal)
                                              OutlinedButton(
                                                  onPressed: () => setState(
                                                      () => _fields['calories']!
                                                              .text =
                                                          estimate
                                                              .toStringAsFixed(
                                                                  0)),
                                                  child: Text(l10n
                                                      .nutritionGoalUseMaintenanceBtn))
                                          ]))
                                    else
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Text(
                                              l10n.nutritionGoalEstimatePrompt,
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                    TextButton(
                                        onPressed: () => launchUrl(Uri.parse(
                                            'https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner')),
                                        child: Text(l10n
                                            .nutritionGoalAboutCaloriePlanning)),
                                  ]),
                            ]),
                      if (_minor)
                        _section(
                            l10n.nutritionGoalMinorSectionTitle,
                            l10n.nutritionGoalMinorSectionSub,
                            []),
                      _section(
                          l10n.nutritionGoalSectionSupportTitle,
                          l10n.nutritionGoalSectionSupportSub,
                          [
                            _switch(l10n.nutritionGoalRemindersTitle, _enabled,
                                (value) => setState(() => _enabled = value),
                                subtitle: l10n.nutritionGoalRemindersSub),
                            if (_enabled) ...[
                              if (_adult)
                                _switch(
                                    l10n.nutritionGoalCalorieCheckinsTitle,
                                    _calorieAlerts,
                                    (value) =>
                                        setState(() => _calorieAlerts = value),
                                    subtitle:
                                        l10n.nutritionGoalCalorieCheckinsSub),
                              if (_adult)
                                _switch(l10n.nutritionGoalMealIdeasTitle, _ideas,
                                    (value) => setState(() => _ideas = value),
                                    subtitle: l10n.nutritionGoalMealIdeasSub),
                              if (_adult && _weightGoal)
                                _switch(l10n.nutritionGoalWeeklyWeightCheckin,
                                    _weekly,
                                    (value) => setState(() => _weekly = value)),
                              _switch(l10n.nutritionGoalMonthlyReview, _monthly,
                                  (value) => setState(() => _monthly = value)),
                              _switch(l10n.nutritionGoalYearlyReview, _yearly,
                                  (value) => setState(() => _yearly = value)),
                              DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _zone,
                                  decoration: InputDecoration(
                                      labelText: l10n.nutritionGoalTimeZoneLabel),
                                  items: [
                                    for (final zone in {..._zones, _zone})
                                      DropdownMenuItem(
                                          value: zone,
                                          child: Text(zone.split('/').last.replaceAll('_', ' '),
                                              style: const TextStyle(
                                                  fontSize: 13)))
                                  ],
                                  onChanged: _saving
                                      ? null
                                      : (value) =>
                                          setState(() => _zone = value!)),
                              const SizedBox(height: 12),
                              for (final entry in {
                                'breakfast': l10n.nutritionGoalBreakfastCheckin,
                                'lunch': l10n.nutritionGoalLunchCheckin,
                                'dinner': l10n.nutritionGoalDinnerCheckin,
                                'quietStart': l10n.nutritionGoalQuietHoursStart,
                                'quietEnd': l10n.nutritionGoalQuietHoursEnd
                              }.entries)
                                ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(entry.value,
                                        style: const TextStyle(fontSize: 13)),
                                    trailing: Text(TimeOfDay(
                                            hour: _times[entry.key]! ~/ 60,
                                            minute: _times[entry.key]! % 60)
                                        .format(context)),
                                    onTap: _saving
                                        ? null
                                        : () => _time(entry.key)),
                              Text(l10n.nutritionGoalQuietHoursNote,
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          ]),
                      if (!widget.signup)
                        _section(
                            l10n.nutritionGoalSectionStatusTitle,
                            l10n.nutritionGoalSectionStatusSub,
                            [
                              DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _status,
                                  items: [
                                    DropdownMenuItem(
                                        value: 'active',
                                        child: Text(
                                            l10n.nutritionGoalStatusActive)),
                                    DropdownMenuItem(
                                        value: 'paused',
                                        child: Text(
                                            l10n.nutritionGoalStatusPaused)),
                                    DropdownMenuItem(
                                        value: 'achieved',
                                        child: Text(
                                            l10n.nutritionGoalStatusAchieved))
                                  ],
                                  onChanged: _saving
                                      ? null
                                      : (value) =>
                                          setState(() => _status = value!)),
                              _switch(
                                  l10n.nutritionGoalStartFreshTitle,
                                  _restart,
                                  (value) => setState(() {
                                        _restart = value;
                                        if (value) _status = 'active';
                                      }),
                                  subtitle: l10n.nutritionGoalStartFreshSub),
                            ]),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(_error!,
                                style: TextStyle(color: context.fitlek.error))),
                      SizedBox(
                          height: 54,
                          child: FilledButton(
                              onPressed: _saving ? null : _save,
                              child: Text(_saving
                                  ? l10n.nutritionGoalSaving
                                  : widget.signup
                                      ? l10n.nutritionGoalUseThisGoal
                                      : l10n.nutritionGoalSaveMyGoal))),
                      if (widget.signup) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            key: const ValueKey('skip-goal-bottom-btn'),
                            onPressed: () =>
                                Navigator.pop(context, const {'skipped': true}),
                            child: Text(
                              l10n.nutritionGoalSetupLaterInProfile,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ]))));
  }
}
