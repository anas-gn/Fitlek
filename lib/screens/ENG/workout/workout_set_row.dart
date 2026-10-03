import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'workout_tools.dart';

// Compact native set-entry grid. Controllers keep typed values across parent ticks.
class WorkoutSetRow extends StatefulWidget {
  final WorkoutExercise exercise;
  final int number;
  final WorkoutSet? saved, previous;
  final bool busy;
  final Future<bool> Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? draft;
  final void Function(Map<String, dynamic>)? onDraft;
  final VoidCallback onUndo, onDetails;
  const WorkoutSetRow(
      {super.key,
      required this.exercise,
      required this.number,
      this.saved,
      this.previous,
      required this.busy,
      required this.onSave,
      this.draft,
      this.onDraft,
      required this.onUndo,
      required this.onDetails});
  @override
  State<WorkoutSetRow> createState() => _WorkoutSetRowState();
}

class _WorkoutSetRowState extends State<WorkoutSetRow> {
  late final TextEditingController _load, _count, _effort;
  bool _dirty = false;
  bool _loadDirty = false;
  bool _addedLoad = false;
  bool get _showLoad =>
      widget.exercise.supportsLoad &&
      (widget.exercise.hasPrescribedLoad ||
          _addedLoad ||
          (widget.saved?.weight ?? 0) > 0);
  @override
  void initState() {
    super.initState();
    _load = TextEditingController();
    _count = TextEditingController();
    _effort = TextEditingController(
        text: WorkoutService.preferences['effort'] == 'rpe'
            ? workoutValue(widget.saved?.rpe).replaceAll('—', '')
            : '${widget.saved?.rir ?? ''}');
    _fill();
    if (widget.draft != null) {
      _load.text = widget.draft!['load'] ?? _load.text;
      _count.text = widget.draft!['count'] ?? _count.text;
      _effort.text = widget.draft!['effort'] ?? _effort.text;
      _dirty = true;
      _loadDirty = widget.draft!['loadDirty'] == true;
      _addedLoad = widget.draft!['addedLoad'] == true;
    }
  }

  void _fill() {
    final e = widget.exercise;
    _load.text = workoutValue(WorkoutService.displayWeight(
        widget.saved?.weight ?? e.weight ?? widget.previous?.weight ?? 0));
    _count.text =
        '${e.exercise.isTimed ? widget.saved?.durationSeconds ?? e.durationSeconds ?? 30 : widget.saved?.reps ?? e.reps ?? 10}';
    _effort.text = WorkoutService.preferences['effort'] == 'rpe'
        ? workoutValue(widget.saved?.rpe).replaceAll('—', '')
        : '${widget.saved?.rir ?? ''}';
  }

  @override
  void didUpdateWidget(covariant WorkoutSetRow old) {
    super.didUpdateWidget(old);
    if (!_dirty &&
        (old.saved != widget.saved || old.exercise != widget.exercise)) {
      _fill();
    }
  }

  @override
  void dispose() {
    _load.dispose();
    _count.dispose();
    _effort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.exercise.configuration['perSide'] == true) {
      widget.onDetails();
      return;
    }
    final w = double.tryParse(_load.text.replaceAll(',', '.')),
        count = int.tryParse(_count.text);
    if (w == null ||
        !w.isFinite ||
        w < 0 ||
        WorkoutService.storedWeight(w) > 2000 ||
        count == null ||
        count < 1 ||
        count > (widget.exercise.exercise.isTimed ? 86400 : 1000)) {
      workoutError(context, const WorkoutApiException('invalid_set', 400));
      return;
    }
    final effort = _effort.text.isEmpty ? null : double.tryParse(_effort.text);
    final scale = WorkoutService.preferences['effort'];
    if (_effort.text.isNotEmpty &&
        (effort == null ||
            !effort.isFinite ||
            effort < 0 ||
            effort > 10 ||
            scale == 'rpe' && effort < 1 ||
            scale == 'rir' && effort % 1 != 0)) {
      workoutError(context, const WorkoutApiException('invalid_effort', 400));
      return;
    }
    final saved = await widget.onSave({
      'workoutExerciseID': widget.exercise.id,
      'setNumber': widget.number,
      'weight': _loadDirty
          ? WorkoutService.storedWeight(w)
          : widget.saved?.weight ??
              widget.exercise.weight ??
              widget.previous?.weight ??
              0,
      'reps': widget.exercise.exercise.isTimed ? null : count,
      'durationSeconds': widget.exercise.exercise.isTimed ? count : null,
      'rpe': scale == 'rpe'
          ? effort
          : scale == 'rir'
              ? null
              : widget.saved?.rpe,
      'rir': scale == 'rir'
          ? effort?.toInt()
          : scale == 'rpe'
              ? null
              : widget.saved?.rir,
      'details': widget.saved?.details ?? {}
    });
    if (mounted && saved) {
      setState(() {
        _dirty = false;
        _loadDirty = false;
      });
    }
  }

  Widget _input(TextEditingController c, String label) => Expanded(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
              controller: c,
              onSubmitted: (_) {
                if (!widget.busy) _save();
              },
              enabled: !widget.busy,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  labelText: ((label)).workoutTr(context),
                  floatingLabelBehavior: FloatingLabelBehavior.never),
              onChanged: (_) => setState(() {
                    _dirty = true;
                    if (c == _load) _loadDirty = true;
                    widget.onDraft?.call({
                      'load': _load.text,
                      'count': _count.text,
                      'effort': _effort.text,
                      'loadDirty': _loadDirty,
                      'addedLoad': _addedLoad
                    });
                  }))));
  @override
  Widget build(BuildContext context) {
    final timed = widget.exercise.exercise.isTimed,
        done = widget.saved != null,
        pending = widget.saved?.details['pending'] == true;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(
              width: 36,
              child: TextButton(
                  onPressed: widget.busy ? null : widget.onDetails,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: WorkoutLabel(
                      widget.saved?.isWarmup == true ? 'W' : '${widget.number}',
                      style: const TextStyle(fontSize: 15)))),
          if (_showLoad) _input(_load, WorkoutService.unit),
          if (widget.exercise.exercise.isBodyweight && !_showLoad)
            IconButton(
                tooltip: 'Add external load'.workoutTr(context),
                onPressed: widget.busy
                    ? null
                    : () => setState(() {
                          _addedLoad = true;
                          widget.onDraft?.call({
                            'load': _load.text,
                            'count': _count.text,
                            'effort': _effort.text,
                            'loadDirty': _loadDirty,
                            'addedLoad': true
                          });
                        }),
                icon: const Icon(Icons.add_rounded, size: 18)),
          _input(_count, timed ? 'SEC' : 'REPS'),
          if (['rpe', 'rir'].contains(WorkoutService.preferences['effort']))
            _input(_effort,
                '${WorkoutService.preferences['effort']}'.toUpperCase()),
          SizedBox(
              width: 48,
              child: IconButton(
                  tooltip: ((done && !_dirty ? 'Undo set' : 'Complete set'))
                      .workoutTr(context),
                  onPressed: widget.busy
                      ? null
                      : done && !_dirty
                          ? widget.onUndo
                          : _save,
                  style: IconButton.styleFrom(
                      backgroundColor: done
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                      foregroundColor: done
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  icon: Icon(pending
                      ? Icons.cloud_upload_outlined
                      : done && !_dirty
                          ? Icons.check_rounded
                          : Icons.check_outlined)))
        ]));
  }
}

class WorkoutNumberStepper extends StatefulWidget {
  final TextEditingController controller;
  final double step, min, max;
  final String label;
  final VoidCallback onChanged;
  const WorkoutNumberStepper(
      {super.key,
      required this.controller,
      required this.label,
      required this.onChanged,
      this.step = 1,
      this.min = 0,
      this.max = 2000});
  @override
  State<WorkoutNumberStepper> createState() => _WorkoutNumberStepperState();
}

class _WorkoutNumberStepperState extends State<WorkoutNumberStepper> {
  Timer? _repeat;
  void _step(int direction) {
    final value =
        double.tryParse(widget.controller.text.replaceAll(',', '.')) ?? 0;
    widget.controller.text = workoutValue(
        (value + direction * widget.step).clamp(widget.min, widget.max));
    widget.onChanged();
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  Widget _button(int direction) => GestureDetector(
      onLongPressStart: (_) {
        _step(direction);
        _repeat = Timer.periodic(
            const Duration(milliseconds: 120), (_) => _step(direction));
      },
      onLongPressEnd: (_) => _repeat?.cancel(),
      child: IconButton(
          tooltip:
              (('${direction > 0 ? 'Increase' : 'Decrease'} ${widget.label}'))
                  .workoutTr(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 44),
          onPressed: () => _step(direction),
          icon: Icon(direction > 0 ? Icons.add : Icons.remove, size: 16)));
  @override
  Widget build(BuildContext context) => Row(children: [
        _button(-1),
        Expanded(
            child: TextField(
                controller: widget.controller,
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: ((widget.label)).workoutTr(context)),
                onChanged: (_) => widget.onChanged())),
        _button(1)
      ]);
}

class WorkoutRichSetEditor extends StatefulWidget {
  final WorkoutExercise exercise;
  final WorkoutSet? saved;
  final int number;
  final bool warmup;
  const WorkoutRichSetEditor(
      {super.key,
      required this.exercise,
      required this.number,
      this.saved,
      this.warmup = false});
  @override
  State<WorkoutRichSetEditor> createState() => _WorkoutRichSetEditorState();
}

class _WorkoutRichSetEditorState extends State<WorkoutRichSetEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _weight,
      _reps,
      _duration,
      _rpe,
      _rir,
      _notes,
      _leftWeight,
      _leftReps,
      _rightWeight,
      _rightReps,
      _distance;
  String _type = 'straight';
  bool _perSide = false;
  final Map<TextEditingController, double> _originalLoads = {};
  final List<
          (TextEditingController, TextEditingController, TextEditingController)>
      _segments = [];
  @override
  void initState() {
    super.initState();
    final s = widget.saved, e = widget.exercise;
    _weight = TextEditingController(
        text: workoutValue(WorkoutService.displayWeight(s?.weight ??
            (widget.warmup ? (e.weight ?? 0) * 0.5 : e.weight ?? 0))));
    _reps = TextEditingController(
        text: '${s?.reps ?? (widget.warmup ? 5 : e.reps ?? 10)}');
    _duration = TextEditingController(
        text: '${s?.durationSeconds ?? e.durationSeconds ?? 30}');
    _rpe =
        TextEditingController(text: s?.rpe == null ? '' : workoutValue(s!.rpe));
    _rir = TextEditingController(text: s?.rir == null ? '' : '${s!.rir}');
    _notes = TextEditingController(text: s?.details['notes'] ?? '');
    _distance = TextEditingController(
        text: s?.details['distanceMeters'] == null
            ? ''
            : '${s!.details['distanceMeters']}');
    _perSide =
        e.configuration['perSide'] == true || s?.details['sides'] != null;
    final sides = Map<String, dynamic>.from(s?.details['sides'] ?? {}),
        left = Map<String, dynamic>.from(sides['left'] ?? {}),
        right = Map<String, dynamic>.from(sides['right'] ?? {});
    _leftWeight = TextEditingController(
        text: workoutValue(WorkoutService.displayWeight(
            workoutNumber(left['weight']) ?? e.weight ?? 0)));
    _rightWeight = TextEditingController(
        text: workoutValue(WorkoutService.displayWeight(
            workoutNumber(right['weight']) ?? e.weight ?? 0)));
    _leftReps = TextEditingController(text: '${left['reps'] ?? e.reps ?? 10}');
    _rightReps =
        TextEditingController(text: '${right['reps'] ?? e.reps ?? 10}');
    _originalLoads[_weight] =
        s?.weight ?? (widget.warmup ? (e.weight ?? 0) * 0.5 : e.weight ?? 0);
    _originalLoads[_leftWeight] =
        workoutNumber(left['weight']) ?? e.weight ?? 0;
    _originalLoads[_rightWeight] =
        workoutNumber(right['weight']) ?? e.weight ?? 0;
    _type = s?.details['type'] ?? 'straight';
    for (final v in workoutRows(s?.details['segments'])) {
      _segments.add((
        TextEditingController(
            text: workoutValue(
                WorkoutService.displayWeight(workoutNumber(v['weight']) ?? 0))),
        TextEditingController(text: '${v['reps']}'),
        TextEditingController(text: '${v['restSeconds'] ?? 0}')
      ));
      _originalLoads[_segments.last.$1] = workoutNumber(v['weight']) ?? 0;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _weight,
      _reps,
      _duration,
      _rpe,
      _rir,
      _notes,
      _leftWeight,
      _leftReps,
      _rightWeight,
      _rightReps,
      _distance
    ]) {
      c.dispose();
    }
    for (final s in _segments) {
      s.$1.dispose();
      s.$2.dispose();
      s.$3.dispose();
    }
    super.dispose();
  }

  double _storedLoad(TextEditingController c) {
    final old = _originalLoads[c];
    if (old != null &&
        c.text == workoutValue(WorkoutService.displayWeight(old))) {
      return old;
    }
    return WorkoutService.storedWeight(_n(c));
  }

  double _n(TextEditingController c) =>
      double.parse(c.text.replaceAll(',', '.'));
  Widget _field(TextEditingController c, String title,
          {double min = 0,
          double max = 2000,
          bool whole = false,
          bool optional = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              controller: c,
              keyboardType: TextInputType.numberWithOptions(decimal: !whole),
              decoration:
                  InputDecoration(labelText: ((title)).workoutTr(context)),
              validator: (v) {
                if ((v ?? '').isEmpty && optional) return null;
                final n = double.tryParse((v ?? '').replaceAll(
                    ((((',').workoutTr(context)))),
                    (((('.').workoutTr(context))))));
                return n == null ||
                        !n.isFinite ||
                        n < min ||
                        n > max ||
                        whole && n % 1 != 0
                    ? 'Enter a value from $min to $max'.workoutTr(context)
                    : null;
              }));
  void _save() {
    if (!_form.currentState!.validate()) return;
    final timed = widget.exercise.exercise.isTimed;
    if (_rpe.text.isNotEmpty && _rir.text.isNotEmpty) {
      workoutError(context, const WorkoutApiException('invalid_effort', 400));
      return;
    }
    final weight = _storedLoad(_weight);
    final sides = _perSide
        ? {
            'left': {
              'weight': _storedLoad(_leftWeight),
              'reps': _n(_leftReps).toInt()
            },
            'right': {
              'weight': _storedLoad(_rightWeight),
              'reps': _n(_rightReps).toInt()
            }
          }
        : null;
    Navigator.pop(context, {
      'workoutExerciseID': widget.exercise.id,
      'setNumber': widget.number,
      'weight': sides == null
          ? weight
          : (_storedLoad(_leftWeight) > _storedLoad(_rightWeight)
              ? _storedLoad(_leftWeight)
              : _storedLoad(_rightWeight)),
      'reps': timed
          ? null
          : _perSide
              ? _n(_leftReps).toInt() + _n(_rightReps).toInt()
              : _n(_reps).toInt(),
      'durationSeconds': timed ? _n(_duration).toInt() : null,
      'rpe': _rpe.text.isEmpty ? null : _n(_rpe),
      'rir': _rir.text.isEmpty ? null : _n(_rir).toInt(),
      'details': {
        'phase': widget.warmup ? 'warmup' : 'work',
        'type': _type,
        'notes': _notes.text,
        'distanceMeters': _distance.text.isEmpty ? null : _n(_distance),
        if (sides != null) 'sides': sides,
        if (_type != 'straight')
          'segments': _segments
              .map((s) => {
                    'weight': _storedLoad(s.$1),
                    'reps': _n(s.$2).toInt(),
                    'restSeconds': _n(s.$3).toInt()
                  })
              .toList()
      }
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SafeArea(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.8),
              child: Form(
                  key: _form,
                  child: ListView(shrinkWrap: true, children: [
                    WorkoutLabel(
                        widget.warmup ? 'Warm-up' : 'Set ${widget.number}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                    WorkoutLabel(widget.exercise.exercise.name),
                    const SizedBox(height: 16),
                    if (!widget.exercise.exercise.isTimed)
                      WorkoutNumberStepper(
                          controller: _reps,
                          label: 'Repetitions',
                          min: 1,
                          max: 1000,
                          onChanged: () => setState(() {})),
                    if (widget.exercise.supportsLoad && !_perSide) ...[
                      _field(
                          _weight,
                          widget.exercise.exercise.isBodyweight
                              ? 'Added weight (${WorkoutService.unit})'
                              : 'Weight (${WorkoutService.unit})',
                          max: WorkoutService.displayWeight(2000)),
                      TextButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              WorkoutRoute(
                                  builder: (_) => WorkoutToolsScreen(
                                      initialWeight: _storedLoad(_weight)))),
                          icon: const Icon(Icons.calculate_outlined),
                          label: const WorkoutLabel('Plate calculator')),
                      if (!widget.exercise.exercise.isTimed)
                        _field(_reps, 'Repetitions',
                            min: 1, max: 1000, whole: true)
                    ],
                    if (_perSide) ...[
                      _field(_leftWeight, 'Left load (${WorkoutService.unit})'),
                      _field(_leftReps, 'Left repetitions',
                          min: 1, max: 1000, whole: true),
                      _field(
                          _rightWeight, 'Right load (${WorkoutService.unit})'),
                      _field(_rightReps, 'Right repetitions',
                          min: 1, max: 1000, whole: true)
                    ],
                    if (widget.exercise.exercise.isTimed)
                      _field(_duration, 'Duration (sec)',
                          min: 1, max: 86400, whole: true),
                    if (widget.exercise.exercise.type == 'cardio')
                      _field(_distance, 'Distance (metres)',
                          max: 1000000, optional: true),
                    _field(_rpe, 'RPE (optional)',
                        min: 1, max: 10, optional: true),
                    _field(_rir, 'RIR (optional)',
                        max: 10, whole: true, optional: true),
                    if (!widget.exercise.exercise.isTimed) ...[
                      DropdownButtonFormField<String>(
                          initialValue: _type,
                          decoration: InputDecoration(
                              labelText: (('Set type')).workoutTr(context)),
                          items: const [
                            DropdownMenuItem(
                                value: 'straight',
                                child: WorkoutLabel('Straight set')),
                            DropdownMenuItem(
                                value: 'dropset',
                                child: WorkoutLabel('Drop set')),
                            DropdownMenuItem(
                                value: 'restpause',
                                child: WorkoutLabel('Rest-pause'))
                          ],
                          onChanged: (v) => setState(() => _type = v!)),
                      const SizedBox(height: 12),
                      if (_type != 'straight') ...[
                        for (final s in _segments)
                          Row(children: [
                            Expanded(
                                child: _field(
                                    s.$1, 'Load (${WorkoutService.unit})')),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _field(s.$2, 'Reps',
                                    min: 1, max: 1000, whole: true)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _field(s.$3, 'Rest (sec)',
                                    max: 3600, whole: true))
                          ]),
                        TextButton.icon(
                            onPressed: () => setState(() => _segments.add((
                                  TextEditingController(
                                      text: workoutValue(_n(_weight) * 0.8)),
                                  TextEditingController(text: '5'),
                                  TextEditingController(
                                      text: _type == 'restpause'
                                          ? '${WorkoutService.preferences['restPauseSeconds'] ?? 15}'
                                          : '0')
                                ))),
                            icon: const Icon(Icons.add),
                            label: WorkoutLabel(_type == 'restpause'
                                ? 'Add burst'
                                : 'Add drop'))
                      ]
                    ],
                    TextFormField(
                        controller: _notes,
                        maxLength: 2000,
                        maxLines: 2,
                        decoration: InputDecoration(
                            labelText: (('Set notes')).workoutTr(context))),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: _save, child: const WorkoutLabel('Save set'))
                  ])))));
}
