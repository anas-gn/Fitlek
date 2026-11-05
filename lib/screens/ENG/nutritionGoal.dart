import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/nutrition_diary_service.dart';
import '../../theme/fitlek_theme_extension.dart';

const nutritionGoalLabels = {
  'balanced': 'Build balanced habits',
  'lose': 'Lose weight gradually',
  'gain': 'Gain weight gradually',
  'maintain': 'Maintain my weight'
};
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
    if (!_form.currentState!.validate()) return;
    if (_weightGoal && !_adult) {
      setState(() => _error =
          'Weight-change goals are available for adults. Choose balanced habits for meal tracking.');
      return;
    }
    final current = _value('currentWeight'),
        target = _value('targetWeight'),
        height = _value('height');
    if (_weightGoal &&
        ((target! / (height! / 100) / (height / 100)) < 18.5 ||
            (_type == 'lose' ? target >= current! : target <= current!))) {
      setState(() => _error =
          'Review your target weight and goal direction. This planner does not support underweight targets.');
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
          {bool required = false, double min = 0, double max = 500}) =>
      Padding(
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
                return required ? 'Add $label' : null;
              }
              final value = double.tryParse(raw.replaceAll(',', '.'));
              return value == null ||
                      !value.isFinite ||
                      value < min ||
                      value > max ||
                      (key == 'age' && value != value.roundToDouble())
                  ? 'Enter a valid $label'
                  : null;
            },
          ));
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

  Widget _buildSmartTargetsCard(
      BuildContext context, RecommendedTargets? rec) {
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
                'Complete your age, height, weight & biological sex above to see personalized daily calorie and macro recommendations.',
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
      ('balanced', '🥑 Balanced'),
      ('high_protein', '🍗 High Protein'),
      ('low_carb', '🥗 Low Carb'),
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
                    const Text(
                      'Recommended Daily Targets',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      rec.note,
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
                  'Calories',
                  '${rec.calories.round()}',
                  'kcal/day',
                  rec.diff < 0
                      ? '${rec.diff.round()} deficit'
                      : rec.diff > 0
                          ? '+${rec.diff.round()} surplus'
                          : 'Maintenance',
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _macroStatBadge(
                  context,
                  'Protein',
                  '${rec.protein.round()}g',
                  '${((rec.protein * 4 / rec.calories) * 100).round()}%',
                  'Muscle recovery',
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
                  'Carbs',
                  '${rec.carbs.round()}g',
                  '${((rec.carbs * 4 / rec.calories) * 100).round()}%',
                  'Daily energy',
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _macroStatBadge(
                  context,
                  'Fat',
                  '${rec.fat.round()}g',
                  '${((rec.fat * 9 / rec.calories) * 100).round()}%',
                  'Hormone health',
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
                'Dietary Style: ',
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
              label: const Text(
                'Apply Recommended Targets',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
                      'Applied ${rec.calories.round()} kcal · ${rec.protein.round()}g P · ${rec.carbs.round()}g C · ${rec.fat.round()}g F!',
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
            title:
                Text(widget.signup ? 'Your first goal' : 'My nutrition goal'),
            actions: [
              if (widget.signup)
                TextButton(
                  key: const ValueKey('skip-goal-signup-btn'),
                  onPressed: () =>
                      Navigator.pop(context, const {'skipped': true}),
                  child: const Text('Skip for now',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
            ]),
        body: Form(
            key: _form,
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('A plan that fits your life.',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 8),
                      Text(
                          'Start simply. You can change your goal, targets or reminders from My profile at any time.',
                          style: TextStyle(
                              color: context.fitlek.textMuted, height: 1.5)),
                      const SizedBox(height: 22),
                      _section(
                          'What matters to you?',
                          'A weight goal is optional. Balanced habits lets you track meals without a weight target.',
                          [
                            DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _type,
                                decoration:
                                    const InputDecoration(labelText: 'My goal'),
                                items: [
                                  for (final entry
                                      in nutritionGoalLabels.entries)
                                    DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value,
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
                            _number('age', 'Age (years)',
                                required: _weightGoal, min: 13, max: 100),
                            if (!_minor)
                              _number('height', 'Height (cm)',
                                  required: _weightGoal, min: 1, max: 300),
                            if (!_minor)
                              _number('currentWeight', 'Starting weight (kg)',
                                  required: _weightGoal, min: 1, max: 500),
                            if (_weightGoal)
                              _number('targetWeight', 'Target weight (kg)',
                                  required: true, min: 25, max: 500),
                            if (!_minor)
                              DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _sex,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Biological sex (for metabolic formula)'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'male', child: Text('Male')),
                                    DropdownMenuItem(
                                        value: 'female', child: Text('Female'))
                                  ],
                                  onChanged: _saving
                                      ? null
                                      : (value) =>
                                          setState(() => _sex = value)),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _activity,
                                decoration: const InputDecoration(
                                    labelText: 'Usual activity'),
                                items: [
                                  for (final entry in {
                                    'low': 'Mostly seated',
                                    'light': 'Lightly active',
                                    'moderate': 'Moderately active',
                                    'high': 'Very active'
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
                                decoration: const InputDecoration(
                                    labelText: 'Food preference'),
                                items: [
                                  for (final entry in {
                                    'balanced': 'No specific preference',
                                    'vegetarian': 'Vegetarian',
                                    'vegan': 'Vegan',
                                    'halal': 'Halal'
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
                            'Daily targets',
                            'Set your daily calorie and macronutrient targets. You can apply our smart recommendations or customize your own numbers below.',
                            [
                              _buildSmartTargetsCard(context, recommended),
                              const SizedBox(height: 8),
                              for (final key in nutritionKeys)
                                _number(key,
                                    '${mealTypeLabel(key)} (${key == 'calories' ? 'kcal' : 'g'})',
                                    max: key == 'calories' ? 20000 : 2000),
                              ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text(
                                      'Estimate maintenance calories',
                                      style: TextStyle(fontSize: 14)),
                                  children: [
                                    const Text(
                                        'Optional general estimate for healthy adults aged 18–80. It does not calculate a weight-loss or weight-gain diet.',
                                        style: TextStyle(
                                            fontSize: 12, height: 1.5)),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _sex,
                                        decoration: const InputDecoration(
                                            labelText: 'Sex used for the estimate'),
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'male',
                                              child: Text('Male')),
                                          DropdownMenuItem(
                                              value: 'female',
                                              child: Text('Female'))
                                        ],
                                        onChanged: _saving
                                            ? null
                                            : (value) =>
                                                setState(() => _sex = value)),
                                    _switch(
                                        'General estimates are suitable for me',
                                        _eligible,
                                        (value) =>
                                            setState(() => _eligible = value),
                                        subtitle:
                                            'Use manual targets if pregnant, breastfeeding, under a medical diet or unsure.'),
                                    if (estimate != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Column(children: [
                                            Text(
                                                'About ${estimate.round()} kcal/day for maintenance',
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
                                                  child: const Text(
                                                      'Use maintenance estimate'))
                                          ]))
                                    else
                                      const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Text(
                                              'Add adult age, height, weight, sex and eligibility to see an estimate. Some needs are outside this general estimator.',
                                              style: TextStyle(fontSize: 12))),
                                    TextButton(
                                        onPressed: () => launchUrl(Uri.parse(
                                            'https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner')),
                                        child: const Text(
                                            'About general calorie planning')),
                                  ]),
                            ]),
                      if (_minor)
                        _section(
                            'Meal tracking for younger clients',
                            'This mode records meals without calorie targets or weight-change prompts. A qualified professional can guide individual needs.',
                            []),
                      _section(
                          'Support on your terms',
                          'Reminders use your logged meals, which may be incomplete. They never ask you to skip meals or compensate for eating.',
                          [
                            _switch('Nutrition reminders', _enabled,
                                (value) => setState(() => _enabled = value),
                                subtitle:
                                    'Optional. Up to 3 routine reminders a day, spaced apart.'),
                            if (_enabled) ...[
                              if (_adult)
                                _switch(
                                    'Calorie target check-ins',
                                    _calorieAlerts,
                                    (value) =>
                                        setState(() => _calorieAlerts = value),
                                    subtitle:
                                        'Gentle alerts when logged calories exceed your target. Targets below 1,500 kcal do not trigger alerts.'),
                              if (_adult)
                                _switch('Include gentle meal ideas', _ideas,
                                    (value) => setState(() => _ideas = value),
                                    subtitle:
                                        'Suggestions that respect your appetite and routine.'),
                              if (_adult && _weightGoal)
                                _switch('Weekly weight check-in', _weekly,
                                    (value) => setState(() => _weekly = value)),
                              _switch('Monthly progress review', _monthly,
                                  (value) => setState(() => _monthly = value)),
                              _switch('Yearly progress review', _yearly,
                                  (value) => setState(() => _yearly = value)),
                              DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _zone,
                                  decoration: const InputDecoration(
                                      labelText: 'Reminder time zone'),
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
                                'breakfast': 'Breakfast check-in',
                                'lunch': 'Lunch check-in',
                                'dinner': 'Dinner check-in',
                                'quietStart': 'Quiet hours start',
                                'quietEnd': 'Quiet hours end'
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
                              const Text(
                                  'Reminders inside quiet hours are skipped; equal start and end times turn quiet hours off. Notifications also need device permission.',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          ]),
                      if (!widget.signup)
                        _section(
                            'Your goal status',
                            'Pause whenever you like. For a weight goal, two recent weigh-in days must confirm the target before automatic completion.',
                            [
                              DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _status,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'active', child: Text('Active')),
                                    DropdownMenuItem(
                                        value: 'paused', child: Text('Paused')),
                                    DropdownMenuItem(
                                        value: 'achieved',
                                        child: Text('Goal reached'))
                                  ],
                                  onChanged: _saving
                                      ? null
                                      : (value) =>
                                          setState(() => _status = value!)),
                              _switch(
                                  'Start a fresh goal',
                                  _restart,
                                  (value) => setState(() {
                                        _restart = value;
                                        if (value) _status = 'active';
                                      }),
                                  subtitle:
                                      'Reset the baseline and start date using these settings.'),
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
                                  ? 'Saving…'
                                  : widget.signup
                                      ? 'Use this goal'
                                      : 'Save my goal'))),
                      if (widget.signup) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            key: const ValueKey('skip-goal-bottom-btn'),
                            onPressed: () =>
                                Navigator.pop(context, const {'skipped': true}),
                            child: const Text(
                              "I'll set this up later in my profile",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ]))));
  }
}
