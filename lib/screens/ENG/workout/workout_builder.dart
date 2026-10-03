import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'exercise_library.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final int? clientID;
  final Exercise? initialExercise;
  final int? initialDayID;
  final bool personal, duplicate;
  final WorkoutPlan? plan;
  const WorkoutBuilderScreen(
      {super.key,
      this.clientID,
      this.initialExercise,
      this.initialDayID,
      this.plan,
      this.personal = false,
      this.duplicate = false});
  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _description = TextEditingController();
  List<WorkoutDay> _days = [];
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    if (p != null) {
      _name.text = p.name;
      _description.text = p.description;
      _days = p.days
          .map((d) => WorkoutDay(
              id: widget.duplicate ? 0 : d.id,
              name: d.name,
              dayOfWeek: d.dayOfWeek,
              configuration: Map<String, dynamic>.from(d.configuration),
              exercises: d.exercises
                  .map((e) => WorkoutExercise(
                      id: widget.duplicate ? 0 : e.id,
                      exercise: e.exercise,
                      sets: e.sets,
                      reps: e.reps,
                      durationSeconds: e.durationSeconds,
                      weight: e.weight,
                      restSeconds: e.restSeconds,
                      notes: e.notes,
                      supersetGroup: e.supersetGroup,
                      configuration:
                          Map<String, dynamic>.from(e.configuration)))
                  .toList()))
          .toList();
    }
    if (widget.initialExercise != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (_days.isEmpty) await _day();
        if (!mounted || _days.isEmpty) return;
        final day =
            _days.where((d) => d.id == widget.initialDayID).firstOrNull ??
                _days.first;
        await _exercise(day, selected: widget.initialExercise);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _day({WorkoutDay? day}) async {
    final name = TextEditingController(text: day?.name ?? '');
    final form = GlobalKey<FormState>();
    int? weekday = day?.dayOfWeek;
    String progression = day?.configuration['progression'] ?? 'off';
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: WorkoutLabel(
                        day == null ? 'Add workout day' : 'Edit workout day'),
                    content: SingleChildScrollView(
                        child: Form(
                            key: form,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                      controller: name,
                                      maxLength: 160,
                                      decoration: InputDecoration(
                                          labelText: (('Day name'))
                                              .workoutTr(context)),
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? (((('Enter a day name')
                                              .workoutTr(context))))
                                          : null),
                                  DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      initialValue: weekday ?? 0,
                                      decoration: InputDecoration(
                                          labelText: (('Scheduled day'))
                                              .workoutTr(context)),
                                      items: [
                                        const DropdownMenuItem(
                                            value: 0,
                                            child: WorkoutLabel('Flexible')),
                                        ...WorkoutText.weekdays
                                            .asMap()
                                            .entries
                                            .map((e) => DropdownMenuItem(
                                                value: e.key + 1,
                                                child: WorkoutLabel(e.value)))
                                      ],
                                      onChanged: (v) => update(
                                          () => weekday = v == 0 ? null : v)),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: progression,
                                      decoration: InputDecoration(
                                          labelText: 'Routine progression'
                                              .workoutTr(context)),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'off',
                                            child: WorkoutLabel(
                                                'Off — prescribed targets')),
                                        DropdownMenuItem(
                                            value: 'linear',
                                            child: WorkoutLabel('Linear')),
                                        DropdownMenuItem(
                                            value: 'double',
                                            child: WorkoutLabel(
                                                'Double progression')),
                                        DropdownMenuItem(
                                            value: 'greyskull',
                                            child: WorkoutLabel(
                                                'Greyskull · AMRAP')),
                                        DropdownMenuItem(
                                            value: 'time',
                                            child:
                                                WorkoutLabel('Increase time'))
                                      ],
                                      onChanged: (v) =>
                                          update(() => progression = v!)),
                                  const WorkoutLabel(
                                      'Exercises can follow the routine rule or choose their own progression.')
                                ]))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const WorkoutLabel(WorkoutText.cancel)),
                      ElevatedButton(
                          onPressed: () {
                            if (form.currentState!.validate()) {
                              Navigator.pop(context, true);
                            }
                          },
                          child: const WorkoutLabel(WorkoutText.save))
                    ])));
    if (yes == true && mounted) {
      setState(() {
        if (day == null) {
          _days.add(WorkoutDay(
              name: name.text.trim(),
              dayOfWeek: weekday,
              configuration: {'progression': progression}));
        } else {
          day.name = name.text.trim();
          day.dayOfWeek = weekday;
          day.configuration = {
            ...day.configuration,
            'progression': progression
          };
        }
      });
    }
    // Dialog route disposes its text field after the pop animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
  }

  Future<void> _exercise(WorkoutDay day,
      {WorkoutExercise? existing, Exercise? selected}) async {
    final exercise = selected ??
        existing?.exercise ??
        await Navigator.push<Exercise>(
            context,
            WorkoutRoute(
                builder: (_) => const WorkoutExerciseLibrary(selecting: true)));
    if (exercise == null || !mounted) return;
    final value = await workoutDialog<WorkoutExercise>(
        context: context,
        builder: (_) =>
            _PrescriptionDialog(exercise: exercise, existing: existing));
    if (value == null || !mounted) return;
    setState(() {
      if (existing == null) {
        day.exercises.add(value);
      } else {
        day.exercises[day.exercises.indexOf(existing)] = value;
      }
    });
  }

  Future<void> _save(String status) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      if (widget.clientID != null) 'clientID': widget.clientID,
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'status': status,
      'days': _days.map((d) => d.toJson()).toList(),
      if (widget.plan != null && !widget.duplicate)
        'revision': widget.plan!.revision
    };
    try {
      if (widget.plan == null || widget.duplicate) {
        await WorkoutService.post('/plans', body);
      } else {
        await WorkoutService.put('/plans/${widget.plan!.id}', body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _move<T>(List<T> list, int index, int offset) => setState(() {
        if (list is List<WorkoutExercise>) {
          final moved =
              moveWorkoutGroup(list.cast<WorkoutExercise>(), index, offset);
          list
            ..clear()
            ..addAll(moved.cast<T>());
        } else {
          final value = list.removeAt(index);
          list.insert(index + offset, value);
        }
      });
  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: WorkoutScaffold(
          appBar: AppBar(
              title: WorkoutLabel(widget.plan == null
                  ? 'Create workout plan'
                  : 'Edit workout plan')),
          body: AbsorbPointer(
              absorbing: _saving,
              child: Form(
                  key: _form,
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    TextFormField(
                        controller: _name,
                        maxLength: 160,
                        decoration: InputDecoration(
                            labelText: (('Plan name')).workoutTr(context)),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? (((('Enter a plan name').workoutTr(context))))
                            : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _description,
                        maxLength: 5000,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                            labelText: (('Description')).workoutTr(context))),
                    const SizedBox(height: 16),
                    ..._days.asMap().entries.map((entry) {
                      final d = entry.value;
                      final i = entry.key;
                      return Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: WorkoutLabel(d.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium)),
                                      IconButton(
                                          tooltip: (('Move day up'))
                                              .workoutTr(context),
                                          onPressed: i == 0
                                              ? null
                                              : () => _move(_days, i, -1),
                                          icon: const Icon(
                                              Icons.arrow_upward_rounded)),
                                      IconButton(
                                          tooltip: (('Move day down'))
                                              .workoutTr(context),
                                          onPressed: i == _days.length - 1
                                              ? null
                                              : () => _move(_days, i, 1),
                                          icon: const Icon(
                                              Icons.arrow_downward_rounded)),
                                      IconButton(
                                          tooltip:
                                              (('Edit day')).workoutTr(context),
                                          onPressed: () => _day(day: d),
                                          icon:
                                              const Icon(Icons.edit_outlined)),
                                      IconButton(
                                          tooltip: (('Remove day'))
                                              .workoutTr(context),
                                          onPressed: () =>
                                              setState(() => _days.remove(d)),
                                          icon: const Icon(Icons.close_rounded))
                                    ]),
                                    WorkoutLabel(d.dayOfWeek == null
                                        ? 'Flexible'
                                        : WorkoutText
                                            .weekdays[d.dayOfWeek! - 1]),
                                    ...d.exercises.asMap().entries.map((row) {
                                      final e = row.value;
                                      final n = row.key;
                                      return Column(children: [
                                        ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title:
                                                WorkoutLabel(e.exercise.name),
                                            subtitle: WorkoutLabel(
                                                '${e.sets} × ${e.exercise.isTimed ? '${e.durationSeconds} sec' : '${e.reps} reps'} · ${workoutValue(e.weight)} kg · ${e.restSeconds} sec rest${e.supersetGroup.isEmpty ? '' : '\nSuperset ${e.supersetGroup}'}'),
                                            onTap: () =>
                                                _exercise(d, existing: e),
                                            trailing: IconButton(
                                                tooltip: (('Remove exercise'))
                                                    .workoutTr(context),
                                                onPressed: () => setState(() =>
                                                    d.exercises.remove(e)),
                                                icon: const Icon(
                                                    Icons.close_rounded))),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                  tooltip:
                                                      (('Move exercise up'))
                                                          .workoutTr(context),
                                                  onPressed: n == 0
                                                      ? null
                                                      : () => _move(
                                                          d.exercises, n, -1),
                                                  icon: const Icon(Icons
                                                      .arrow_upward_rounded)),
                                              IconButton(
                                                  tooltip:
                                                      (('Move exercise down'))
                                                          .workoutTr(context),
                                                  onPressed: n ==
                                                          d.exercises.length - 1
                                                      ? null
                                                      : () => _move(
                                                          d.exercises, n, 1),
                                                  icon: const Icon(Icons
                                                      .arrow_downward_rounded))
                                            ])
                                      ]);
                                    }),
                                    OutlinedButton.icon(
                                        onPressed: () => _exercise(d),
                                        icon: const Icon(Icons.add_rounded),
                                        label:
                                            const WorkoutLabel('Add exercise')),
                                  ])));
                    }),
                    OutlinedButton.icon(
                        onPressed: _days.length >= 14 ? null : () => _day(),
                        icon: const Icon(Icons.add_rounded),
                        label: const WorkoutLabel('Add workout day')),
                    const SizedBox(height: 16),
                    if (_saving)
                      const Center(child: CircularProgressIndicator()),
                    ElevatedButton(
                        onPressed: () => _save('assigned'),
                        child: WorkoutLabel(widget.personal
                            ? 'Save routine'
                            : 'Save and assign to client')),
                    TextButton(
                        onPressed: () => _save('draft'),
                        child: const WorkoutLabel('Save draft')),
                  ])))));
}

class _PrescriptionDialog extends StatefulWidget {
  final Exercise exercise;
  final WorkoutExercise? existing;
  const _PrescriptionDialog({required this.exercise, this.existing});
  @override
  State<_PrescriptionDialog> createState() => _PrescriptionDialogState();
}

class _PrescriptionDialogState extends State<_PrescriptionDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _sets,
      _reps,
      _weight,
      _duration,
      _rest,
      _notes,
      _group;
  String _progression = 'inherit';
  bool _perSide = false;
  bool _excluded = false;
  String _effortScale = 'off';
  final _targetEffort = TextEditingController();
  final _increment = TextEditingController(text: '2.5'),
      _minReps = TextEditingController(text: '8'),
      _bodyweightCeiling = TextEditingController(text: '30'),
      _bodyweightSets = TextEditingController(text: '6');
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _progression = e?.configuration['progression'] ?? 'inherit';
    _perSide = e?.configuration['perSide'] == true;
    _excluded = e?.configuration['excludeFromProgression'] == true;
    _effortScale = e?.configuration['targetRpe'] != null
        ? 'rpe'
        : e?.configuration['targetRir'] != null
            ? 'rir'
            : 'off';
    _targetEffort.text =
        '${e?.configuration['targetRpe'] ?? e?.configuration['targetRir'] ?? ''}';
    _increment.text =
        '${e?.configuration['increment'] ?? (widget.exercise.isTimed ? 5 : 2.5)}';
    _minReps.text = '${e?.configuration['minReps'] ?? 8}';
    _bodyweightCeiling.text =
        '${e?.configuration['bodyweightRepCeiling'] ?? 30}';
    _bodyweightSets.text = '${e?.configuration['maxBodyweightSets'] ?? 6}';
    _sets = TextEditingController(text: '${e?.sets ?? 3}');
    _reps = TextEditingController(text: '${e?.reps ?? 10}');
    _weight = TextEditingController(
        text: workoutValue(WorkoutService.displayWeight(e?.weight ?? 0)));
    _duration = TextEditingController(text: '${e?.durationSeconds ?? 30}');
    _rest = TextEditingController(
        text:
            '${e?.restSeconds ?? WorkoutService.preferences['defaultRestSeconds'] ?? 90}');
    _notes = TextEditingController(text: e?.notes ?? '');
    _group = TextEditingController(text: e?.supersetGroup ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _sets,
      _reps,
      _weight,
      _duration,
      _rest,
      _notes,
      _group,
      _increment,
      _minReps,
      _bodyweightCeiling,
      _bodyweightSets,
      _targetEffort
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _number(TextEditingController c, String label, num min, num max,
          {bool whole = true}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              controller: c,
              keyboardType: TextInputType.numberWithOptions(decimal: !whole),
              decoration:
                  InputDecoration(labelText: ((label)).workoutTr(context)),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return n == null ||
                        !n.isFinite ||
                        n < min ||
                        n > max ||
                        whole && int.tryParse(v ?? '') == null
                    ? 'Enter a value from $min to $max'.workoutTr(context)
                    : null;
              }));
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: WorkoutLabel(widget.exercise.name),
          content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                  child: Form(
                      key: _form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _number(_sets, 'Sets', 1, 30),
                        if (widget.exercise.isTimed)
                          _number(_duration, 'Target duration (sec)', 1, 86400)
                        else
                          _number(_reps, 'Target repetitions', 1, 1000),
                        _number(
                            _weight,
                            widget.exercise.isBodyweight
                                ? 'Added weight (${WorkoutService.unit})'
                                : 'Target weight (${WorkoutService.unit})',
                            0,
                            WorkoutService.displayWeight(2000),
                            whole: false),
                        _number(_rest, 'Rest (sec)', 0, 3600),
                        DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _progression,
                            decoration: InputDecoration(
                                labelText:
                                    (('Progression')).workoutTr(context)),
                            items: [
                              const DropdownMenuItem(
                                  value: 'inherit',
                                  child: WorkoutLabel(
                                      'Follow routine progression')),
                              const DropdownMenuItem(
                                  value: 'off',
                                  child:
                                      WorkoutLabel('Off — prescribed targets')),
                              if (widget.exercise.isTimed)
                                const DropdownMenuItem(
                                    value: 'time',
                                    child: WorkoutLabel('Increase time')),
                              if (!widget.exercise.isTimed) ...const [
                                DropdownMenuItem(
                                    value: 'linear',
                                    child: WorkoutLabel('Linear')),
                                DropdownMenuItem(
                                    value: 'double',
                                    child: WorkoutLabel('Double progression')),
                                DropdownMenuItem(
                                    value: 'greyskull',
                                    child: WorkoutLabel('Greyskull · AMRAP'))
                              ]
                            ],
                            onChanged: (v) =>
                                setState(() => _progression = v!)),
                        if (_progression != 'off')
                          _number(
                              _increment,
                              widget.exercise.isTimed
                                  ? 'Time increment (sec)'
                                  : 'Load increment (kg)',
                              0.1,
                              100,
                              whole: false),
                        if (_progression == 'double')
                          _number(_minReps, 'Minimum repetitions', 1, 1000),
                        if (widget.exercise.isBodyweight &&
                            !widget.exercise.isTimed &&
                            _progression != 'off') ...[
                          _number(_bodyweightCeiling,
                              'Bodyweight repetition ceiling', 1, 1000),
                          _number(_bodyweightSets, 'Maximum bodyweight sets', 1,
                              30),
                        ],
                        if (!widget.exercise.isTimed)
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const WorkoutLabel(
                                  'Log each side separately'),
                              value: _perSide,
                              onChanged: (v) => setState(() => _perSide = v)),
                        DropdownButtonFormField<String>(
                            initialValue: _effortScale,
                            decoration: InputDecoration(
                                labelText: 'Target effort (optional)'
                                    .workoutTr(context)),
                            items: const [
                              DropdownMenuItem(
                                  value: 'off', child: WorkoutLabel('Off')),
                              DropdownMenuItem(
                                  value: 'rpe', child: WorkoutLabel('RPE')),
                              DropdownMenuItem(
                                  value: 'rir', child: WorkoutLabel('RIR'))
                            ],
                            onChanged: (v) =>
                                setState(() => _effortScale = v!)),
                        if (_effortScale != 'off')
                          _number(
                              _targetEffort,
                              _effortScale == 'rpe'
                                  ? 'Target RPE'
                                  : 'Target RIR',
                              _effortScale == 'rpe' ? 1 : 0,
                              10,
                              whole: _effortScale == 'rir'),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const WorkoutLabel(
                                'Exclude from automatic progression'),
                            value: _excluded,
                            onChanged: (v) => setState(() => _excluded = v)),
                        TextFormField(
                            controller: _group,
                            maxLength: 64,
                            decoration: InputDecoration(
                                labelText: (('Superset group (optional)'))
                                    .workoutTr(context),
                                helperText:
                                    (('Use the same group for adjacent exercises.'))
                                        .workoutTr(context))),
                        TextFormField(
                            controller: _notes,
                            maxLength: 2000,
                            maxLines: 3,
                            decoration: InputDecoration(
                                labelText:
                                    (('Coach notes')).workoutTr(context))),
                      ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const WorkoutLabel(WorkoutText.cancel)),
            ElevatedButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  if (_progression == 'double' &&
                      int.parse(_minReps.text) > int.parse(_reps.text)) {
                    workoutError(context,
                        const WorkoutApiException('invalid_target', 400));
                    return;
                  }
                  Navigator.pop(
                      context,
                      WorkoutExercise(
                          id: widget.existing?.id ?? 0,
                          exercise: widget.exercise,
                          sets: int.parse(_sets.text),
                          reps: widget.exercise.isTimed
                              ? null
                              : int.parse(_reps.text),
                          durationSeconds: widget.exercise.isTimed
                              ? int.parse(_duration.text)
                              : null,
                          weight: widget.existing?.weight != null &&
                                  _weight.text ==
                                      workoutValue(WorkoutService.displayWeight(
                                          widget.existing!.weight!))
                              ? widget.existing!.weight
                              : WorkoutService.storedWeight(
                                  double.parse(_weight.text)),
                          restSeconds: int.parse(_rest.text),
                          notes: _notes.text.trim(),
                          supersetGroup: _group.text.trim(),
                          configuration: {
                            ...?widget.existing?.configuration,
                            'progression': _progression,
                            'increment':
                                double.tryParse(_increment.text) ?? 2.5,
                            'minReps': _progression == 'double'
                                ? int.parse(_minReps.text)
                                : null,
                            'perSide': _perSide,
                            'bodyweightRepCeiling':
                                int.parse(_bodyweightCeiling.text),
                            'maxBodyweightSets':
                                int.parse(_bodyweightSets.text),
                            'excludeFromProgression': _excluded,
                            'targetRpe': _effortScale == 'rpe'
                                ? double.parse(_targetEffort.text)
                                : null,
                            'targetRir': _effortScale == 'rir'
                                ? int.parse(_targetEffort.text)
                                : null
                          }));
                },
                child: const WorkoutLabel(WorkoutText.save))
          ]);
}
