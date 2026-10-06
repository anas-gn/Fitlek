import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import '../../../services/apiService.dart';
import 'workout_ui.dart';
import 'exercise_library.dart';
import 'workout_muscles.dart';
import 'workout_set_row.dart';
import 'workout_demonstration.dart';

Future<WorkoutExercise?> workoutConfigureExercise(BuildContext context,
        {required Exercise exercise,
        WorkoutExercise? existing,
        VoidCallback? onDelete}) =>
    workoutSheet<WorkoutExercise>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _PrescriptionDialog(
            exercise: exercise, existing: existing, onDelete: onDelete));

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
  bool _saving = false, _dirty = false, _allowLeave = false;
  Object? _saveError;
  int? _planID;
  int _revision = 0, _generation = 0;
  Timer? _autosaveTimer;
  Future<bool>? _writeFuture;
  bool get _autosave => _simpleRoutine && (widget.plan?.coachID ?? 0) == 0;

  bool get _simpleRoutine =>
      widget.personal && (_days.length == 1 || widget.initialDayID != null);
  WorkoutDay get _routine =>
      _days.where((d) => d.id == widget.initialDayID).firstOrNull ??
      _days.first;
  List<WorkoutDay> get _visibleDays => _simpleRoutine ? [_routine] : _days;
  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    if (p != null && !widget.duplicate && p.id > 0) {
      _planID = p.id;
      _revision = p.revision;
    }
    if (p != null) {
      _name.text = p.name;
      _description.text = p.description;
      _days = p.days
          .where((d) =>
              !widget.duplicate ||
              widget.initialDayID == null ||
              d.id == widget.initialDayID)
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
    if (widget.personal && _days.isEmpty) {
      _name.text = 'New routine';
      _days.add(WorkoutDay(
          name: 'New routine',
          configuration: {'progression': 'linear', 'icon': 'strength'}));
    }
    if (_simpleRoutine) _name.text = _routine.name;
    if (_autosave && _planID == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changed();
      });
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
    _autosaveTimer?.cancel();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _day({WorkoutDay? day}) async {
    final name = TextEditingController(text: day?.name ?? '');
    final form = GlobalKey<FormState>();
    int? weekday = day?.dayOfWeek;
    String progression = day?.configuration['progression'] ?? 'off';
    String icon = day?.configuration['icon'] ?? 'strength';
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: WorkoutLabel(widget.personal
                        ? 'Routine options'
                        : day == null
                            ? 'Add workout day'
                            : 'Edit workout day'),
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
                                          labelText: ((widget.personal
                                                  ? 'Routine name'
                                                  : 'Day name'))
                                              .workoutTr(context)),
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? (((('Enter a day name')
                                              .workoutTr(context))))
                                          : null),
                                  if (!widget.personal)
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
                                      initialValue: icon,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                          labelText: 'Routine icon'
                                              .workoutTr(context)),
                                      items: workoutRoutineIcons.entries
                                          .map((entry) => DropdownMenuItem(
                                              value: entry.key,
                                              child: Row(children: [
                                                Icon(entry.value),
                                                const SizedBox(width: 12),
                                                WorkoutLabel(entry.key)
                                              ])))
                                          .toList(),
                                      onChanged: (value) =>
                                          update(() => icon = value!)),
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
              configuration: {'progression': progression, 'icon': icon}));
        } else {
          day.name = name.text.trim();
          if (_simpleRoutine && day == _routine) _name.text = day.name;
          day.dayOfWeek = weekday;
          day.configuration = {
            ...day.configuration,
            'progression': progression,
            'icon': icon
          };
        }
      });
    }
    if (yes == true && mounted) _changed();
    // Dialog route disposes its text field after the pop animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
  }

  Future<void> _exercise(WorkoutDay day,
      {WorkoutExercise? existing, Exercise? selected}) async {
    if (existing == null && selected == null) {
      await workoutPickExercise(context,
          onSelect: (pickerContext, exercise) async {
        final value =
            await workoutConfigureExercise(pickerContext, exercise: exercise);
        if (value == null || !mounted) return;
        setState(() => day.exercises.add(value));
        _changed();
      });
      return;
    }
    final exercise = selected ?? existing?.exercise;
    if (exercise == null || !mounted) return;
    final value = await workoutConfigureExercise(context,
        exercise: exercise,
        existing: existing,
        onDelete: existing == null
            ? null
            : () {
                if (!mounted) return;
                setState(() {
                  day.exercises.remove(existing);
                  cleanupWorkoutSupersets(day.exercises);
                });
                _changed();
              });
    if (value == null || !mounted) return;
    setState(() {
      if (existing == null) {
        day.exercises.add(value);
      } else {
        day.exercises[day.exercises.indexOf(existing)] = value;
      }
    });
    _changed();
  }

  void _changed() {
    _generation++;
    _dirty = true;
    _autosaveTimer?.cancel();
    if (_autosave) {
      _autosaveTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) unawaited(_persist('assigned'));
      });
    }
  }

  Future<bool> _persist(String status) async {
    _autosaveTimer?.cancel();
    if (_writeFuture != null) {
      if (!await _writeFuture!) return false;
      if (!_dirty) return true;
    }
    if (_autosave && !_dirty && _planID != null) return true;
    final task = _write(status);
    _writeFuture = task;
    try {
      return await task;
    } finally {
      if (_writeFuture == task) _writeFuture = null;
    }
  }

  Future<bool> _write(String status) async {
    final generation = _generation;
    final savedDays = [..._days];
    final savedExercises = savedDays.map((d) => [...d.exercises]).toList();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final body = {
      if (widget.clientID != null) 'clientID': widget.clientID,
      'name': _simpleRoutine && _days.length > 1
          ? widget.plan!.name
          : _name.text.trim().isEmpty
              ? 'Routine'
              : _name.text.trim(),
      'description': _description.text.trim(),
      'status': status,
      'days': _days
          .map((d) => {
                ...d.toJson(),
                'name': d.name.trim().isEmpty ? 'Routine' : d.name.trim()
              })
          .toList(),
      if (_planID != null) 'revision': _revision
    };
    try {
      final result = _planID == null
          ? await WorkoutService.post('/plans', body)
          : await WorkoutService.put('/plans/$_planID', body);
      _planID = workoutInt(result['id']);
      _revision = workoutInt(result['revision']);
      // Bind server IDs from the committed transaction. A follow-up read is not
      // needed, so a lost network read cannot replace weekly routine identities.
      final dayIDs = result['dayIDs'] as List? ?? [],
          exerciseIDs = result['exerciseIDs'] as List? ?? [];
      var slot = 0;
      for (var i = 0; i < savedDays.length; i++) {
        if (i < dayIDs.length) savedDays[i].id = workoutInt(dayIDs[i]);
        for (final e in savedExercises[i]) {
          if (slot < exerciseIDs.length) e.id = workoutInt(exerciseIDs[slot]);
          slot++;
        }
      }
      if (_generation == generation) _dirty = false;
      return true;
    } catch (e) {
      if (mounted) setState(() => _saveError = e);
      if (!_autosave && mounted) workoutError(context, e);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save(String status) async {
    if (!_form.currentState!.validate()) return;
    if (await _persist(status) && mounted) {
      setState(() => _allowLeave = true);
      Navigator.pop(context, true);
    }
  }

  Future<void> _leave() async {
    if (_saving) await _writeFuture;
    if (!mounted) return;
    if (_dirty && !await _persist('assigned')) return;
    if (mounted) {
      setState(() => _allowLeave = true);
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    if (_dirty && !await _persist('assigned')) return;
    if (!mounted || _planID == null || _routine.id == 0) return;
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const WorkoutLabel('Delete routine?'),
                content: WorkoutLabel(
                    '${_routine.name} and its exercises will be removed. Logged workouts are kept.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const WorkoutLabel('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const WorkoutLabel('Delete'))
                ]));
    if (yes != true || !mounted) return;
    setState(() => _saving = true);
    try {
      WorkoutService.checked(await ApiService.delete(
          '/workout/plans/$_planID/days/${_routine.id}?revision=$_revision'));
      if (mounted) {
        setState(() => _allowLeave = true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _move<T>(List<T> list, int index, int offset) => setState(() {
        if (list is List<WorkoutExercise>) {
          if (widget.personal) {
            moveWorkoutExercise(list.cast<WorkoutExercise>(), index, offset);
          } else {
            final moved =
                moveWorkoutGroup(list.cast<WorkoutExercise>(), index, offset);
            list
              ..clear()
              ..addAll(moved.cast<T>());
          }
        } else {
          final value = list.removeAt(index);
          list.insert(index + offset, value);
        }
        _changed();
      });
  Future<void> _routineRule() async {
    const labels = {
      'off': 'Off — prescribed targets',
      'linear': 'Linear',
      'double': 'Double progression',
      'greyskull': 'Greyskull · AMRAP'
    };
    final rule = await workoutSheet<String>(
        context: context,
        builder: (context) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: WorkoutLabel('Progression',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600))),
              for (final option in labels.entries)
                ListTile(
                    title: WorkoutLabel(option.value),
                    trailing:
                        _routine.configuration['progression'] == option.key
                            ? const Icon(Icons.check_rounded)
                            : null,
                    onTap: () => Navigator.pop(context, option.key))
            ])));
    if (rule == null || !mounted) return;
    setState(() => _routine.configuration['progression'] = rule);
    _changed();
  }

  void _linkPrevious(int index) {
    final e = _routine.exercises[index],
        previous = _routine.exercises[index - 1];
    setState(() {
      if (e.supersetGroup.isNotEmpty &&
          e.supersetGroup == previous.supersetGroup) {
        e.supersetGroup = '';
      } else {
        final group = previous.supersetGroup.isEmpty
            ? 'pair_${DateTime.now().microsecondsSinceEpoch}'
            : previous.supersetGroup;
        previous.supersetGroup = group;
        e.supersetGroup = group;
      }
      cleanupWorkoutSupersets(_routine.exercises);
    });
    _changed();
  }

  String _prescriptionLine(WorkoutExercise e) {
    final count = e.exercise.type == 'cardio'
        ? '${workoutValue((e.durationSeconds ?? 0) / 60)} min · ${workoutValue(workoutNumber(e.configuration['speedKmh']) ?? 8)} km/h'
        : e.exercise.isTimed
            ? workoutClock(e.durationSeconds ?? 0)
            : '${e.reps ?? 0} reps${e.configuration['perSide'] == true ? ' (${workoutValue((e.reps ?? 0) / 2)} per side)' : ''}';
    final load = !e.supportsLoad ||
            e.exercise.isBodyweight && (e.weight ?? 0) == 0
        ? ''
        : ' · ${e.exercise.isBodyweight ? '+' : ''}${workoutValue(WorkoutService.displayWeight(e.weight ?? 0))} ${WorkoutService.unit}';
    return '${e.sets} × $count$load';
  }

  Widget _personalEditor() {
    final d = _routine;
    final groups = workoutExerciseGroups(d.exercises);
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        IconButton.filledTonal(
            tooltip: 'Back'.workoutTr(context),
            style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface),
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left)),
        const SizedBox(width: 12),
        Expanded(
            child: TextFormField(
                controller: _name,
                maxLength: 160,
                decoration: InputDecoration(
                    hintText: 'Routine name'.workoutTr(context),
                    fillColor: Theme.of(context).colorScheme.surface,
                    counterText: ''),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                onChanged: (value) {
                  d.name = value;
                  _changed();
                },
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a plan name'.workoutTr(context)
                    : null)),
        const SizedBox(width: 8),
        IconButton(
            tooltip: 'Routine options'.workoutTr(context),
            onPressed: () => _day(day: d),
            icon: Icon(workoutRoutineIcons[d.configuration['icon']] ??
                Icons.fitness_center_rounded))
      ]),
      const SizedBox(height: 16),
      Card(
          child: ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.trending_up_rounded,
                      color: Colors.white, size: 18)),
              title: const WorkoutLabel('Progression'),
              subtitle: WorkoutLabel(const {
                    'off': 'Off — prescribed targets',
                    'linear': 'Linear',
                    'double': 'Double progression',
                    'greyskull': 'Greyskull · AMRAP'
                  }[d.configuration['progression']] ??
                  'Linear'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _routineRule)),
      const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: WorkoutLabel(
              'Exercises follow this rule unless they have their own progression.',
              style: TextStyle(fontSize: 13))),
      if (d.exercises.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: WorkoutLabel('No exercises yet — add your first one.',
                textAlign: TextAlign.center)),
      if (d.exercises.isNotEmpty)
        for (var n = 0; n < d.exercises.length; n++)
          Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                if (groups.any(
                    (g) => g.length > 1 && identical(g.first, d.exercises[n])))
                  Container(
                      width: double.infinity,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .08),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: const WorkoutLabel('Superset',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600))),
                InkWell(
                    onTap: () => _exercise(d, existing: d.exercises[n]),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(children: [
                          WorkoutExerciseThumbnail(
                              exercise: d.exercises[n].exercise),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                WorkoutLabel(
                                    workoutExerciseTitle(
                                        d.exercises[n].exercise.name),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400)),
                                const SizedBox(height: 4),
                                WorkoutLabel(_prescriptionLine(d.exercises[n]),
                                    style: const TextStyle(fontSize: 13))
                              ])),
                          SizedBox(
                              width: 72,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (n > 0)
                                      SizedBox(
                                          height: 30,
                                          child: IconButton(
                                              tooltip: (d
                                                              .exercises[n]
                                                              .supersetGroup
                                                              .isNotEmpty &&
                                                          d.exercises[n]
                                                                  .supersetGroup ==
                                                              d.exercises[n - 1]
                                                                  .supersetGroup
                                                      ? 'Unlink superset'
                                                      : 'Link previous exercise')
                                                  .workoutTr(context),
                                              padding: EdgeInsets.zero,
                                              color: d.exercises[n]
                                                      .supersetGroup.isNotEmpty
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : null,
                                              onPressed: () => _linkPrevious(n),
                                              icon: const Icon(Icons.link,
                                                  size: 18))),
                                    Row(children: [
                                      Expanded(
                                          child: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                  minWidth: 32, minHeight: 40),
                                              tooltip: 'Move exercise up'
                                                  .workoutTr(context),
                                              onPressed: n == 0
                                                  ? null
                                                  : () =>
                                                      _move(d.exercises, n, -1),
                                              icon: const Icon(
                                                  Icons.keyboard_arrow_up,
                                                  size: 18))),
                                      Expanded(
                                          child: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                  minWidth: 32, minHeight: 40),
                                              tooltip: 'Move exercise down'
                                                  .workoutTr(context),
                                              onPressed: n ==
                                                      d.exercises.length - 1
                                                  ? null
                                                  : () =>
                                                      _move(d.exercises, n, 1),
                                              icon: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 18)))
                                    ])
                                  ]))
                        ]))),
              ])),
      if (d.exercises.isNotEmpty)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WorkoutLabel('What this session hits',
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      const SizedBox(height: 12),
                      WorkoutMuscleCoverage(
                          load: workoutMuscleCoverage(d.exercises),
                          showList: false,
                          showLegend: false),
                      Wrap(
                          spacing: 6,
                          children: (workoutMuscleCoverage(d.exercises)
                                  .entries
                                  .toList()
                                ..sort((a, b) => b.value.compareTo(a.value)))
                              .take(6)
                              .map((entry) => Chip(
                                  label: WorkoutLabel(entry.key,
                                      style: const TextStyle(fontSize: 12))))
                              .toList()),
                    ]))),
      const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: WorkoutLabel(
              'Link an exercise with the one above to perform a superset.',
              style: TextStyle(fontSize: 13))),
      ElevatedButton.icon(
          onPressed: () => _exercise(d),
          icon: const Icon(Icons.add),
          label: const WorkoutLabel('Add exercise')),
      if (_autosave)
        WorkoutLabel(_saveError != null
            ? 'Changes are not saved yet.'
            : _dirty
                ? 'Saving routine…'
                : 'All changes saved'),
      if (_saveError != null) ...[
        WorkoutLabel(WorkoutText.error(_saveError!)),
        TextButton(
            onPressed: () => _persist('assigned'),
            child: const WorkoutLabel('Retry'))
      ],
      TextButton(
          onPressed: () => _save('assigned'),
          child: const WorkoutLabel('Done')),
      if (_planID != null && _autosave)
        TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const WorkoutLabel('Delete routine'))
    ]));
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: _allowLeave || !_saving && (!_autosave || !_dirty),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _autosave) unawaited(_leave());
      },
      child: WorkoutScaffold(
          appBar: _simpleRoutine
              ? null
              : AppBar(
                  title: WorkoutLabel(widget.plan == null
                      ? widget.personal
                          ? 'Create routine'
                          : 'Create workout plan'
                      : widget.personal
                          ? 'Edit routine'
                          : 'Edit workout plan')),
          body: AbsorbPointer(
              absorbing: _saving,
              child: Form(
                  key: _form,
                  child: _simpleRoutine
                      ? _personalEditor()
                      : ListView(padding: const EdgeInsets.all(20), children: [
                          TextFormField(
                              controller: _name,
                              onChanged: _simpleRoutine
                                  ? (value) => setState(() {
                                        _routine.name = value;
                                        _changed();
                                      })
                                  : null,
                              maxLength: 160,
                              decoration: InputDecoration(
                                  labelText: (_simpleRoutine
                                          ? 'Routine name'
                                          : 'Plan name')
                                      .workoutTr(context)),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? (((('Enter a plan name')
                                      .workoutTr(context))))
                                  : null),
                          const SizedBox(height: 12),
                          if (!_simpleRoutine || _description.text.isNotEmpty)
                            TextFormField(
                                controller: _description,
                                maxLength: 5000,
                                minLines: 2,
                                maxLines: 4,
                                decoration: InputDecoration(
                                    labelText:
                                        (('Description')).workoutTr(context))),
                          const SizedBox(height: 16),
                          ..._visibleDays.asMap().entries.map((entry) {
                            final d = entry.value;
                            final i = entry.key;
                            return Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Icon(workoutRoutineIcons[
                                                    d.configuration['icon']] ??
                                                workoutRoutineIcons[
                                                    'strength']),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: WorkoutLabel(d.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium)),
                                            if (!_simpleRoutine)
                                              IconButton(
                                                  tooltip: (('Move day up'))
                                                      .workoutTr(context),
                                                  onPressed: i == 0
                                                      ? null
                                                      : () =>
                                                          _move(_days, i, -1),
                                                  icon: const Icon(Icons
                                                      .arrow_upward_rounded)),
                                            if (!_simpleRoutine)
                                              IconButton(
                                                  tooltip: (('Move day down'))
                                                      .workoutTr(context),
                                                  onPressed: i ==
                                                          _days.length - 1
                                                      ? null
                                                      : () =>
                                                          _move(_days, i, 1),
                                                  icon: const Icon(Icons
                                                      .arrow_downward_rounded)),
                                            IconButton(
                                                tooltip: (('Edit day'))
                                                    .workoutTr(context),
                                                onPressed: () => _day(day: d),
                                                icon: const Icon(
                                                    Icons.edit_outlined)),
                                            if (!_simpleRoutine)
                                              IconButton(
                                                  tooltip: (('Remove day'))
                                                      .workoutTr(context),
                                                  onPressed: () => setState(
                                                      () => _days.remove(d)),
                                                  icon: const Icon(
                                                      Icons.close_rounded))
                                          ]),
                                          if (!_simpleRoutine)
                                            WorkoutLabel(d.dayOfWeek == null
                                                ? 'Flexible'
                                                : WorkoutText.weekdays[
                                                    d.dayOfWeek! - 1]),
                                          ...d.exercises
                                              .asMap()
                                              .entries
                                              .map((row) {
                                            final e = row.value;
                                            final n = row.key;
                                            return Column(children: [
                                              ListTile(
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  title: WorkoutLabel(
                                                      e.exercise.name),
                                                  subtitle: WorkoutLabel(
                                                      '${e.sets} × ${e.exercise.isTimed ? '${e.durationSeconds} sec' : '${e.reps} reps'} · ${workoutValue(WorkoutService.displayWeight(e.weight ?? 0))} ${WorkoutService.unit} · ${e.restSeconds} sec rest${e.supersetGroup.isEmpty ? '' : '\nSuperset ${e.supersetGroup}'}'),
                                                  onTap: () =>
                                                      _exercise(d, existing: e),
                                                  trailing: IconButton(
                                                      tooltip:
                                                          (('Remove exercise'))
                                                              .workoutTr(
                                                                  context),
                                                      onPressed: () =>
                                                          setState(() {
                                                            d.exercises
                                                                .remove(e);
                                                            cleanupWorkoutSupersets(
                                                                d.exercises);
                                                            _changed();
                                                          }),
                                                      icon: const Icon(Icons
                                                          .close_rounded))),
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    if (n > 0)
                                                      IconButton(
                                                          tooltip: (e.supersetGroup
                                                                          .isNotEmpty &&
                                                                      e.supersetGroup ==
                                                                          d
                                                                              .exercises[n -
                                                                                  1]
                                                                              .supersetGroup
                                                                  ? 'Unlink superset'
                                                                  : 'Link previous exercise')
                                                              .workoutTr(
                                                                  context),
                                                          icon: Icon(e.supersetGroup
                                                                      .isNotEmpty &&
                                                                  e.supersetGroup ==
                                                                      d
                                                                          .exercises[n -
                                                                              1]
                                                                          .supersetGroup
                                                              ? Icons.link_off
                                                              : Icons.link),
                                                          onPressed:
                                                              () =>
                                                                  setState(() {
                                                                    final previous =
                                                                        d.exercises[
                                                                            n - 1];
                                                                    if (e.supersetGroup
                                                                            .isNotEmpty &&
                                                                        e.supersetGroup ==
                                                                            previous.supersetGroup) {
                                                                      e.supersetGroup =
                                                                          '';
                                                                    } else {
                                                                      final group = previous
                                                                              .supersetGroup
                                                                              .isEmpty
                                                                          ? 'group-${DateTime.now().microsecondsSinceEpoch}'
                                                                          : previous
                                                                              .supersetGroup;
                                                                      previous.supersetGroup =
                                                                          group;
                                                                      e.supersetGroup =
                                                                          group;
                                                                    }
                                                                    cleanupWorkoutSupersets(
                                                                        d.exercises);
                                                                    _changed();
                                                                  })),
                                                    IconButton(
                                                        tooltip:
                                                            (('Move exercise up'))
                                                                .workoutTr(
                                                                    context),
                                                        onPressed: n == 0
                                                            ? null
                                                            : () => _move(
                                                                d.exercises,
                                                                n,
                                                                -1),
                                                        icon: const Icon(Icons
                                                            .arrow_upward_rounded)),
                                                    IconButton(
                                                        tooltip:
                                                            (('Move exercise down'))
                                                                .workoutTr(
                                                                    context),
                                                        onPressed: n ==
                                                                d.exercises
                                                                        .length -
                                                                    1
                                                            ? null
                                                            : () => _move(
                                                                d.exercises,
                                                                n,
                                                                1),
                                                        icon: const Icon(Icons
                                                            .arrow_downward_rounded))
                                                  ])
                                            ]);
                                          }),
                                          OutlinedButton.icon(
                                              onPressed: () => _exercise(d),
                                              icon:
                                                  const Icon(Icons.add_rounded),
                                              label: const WorkoutLabel(
                                                  'Add exercise')),
                                          if (d.exercises.isNotEmpty)
                                            WorkoutMuscleCoverage(
                                                load: workoutMuscleCoverage(
                                                    d.exercises)),
                                        ])));
                          }),
                          if (!_simpleRoutine)
                            OutlinedButton.icon(
                                onPressed:
                                    _days.length >= 14 ? null : () => _day(),
                                icon: const Icon(Icons.add_rounded),
                                label: const WorkoutLabel('Add workout day')),
                          const SizedBox(height: 16),
                          if (_saving)
                            const Center(child: CircularProgressIndicator()),
                          if (_autosave) ...[
                            WorkoutLabel(_saveError != null
                                ? 'Changes could not be saved. Retry before leaving.'
                                : _saving
                                    ? 'Saving…'
                                    : _dirty
                                        ? 'Unsaved changes'
                                        : 'All changes saved'),
                            if (_saveError != null)
                              TextButton(
                                  onPressed: () => _persist('assigned'),
                                  child: const WorkoutLabel('Retry')),
                          ],
                          ElevatedButton(
                              onPressed: () => _save('assigned'),
                              child: WorkoutLabel(widget.personal
                                  ? _autosave
                                      ? 'Done'
                                      : 'Save routine'
                                  : 'Save and assign to client')),
                          if (!_autosave)
                            TextButton(
                                onPressed: () => _save('draft'),
                                child: const WorkoutLabel('Save draft')),
                          if (_autosave && _planID != null)
                            TextButton(
                                onPressed: _saving ? null : _delete,
                                child: const WorkoutLabel('Delete routine')),
                        ])))));
}

class _PrescriptionDialog extends StatefulWidget {
  final Exercise exercise;
  final WorkoutExercise? existing;
  final VoidCallback? onDelete;
  const _PrescriptionDialog(
      {required this.exercise, this.existing, this.onDelete});
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
  String _mode = 'reps';
  bool _bodyweight = false;
  Exercise get _effective =>
      widget.exercise.copyWith(type: _mode, isBodyweight: _bodyweight);
  bool _perSide = false;
  bool _excluded = false;
  String _effortScale = 'off';
  final _targetEffort = TextEditingController();
  final _speed = TextEditingController(text: '8');
  final _increment = TextEditingController(text: '2.5'),
      _minReps = TextEditingController(text: '8'),
      _bodyweightCeiling = TextEditingController(text: '30'),
      _bodyweightSets = TextEditingController(text: '6');
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _mode = e?.exercise.type ?? widget.exercise.type;
    _bodyweight = e?.exercise.isBodyweight ?? widget.exercise.isBodyweight;
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
    final heavy = ['upper legs', 'lower legs', 'back', 'hips', 'glutes']
        .contains(_effective.bodyPart);
    _increment.text = workoutValue(_effective.isTimed
        ? workoutNumber(e?.configuration['increment']) ?? 5
        : e?.configuration['increment'] != null
            ? WorkoutService.displayWeight(
                workoutNumber(e!.configuration['increment'])!)
            : WorkoutService.unit == 'lb'
                ? (heavy ? 10 : 5)
                : (heavy ? 5 : 2.5));
    _minReps.text = '${e?.configuration['minReps'] ?? 8}';
    _bodyweightCeiling.text =
        '${e?.configuration['bodyweightRepCeiling'] ?? 0}';
    _bodyweightSets.text = '${e?.configuration['maxBodyweightSets'] ?? 6}';
    _sets = TextEditingController(
        text: '${e?.sets ?? (_mode == 'cardio' ? 1 : 3)}');
    _reps = TextEditingController(text: '${e?.reps ?? 10}');
    _weight = TextEditingController(
        text: workoutValue(WorkoutService.displayWeight(e?.weight ?? 0)));
    _duration = TextEditingController(
        text: _mode == 'cardio'
            ? workoutValue((e?.durationSeconds ?? 1200) / 60)
            : '${e?.durationSeconds ?? 45}');
    _speed.text = '${e?.configuration['speedKmh'] ?? 8}';
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
      _speed,
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
          {bool whole = true, bool compact = false, String? caption}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FormField<double>(
              validator: (_) {
                final n = double.tryParse(c.text);
                return n == null ||
                        !n.isFinite ||
                        n < min ||
                        n > max ||
                        whole && n % 1 != 0
                    ? 'Enter a value from $min to $max'.workoutTr(context)
                    : null;
              },
              builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WorkoutLabel(caption ?? label,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        WorkoutNumberStepper(
                            compact: compact,
                            controller: c,
                            label: label,
                            min: min.toDouble(),
                            max: max.toDouble(),
                            step: c == _weight
                                ? 2.5
                                : c == _duration
                                    ? (_mode == 'cardio' ? 1 : 5)
                                    : c == _rest
                                        ? 5
                                        : c == _reps && _perSide
                                            ? 2
                                            : whole
                                                ? 1
                                                : .5,
                            onChanged: () =>
                                field.didChange(double.tryParse(c.text))),
                        if (field.errorText != null)
                          WorkoutLabel(field.errorText!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))
                      ])));
  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: SizedBox(
              height: (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom) *
                  .88,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WorkoutLabel(workoutExerciseTitle(widget.exercise.name),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Expanded(
                        child: SingleChildScrollView(
                            child: Form(
                                key: _form,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      WorkoutDemonstrationPanel(
                                          exercise: widget.exercise,
                                          compact: true),
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Wrap(spacing: 6, children: [
                                            Chip(
                                                label: WorkoutLabel(widget
                                                    .exercise.muscleGroup)),
                                            Chip(
                                                label: WorkoutLabel(
                                                    widget.exercise.equipment))
                                          ])),
                                      const SizedBox(height: 12),
                                      WorkoutSegments<String>(
                                          choices: const {
                                            'reps': 'Reps',
                                            'timed': 'Time',
                                            'cardio': 'Cardio'
                                          },
                                          selected: _mode,
                                          onChanged: (value) => setState(() {
                                                final previous = _mode;
                                                _mode = value;
                                                if (previous != _mode) {
                                                  if (_mode == 'cardio') {
                                                    _duration.text = workoutValue(
                                                        (double.tryParse(
                                                                    _duration
                                                                        .text) ??
                                                                1200) /
                                                            60);
                                                  } else if (previous ==
                                                      'cardio') {
                                                    _duration.text =
                                                        '${((double.tryParse(_duration.text) ?? 20) * 60).round()}';
                                                  }
                                                }
                                                _progression = 'inherit';
                                                if (_mode != 'reps') {
                                                  _perSide = false;
                                                }
                                                _increment.text = _mode ==
                                                        'reps'
                                                    ? (WorkoutService.unit ==
                                                            'lb'
                                                        ? '5'
                                                        : '2.5')
                                                    : '5';
                                              })),
                                      const SizedBox(height: 16),
                                      Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                                child: _number(
                                                    _sets, 'Sets', 1, 30,
                                                    compact: true)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: _effective.isTimed
                                                    ? _number(
                                                        _duration,
                                                        _mode == 'cardio'
                                                            ? 'Duration (min)'
                                                            : 'Target duration (sec)',
                                                        _mode == 'cardio'
                                                            ? 1 / 60
                                                            : 1,
                                                        _mode == 'cardio'
                                                            ? 1440
                                                            : 86400,
                                                        whole:
                                                            _mode != 'cardio',
                                                        compact: true,
                                                        caption:
                                                            _mode == 'cardio'
                                                                ? 'Minutes'
                                                                : 'Seconds')
                                                    : _number(
                                                        _reps,
                                                        'Target repetitions',
                                                        1,
                                                        1000,
                                                        compact: true,
                                                        caption: 'Reps')),
                                            if (_mode == 'cardio' ||
                                                _mode == 'timed' ||
                                                !_bodyweight) ...[
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: _mode == 'cardio'
                                                      ? _number(
                                                          _speed,
                                                          'Speed (km/h)',
                                                          0,
                                                          100,
                                                          whole: false,
                                                          compact: true)
                                                      : _number(
                                                          _weight,
                                                          'Target weight (${WorkoutService.unit})',
                                                          0,
                                                          WorkoutService
                                                              .displayWeight(
                                                                  2000),
                                                          whole: false,
                                                          compact: true,
                                                          caption:
                                                              'Weight (${WorkoutService.unit})')),
                                            ],
                                          ]),
                                      if (_perSide && !_effective.isTimed)
                                        WorkoutLabel(
                                            '${workoutValue((double.tryParse(_reps.text) ?? 0) / 2)} per side · log the total'),
                                      if (_mode != 'cardio')
                                        SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const WorkoutLabel(
                                                'Bodyweight'),
                                            value: _bodyweight,
                                            onChanged: (value) => setState(() {
                                                  _bodyweight = value;
                                                  if (value) _weight.text = '0';
                                                })),
                                      if (!_effective.isTimed)
                                        SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const WorkoutLabel(
                                                'Repetitions per side'),
                                            value: _perSide,
                                            onChanged: (v) => setState(() {
                                                  _perSide = v;
                                                  if (v) {
                                                    _reps.text =
                                                        '${((int.tryParse(_reps.text) ?? 10) / 2).ceil() * 2}';
                                                  }
                                                })),
                                      if (_bodyweight && _mode != 'cardio')
                                        _number(
                                            _weight,
                                            _effective.isBodyweight
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
                                              labelText: (('Progression'))
                                                  .workoutTr(context)),
                                          items: [
                                            const DropdownMenuItem(
                                                value: 'inherit',
                                                child: WorkoutLabel(
                                                    'Follow routine progression')),
                                            const DropdownMenuItem(
                                                value: 'off',
                                                child: WorkoutLabel(
                                                    'Off — prescribed targets')),
                                            if (_effective.isTimed)
                                              const DropdownMenuItem(
                                                  value: 'time',
                                                  child: WorkoutLabel(
                                                      'Increase time')),
                                            if (!_effective.isTimed) ...const [
                                              DropdownMenuItem(
                                                  value: 'linear',
                                                  child:
                                                      WorkoutLabel('Linear')),
                                              DropdownMenuItem(
                                                  value: 'double',
                                                  child: WorkoutLabel(
                                                      'Double progression')),
                                              DropdownMenuItem(
                                                  value: 'greyskull',
                                                  child: WorkoutLabel(
                                                      'Greyskull · AMRAP'))
                                            ]
                                          ],
                                          onChanged: (v) => setState(
                                              () => _progression = v!)),
                                      if (_progression != 'off')
                                        _number(
                                            _increment,
                                            _effective.isTimed
                                                ? 'Time increment (sec)'
                                                : 'Load increment (${WorkoutService.unit})',
                                            0.1,
                                            100,
                                            whole: false),
                                      if (_progression == 'double')
                                        _number(_minReps, 'Minimum repetitions',
                                            1, 1000),
                                      if (_effective.isBodyweight &&
                                          !_effective.isTimed &&
                                          _progression != 'off') ...[
                                        _number(
                                            _bodyweightCeiling,
                                            'Bodyweight repetition ceiling (0 = off)',
                                            0,
                                            1000),
                                        _number(_bodyweightSets,
                                            'Maximum bodyweight sets', 1, 30),
                                      ],
                                      DropdownButtonFormField<String>(
                                          initialValue: _effortScale,
                                          decoration: InputDecoration(
                                              labelText:
                                                  'Target effort (optional)'
                                                      .workoutTr(context)),
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'off',
                                                child: WorkoutLabel('Off')),
                                            DropdownMenuItem(
                                                value: 'rpe',
                                                child: WorkoutLabel('RPE')),
                                            DropdownMenuItem(
                                                value: 'rir',
                                                child: WorkoutLabel('RIR'))
                                          ],
                                          onChanged: (v) => setState(
                                              () => _effortScale = v!)),
                                      if (_effortScale != 'off')
                                        _number(
                                            _targetEffort,
                                            _effortScale == 'rpe'
                                                ? 'Target RPE'
                                                : 'Target RIR',
                                            _effortScale == 'rpe' ? 1 : 0,
                                            10,
                                            whole: false),
                                      SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const WorkoutLabel(
                                              'Exclude from automatic progression'),
                                          value: _excluded,
                                          onChanged: (v) =>
                                              setState(() => _excluded = v)),
                                      TextFormField(
                                          controller: _group,
                                          maxLength: 64,
                                          decoration: InputDecoration(
                                              labelText:
                                                  (('Superset group (optional)'))
                                                      .workoutTr(context),
                                              helperText:
                                                  (('Use the same group for adjacent exercises.'))
                                                      .workoutTr(context))),
                                      TextFormField(
                                          controller: _notes,
                                          maxLength: 2000,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                              labelText: (('Coach notes'))
                                                  .workoutTr(context))),
                                    ])))),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const WorkoutLabel(WorkoutText.cancel)),
                      ElevatedButton(
                          onPressed: () {
                            if (!_form.currentState!.validate()) return;
                            if (_progression == 'double' &&
                                int.parse(_minReps.text) >
                                    int.parse(_reps.text)) {
                              workoutError(
                                  context,
                                  const WorkoutApiException(
                                      'invalid_target', 400));
                              return;
                            }
                            Navigator.pop(
                                context,
                                WorkoutExercise(
                                    id: widget.existing?.id ?? 0,
                                    exercise: _effective,
                                    sets: int.parse(_sets.text),
                                    reps: _effective.isTimed
                                        ? null
                                        : _perSide
                                            ? (int.parse(_reps.text) / 2)
                                                    .ceil() *
                                                2
                                            : int.parse(_reps.text),
                                    durationSeconds: _effective.isTimed
                                        ? _mode == 'cardio'
                                            ? (double.parse(_duration.text) *
                                                    60)
                                                .round()
                                            : int.parse(_duration.text)
                                        : null,
                                    weight: _mode == 'cardio'
                                        ? 0
                                        : widget.existing?.weight != null &&
                                                _weight.text ==
                                                    workoutValue(WorkoutService
                                                        .displayWeight(widget
                                                            .existing!.weight!))
                                            ? widget.existing!.weight
                                            : WorkoutService.storedWeight(
                                                double.parse(_weight.text)),
                                    restSeconds: int.parse(_rest.text),
                                    notes: _notes.text.trim(),
                                    supersetGroup: _group.text.trim(),
                                    configuration: {
                                      ...?widget.existing?.configuration,
                                      'speedKmh': _mode == 'cardio'
                                          ? double.parse(_speed.text)
                                          : null,
                                      'mode': _mode,
                                      'bodyweight': _bodyweight,
                                      'progression': _progression,
                                      'increment': _effective.isTimed
                                          ? double.parse(_increment.text)
                                          : WorkoutService.storedWeight(
                                              double.parse(_increment.text)),
                                      'minReps': _progression == 'double'
                                          ? int.parse(_minReps.text)
                                          : null,
                                      'perSide':
                                          !_effective.isTimed && _perSide,
                                      'bodyweightRepCeiling':
                                          int.parse(_bodyweightCeiling.text),
                                      'maxBodyweightSets':
                                          int.parse(_bodyweightSets.text),
                                      'excludeFromProgression': _excluded,
                                      'targetRpe': _effortScale == 'rpe'
                                          ? double.parse(_targetEffort.text)
                                          : null,
                                      'targetRir': _effortScale == 'rir'
                                          ? double.parse(_targetEffort.text)
                                          : null
                                    }));
                          },
                          child: const WorkoutLabel(WorkoutText.save))
                    ]),
                    if (widget.onDelete != null)
                      TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDelete!();
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const WorkoutLabel('Remove exercise'))
                  ]))));
}
