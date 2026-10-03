import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import '../../../services/workout_recovery.dart';
import '../../../services/workout_timer.dart';
import '../../../services/apiService.dart';
import '../../../services/notification_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'workout_set_row.dart';
import 'workout_media.dart';
import 'package:flutter/services.dart';
import 'workout_ui.dart';
import 'exercise_library.dart';

// Round-robin sets for contiguous supersets, straight sets for other exercises.
List<(WorkoutExercise, int, bool)> workoutSequence(
    List<WorkoutExercise> exercises) {
  final result = <(WorkoutExercise, int, bool)>[];
  for (int i = 0; i < exercises.length;) {
    final group = <WorkoutExercise>[exercises[i++]];
    if (group.first.supersetGroup.isNotEmpty) {
      while (i < exercises.length &&
          exercises[i].supersetGroup == group.first.supersetGroup) {
        group.add(exercises[i++]);
      }
    }
    final maxSets = group.map((e) => e.sets).reduce((a, b) => a > b ? a : b);
    for (int round = 1; round <= maxSets; round++) {
      final members = group.where((e) => e.sets >= round).toList();
      for (int j = 0; j < members.length; j++) {
        result.add((members[j], round, j == members.length - 1));
      }
    }
  }
  return result;
}

class ActiveWorkoutScreen extends StatefulWidget {
  final int sessionID;
  const ActiveWorkoutScreen({super.key, required this.sessionID});
  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  WorkoutSession? _session;
  Object? _error;
  bool _loading = true, _saving = false;
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController(),
      _reps = TextEditingController(),
      _duration = TextEditingController(),
      _effort = TextEditingController();
  final _notes = TextEditingController();
  final _workWatch = PersistentWorkoutTimer();
  bool _workAlerted = false;
  double? _prefilledWeight;
  bool _addedLoad = false;
  Timer? _ticker;
  bool _workRunning = false;
  int _workSeconds = 0, _restPausedSeconds = 0;
  DateTime? _restUntil;
  String _scale = 'off';
  int _index = 0;
  String _view = WorkoutService.preferences['view'] ?? 'guided';
  bool _recovery = false;
  bool _allowLeave = false;
  int _pending = 0;
  Timer? _draftTimer;
  Map<String, dynamic> _rowDrafts = {};
  int _timerEvent = 0;
  List<(WorkoutExercise, int, bool)> get _sequence =>
      workoutSequence(_session?.exercises ?? []);
  int get _restSeconds => _restUntil == null
      ? _restPausedSeconds
      : (_restUntil!.difference(DateTime.now()).inMilliseconds / 1000)
          .ceil()
          .clamp(0, 86400);
  bool get _resting => _restSeconds > 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.restControlsSessionID = widget.sessionID;
    NotificationService.instance.restAction
        .addListener(_notificationTimerAction);
    if (WorkoutService.preferences['keepAwake'] == true) {
      WakelockPlus.enable().catchError((_) {});
    }
    _load();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final hadRest = _restUntil != null;
      if (_workRunning || hadRest) {
        setState(() {
          _workSeconds = _workWatch.elapsed.inSeconds;
          if (_workRunning &&
              !_workAlerted &&
              _index < _sequence.length &&
              _sequence[_index].$1.exercise.isTimed &&
              _workSeconds >= (_sequence[_index].$1.durationSeconds ?? 30)) {
            _workAlerted = true;
            if (WorkoutService.preferences['timerVibration'] == true) {
              HapticFeedback.mediumImpact();
            }
            if (WorkoutService.preferences['timerSound'] == true) {
              SystemSound.play(SystemSoundType.alert);
            }
          }
          if (hadRest && _restSeconds == 0) {
            _restUntil = null;
            if (WorkoutService.preferences['timerVibration'] == true) {
              HapticFeedback.mediumImpact();
            }
            if (WorkoutService.preferences['timerSound'] == true) {
              SystemSound.play(SystemSoundType.alert);
            }
            if (WorkoutService.preferences['timerFlash'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  content: const WorkoutLabel('Rest complete')));
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _draftTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.restControlsSessionID = null;
    NotificationService.instance.restAction
        .removeListener(_notificationTimerAction);
    if (WorkoutService.preferences['keepAwake'] == true) {
      WakelockPlus.disable().catchError((_) {});
    }
    for (final c in [_weight, _reps, _duration, _effort, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _done(WorkoutExercise e, int number) => _session!.sets.any((s) =>
      s.workoutExerciseID == e.id && s.setNumber == number && !s.isWarmup);
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _recovery = await ApiService.getUserData() != null;
      final raw = _recovery
          ? await WorkoutRecovery.session(widget.sessionID)
          : await WorkoutService.get('/sessions/${widget.sessionID}');
      final session = WorkoutSession.fromJson(raw);
      final recovery = _recovery
          ? await WorkoutRecovery.read(widget.sessionID)
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _session = session;
        _notes.text = session.notes;
        _index = 0;
      });
      if (_recovery) await _overlayPending();
      final seq = _sequence;
      while (_index < seq.length && _done(seq[_index].$1, seq[_index].$2)) {
        _index++;
      }
      _prefill();
      final draft = Map<String, dynamic>.from(recovery['draft'] ?? {});
      _rowDrafts = Map<String, dynamic>.from(draft['rows'] ?? {});
      if (draft.isNotEmpty) {
        _notes.text = draft['notes'] ?? session.notes;
        _restUntil = DateTime.tryParse(draft['restUntil'] ?? '');
        _restPausedSeconds = workoutInt(draft['restPausedSeconds']);
        if (draft['index'] == _index) {
          _weight.text = draft['weight'] ?? _weight.text;
          _reps.text = draft['reps'] ?? _reps.text;
          _duration.text = draft['duration'] ?? _duration.text;
          _effort.text = draft['effort'] ?? '';
          _scale = draft['scale'] ?? _scale;
          _addedLoad = draft['addedLoad'] == true || _addedLoad;
          _workWatch
              .restore(Map<String, dynamic>.from(draft['workTimer'] ?? {}));
          _workRunning = _workWatch.isRunning;
          _workSeconds = _workWatch.elapsed.inSeconds;
        }
      }
      _notificationTimerAction();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _overlayPending() async {
    final data = await WorkoutRecovery.read(widget.sessionID),
        outbox = Map<String, dynamic>.from(
            (await WorkoutRecovery.read(widget.sessionID))['outbox'] ?? {});
    final raw = Map<String, dynamic>.from(data['session'] ?? {});
    if (raw.isEmpty) return;
    final sets = workoutRows(raw['sets']);
    for (final v in outbox.values) {
      final row = Map<String, dynamic>.from(v);
      sets.removeWhere((s) =>
          s['workoutExerciseID'] == row['workoutExerciseID'] &&
          s['setNumber'] == row['setNumber']);
      row['details'] = {
        ...Map<String, dynamic>.from(row['details'] ?? {}),
        'pending': true
      };
      sets.add(row);
    }
    raw['sets'] = sets;
    raw['offline'] = _session?.offline == true;
    if (mounted) {
      setState(() {
        _pending = outbox.length;
        _session = WorkoutSession.fromJson(raw);
      });
    }
  }

  void _remember({bool immediate = false}) {
    if (!_recovery) return;
    _draftTimer?.cancel();
    final draft = {
      'rows': _rowDrafts,
      'index': _index,
      'weight': _weight.text,
      'reps': _reps.text,
      'duration': _duration.text,
      'effort': _effort.text,
      'scale': _scale,
      'addedLoad': _addedLoad,
      'workTimer': _workWatch.toJson(),
      'notes': _notes.text,
      'restUntil': _restUntil?.toIso8601String(),
      'restPausedSeconds': _restPausedSeconds
    };
    if (immediate) {
      WorkoutRecovery.draft(widget.sessionID, draft).catchError((_) {});
    } else {
      _draftTimer = Timer(
          const Duration(milliseconds: 250),
          () => WorkoutRecovery.draft(widget.sessionID, draft)
              .catchError((_) {}));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _recovery && !_saving) {
      _sync();
    } else {
      _remember(immediate: true);
    }
  }

  Future<void> _sync() async {
    try {
      final raw = await WorkoutRecovery.session(widget.sessionID);
      if (!mounted) return;
      setState(() => _session = WorkoutSession.fromJson(raw));
      await _overlayPending();
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<bool> _record(Map<String, dynamic> body) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      if (_recovery) {
        await WorkoutRecovery.save(widget.sessionID, body);
      } else {
        await WorkoutService.put('/sessions/${widget.sessionID}/sets', body);
      }
      final raw = _recovery
          ? await WorkoutRecovery.session(widget.sessionID)
          : await WorkoutService.get('/sessions/${widget.sessionID}');
      if (!mounted) return false;
      setState(() => _session = WorkoutSession.fromJson(raw));
      if (_recovery) await _overlayPending();
      final e = _session!.exercises
          .firstWhere((e) => e.id == body['workoutExerciseID']);
      final item = _sequence
          .where((v) => v.$1.id == e.id && v.$2 == body['setNumber'])
          .firstOrNull;
      if (item?.$3 == true &&
          e.restSeconds > 0 &&
          WorkoutService.preferences['automaticRest'] != false) {
        _restPausedSeconds = 0;
        _workWatch.stop();
        _workRunning = false;
        _restUntil = DateTime.now().add(Duration(seconds: e.restSeconds));
        _updateRestAlert();
      }
      _index = 0;
      while (_index < _sequence.length &&
          _done(_sequence[_index].$1, _sequence[_index].$2)) {
        _index++;
      }
      _rowDrafts.remove('${body['workoutExerciseID']}:${body['setNumber']}');
      _remember();
      return true;
    } catch (e) {
      if (mounted) workoutError(context, e);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateRestAlert() async {
    _remember();
    final seconds = _restUntil == null ? 0 : _restSeconds;
    final local = await NotificationService.instance.scheduleWorkoutRest(
        widget.sessionID, seconds,
        title: 'SIRVYA Workout',
        body: 'Rest complete'.workoutTr(context),
        sound: WorkoutService.preferences['timerSound'] == true,
        vibration: WorkoutService.preferences['timerVibration'] == true);
    if (_recovery && WorkoutService.preferences.isNotEmpty) {
      WorkoutService.put('/sessions/${widget.sessionID}/rest-alert', {
        'seconds': local ? 0 : seconds
      }).catchError((_) => <String, dynamic>{});
    }
  }

  Future<void> _notificationTimerAction() async {
    final action = NotificationService.instance.restAction.value;
    if (_session == null ||
        action == null ||
        workoutInt(action['relatedEntityID']) != widget.sessionID ||
        workoutInt(action['event']) == _timerEvent) {
      return;
    }
    final user = await ApiService.getUserData();
    if (!mounted || '${action['userID']}' != '${user?['id']}') return;
    _timerEvent = workoutInt(action['event']);
    if (action['action'] == 'pause') {
      _restPause();
      return;
    }
    setState(() {
      if (action['action'] == 'skip') {
        _restUntil = null;
        _restPausedSeconds = 0;
      }
      if (action['action'] == 'extend') {
        _restUntil = DateTime.now().add(Duration(seconds: _restSeconds + 30));
        _restPausedSeconds = 0;
      }
    });
    _updateRestAlert();
  }

  Future<void> _undo(WorkoutExercise e, int n) async {
    if (_pending > 0) {
      workoutError(context, const WorkoutApiException('pending_sets', 409));
      return;
    }
    try {
      WorkoutService.checked(await ApiService.delete(
          '/workout/sessions/${widget.sessionID}/sets/${e.id}/$n'));
      await _load();
    } catch (error) {
      if (mounted) workoutError(context, error);
    }
  }

  Future<void> _changeExecution(List<WorkoutExercise> exercises) async {
    if (_pending > 0) {
      workoutError(context, const WorkoutApiException('pending_sets', 409));
      return;
    }
    try {
      await WorkoutService.put('/sessions/${widget.sessionID}/execution', {
        'revision': _session!.revision,
        'exercises': exercises
            .map((e) => {'id': e.id == 0 ? null : e.id, ...e.toJson()})
            .toList(),
        'notes': _notes.text
      });
      await _load();
    } catch (error) {
      if (mounted) workoutError(context, error);
    }
  }

  Future<void> _addExercise() async {
    final exercise = await Navigator.push<Exercise>(
        context,
        WorkoutRoute(
            builder: (_) => const WorkoutExerciseLibrary(selecting: true)));
    if (exercise == null || !mounted) return;
    await _changeExecution([
      ..._session!.exercises,
      WorkoutExercise(
          exercise: exercise,
          sets: 3,
          reps: exercise.isTimed ? null : 10,
          durationSeconds: exercise.isTimed ? 30 : null,
          restSeconds: workoutInt(
              WorkoutService.preferences['defaultRestSeconds'] ?? 90),
          weight: 0)
    ]);
  }

  Iterable<Widget> _exerciseCards() {
    final exercises = _session!.exercises;
    final current =
        _index < _sequence.length ? _sequence[_index].$1 : exercises.lastOrNull;
    final shown = _view == 'compact'
        ? exercises
        : current == null
            ? <WorkoutExercise>[]
            : [current];
    return [
      if (_view == 'cards' && current != null)
        Row(children: [
          TextButton.icon(
              onPressed: _saving || exercises.indexOf(current) == 0
                  ? null
                  : () {
                      setState(() => _index = _sequence.indexWhere((v) =>
                          v.$1.id ==
                          exercises[exercises.indexOf(current) - 1].id));
                    },
              icon: const Icon(Icons.chevron_left),
              label: const WorkoutLabel('Previous')),
          const Spacer(),
          TextButton.icon(
              onPressed:
                  _saving || exercises.indexOf(current) == exercises.length - 1
                      ? null
                      : () {
                          setState(() => _index = _sequence.indexWhere((v) =>
                              v.$1.id ==
                              exercises[exercises.indexOf(current) + 1].id));
                        },
              icon: const Icon(Icons.chevron_right),
              label: const WorkoutLabel('Next'))
        ]),
      ...shown.map((e) => Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: WorkoutLabel(e.exercise.name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4))),
                      PopupMenuButton<String>(
                          tooltip: (('Exercise actions')).workoutTr(context),
                          onSelected: (action) async {
                            final list = [...exercises],
                                index = list.indexOf(e);
                            if (action == 'add') {
                              if (e.sets >= 30) return;
                              list[index] = WorkoutExercise.fromJson({
                                'id': e.id,
                                ...e.toJson(),
                                'targetSets': e.sets + 1,
                                'name': e.exercise.name,
                                'muscleGroup': e.exercise.muscleGroup,
                                'equipment': e.exercise.equipment,
                                'exerciseType': e.exercise.type,
                                'isBodyweight': e.exercise.isBodyweight
                              });
                              await _changeExecution(list);
                            }
                            if (action == 'warmup') {
                              final n = 1001 +
                                  _session!.sets
                                      .where((s) =>
                                          s.workoutExerciseID == e.id &&
                                          s.isWarmup)
                                      .length;
                              await _editRichSet(e, n, warmup: true);
                            }
                            if (action == 'remove') {
                              list.remove(e);
                              await _changeExecution(list);
                            }
                            if (action == 'up' && index > 0) {
                              await _changeExecution(
                                  moveWorkoutGroup(list, index, -1));
                            }
                            if (action == 'down' && index < list.length - 1) {
                              await _changeExecution(
                                  moveWorkoutGroup(list, index, 1));
                            }
                            if (action == 'swap') {
                              if (!mounted) return;
                              final replacement =
                                  await Navigator.push<Exercise>(
                                      context,
                                      WorkoutRoute(
                                          builder: (_) =>
                                              const WorkoutExerciseLibrary(
                                                  selecting: true)));
                              if (replacement == null) return;
                              list[index] = WorkoutExercise(
                                  id: e.id,
                                  exercise: replacement,
                                  sets: e.sets,
                                  reps:
                                      replacement.isTimed ? null : e.reps ?? 10,
                                  durationSeconds: replacement.isTimed
                                      ? e.durationSeconds ?? 30
                                      : null,
                                  weight: e.weight,
                                  restSeconds: e.restSeconds,
                                  notes: e.notes,
                                  supersetGroup: e.supersetGroup,
                                  configuration: e.configuration);
                              await _changeExecution(list);
                            }
                          },
                          itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'add',
                                    child: WorkoutLabel('Add set')),
                                PopupMenuItem(
                                    value: 'warmup',
                                    child: WorkoutLabel('Add warm-up')),
                                PopupMenuItem(
                                    value: 'swap',
                                    child: WorkoutLabel('Swap exercise')),
                                PopupMenuItem(
                                    value: 'up',
                                    child: WorkoutLabel('Move up')),
                                PopupMenuItem(
                                    value: 'down',
                                    child: WorkoutLabel('Move down')),
                                PopupMenuItem(
                                    value: 'remove',
                                    child: WorkoutLabel('Remove exercise'))
                              ])
                    ]),
                    if (_view != 'compact') ...[
                      WorkoutLabel(
                          '${e.exercise.muscleGroup} · ${e.exercise.equipment}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      if (e.notes.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: WorkoutLabel(e.notes)),
                      if (e.configuration['targetRpe'] != null ||
                          e.configuration['targetRir'] != null)
                        WorkoutLabel(
                            'Target effort: ${e.configuration['targetRpe'] != null ? 'RPE ${e.configuration['targetRpe']}' : 'RIR ${e.configuration['targetRir']}'}'),
                      WorkoutLabel(
                          'Plan: ${e.sets} × ${e.exercise.isTimed ? '${e.durationSeconds} sec' : '${e.reps} reps'}'),
                      if (e.recommendation['reason'] != null &&
                          e.recommendation['policy'] != 'off')
                        WorkoutLabel(
                            'Progression: ${e.recommendation['reason'].toString().replaceAll('_', ' ')}',
                            style: const TextStyle(fontSize: 13)),
                      if ((_session!.previous[e.exercise.id] ?? []).isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: WorkoutLabel(
                                'Previous: ${_setLabel(_session!.previous[e.exercise.id]!.first, e)}',
                                style: const TextStyle(fontSize: 13)))
                    ],
                    if (e.supersetGroup.isNotEmpty)
                      Chip(label: WorkoutLabel('Superset ${e.supersetGroup}')),
                    const SizedBox(height: 12),
                    Row(children: [
                      const SizedBox(
                          width: 36,
                          child: WorkoutLabel('SET',
                              style: TextStyle(fontSize: 11))),
                      if (e.hasPrescribedLoad)
                        Expanded(
                            child: WorkoutLabel(
                                WorkoutService.unit.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11))),
                      Expanded(
                          child: WorkoutLabel(
                              e.exercise.isTimed ? 'SEC' : 'REPS',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11))),
                      const SizedBox(width: 48)
                    ]),
                    for (final s in _session!.sets.where(
                        (s) => s.workoutExerciseID == e.id && s.isWarmup))
                      WorkoutSetRow(
                          key: ValueKey('${e.id}:${s.setNumber}'),
                          exercise: e,
                          number: s.setNumber,
                          saved: s,
                          busy: _saving,
                          onSave: _record,
                          draft: _rowDrafts['${e.id}:${s.setNumber}']
                              as Map<String, dynamic>?,
                          onDraft: (draft) {
                            _rowDrafts['${e.id}:${s.setNumber}'] = draft;
                            _remember();
                          },
                          onUndo: () => _undo(e, s.setNumber),
                          onDetails: () =>
                              _editRichSet(e, s.setNumber, warmup: true)),
                    for (int n = 1; n <= e.sets; n++)
                      WorkoutSetRow(
                          key: ValueKey('${e.id}:$n'),
                          exercise: e,
                          number: n,
                          saved: _session!.sets
                              .where((s) =>
                                  s.workoutExerciseID == e.id &&
                                  s.setNumber == n)
                              .firstOrNull,
                          previous: (_session!.previous[e.exercise.id] ?? [])
                              .where((s) => s.setNumber == n)
                              .firstOrNull,
                          busy: _saving,
                          onSave: _record,
                          draft:
                              _rowDrafts['${e.id}:$n'] as Map<String, dynamic>?,
                          onDraft: (draft) {
                            _rowDrafts['${e.id}:$n'] = draft;
                            _remember();
                          },
                          onUndo: () => _undo(e, n),
                          onDetails: () => _editRichSet(e, n)),
                    if (e.exercise.isTimed)
                      TextButton.icon(
                          onPressed: () {
                            final seq = _sequence.indexWhere(
                                (v) => v.$1.id == e.id && !_done(e, v.$2));
                            if (seq < 0) return;
                            setState(() {
                              _index = seq;
                              _view = 'guided';
                              _prefill();
                            });
                          },
                          icon: const Icon(Icons.timer_outlined),
                          label: const WorkoutLabel('Start work timer')),
                    TextButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            WorkoutRoute(
                                builder: (_) => WorkoutExerciseDetail(
                                    exercise: e.exercise))),
                        icon: const Icon(Icons.info_outline),
                        label: const WorkoutLabel('Exercise details'))
                  ])))),
      OutlinedButton.icon(
          onPressed: _saving ? null : _addExercise,
          icon: const Icon(Icons.add),
          label: const WorkoutLabel('Add exercise'))
    ];
  }

  Future<void> _editRichSet(WorkoutExercise e, int n,
      {bool warmup = false}) async {
    final saved = _session!.sets
        .where((s) => s.workoutExerciseID == e.id && s.setNumber == n)
        .firstOrNull;
    final result = await workoutSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (_) => WorkoutRichSetEditor(
            exercise: e, number: n, saved: saved, warmup: warmup));
    if (result != null && mounted) await _record(result);
  }

  void _prefill() {
    _form.currentState?.reset();
    _workWatch
      ..stop()
      ..reset();
    _workSeconds = 0;
    _workAlerted = false;
    _workRunning = false;
    _effort.clear();
    if (_index >= _sequence.length) return;
    final (e, number, _) = _sequence[_index];
    final saved = _session!.sets
        .where((s) => s.workoutExerciseID == e.id && s.setNumber == number)
        .firstOrNull;
    final previous = (_session!.previous[e.exercise.id] ?? [])
        .where((s) => s.setNumber == number)
        .firstOrNull;
    _prefilledWeight = saved?.weight ?? e.weight ?? previous?.weight ?? 0;
    _addedLoad = (_prefilledWeight ?? 0) > 0;
    _scale = WorkoutService.preferences['effort'] ?? 'off';
    _effort.clear();
    _weight.text =
        workoutValue(WorkoutService.displayWeight(_prefilledWeight!));
    _reps.text = '${saved?.reps ?? e.reps ?? previous?.reps ?? 10}';
    _duration.text =
        '${saved?.durationSeconds ?? e.durationSeconds ?? previous?.durationSeconds ?? 30}';
    if (saved?.rpe != null) {
      _scale = 'rpe';
      _effort.text = workoutValue(saved!.rpe);
    }
    if (saved?.rir != null) {
      _scale = 'rir';
      _effort.text = '${saved!.rir}';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final (e, number, rest) = _sequence[_index];
    if (e.configuration['perSide'] == true) {
      await _editRichSet(e, number);
      return;
    }
    if (e.exercise.isTimed && _workRunning) {
      _duration.text = '${_workWatch.elapsed.inSeconds.clamp(1, 86400)}';
    }
    if (!_form.currentState!.validate()) return;
    _workWatch.stop();
    setState(() {
      _saving = true;
      _workRunning = false;
    });
    try {
      final body = <String, dynamic>{
        'workoutExerciseID': e.id,
        'setNumber': number,
        'weight': _prefilledWeight != null &&
                _weight.text ==
                    workoutValue(
                        WorkoutService.displayWeight(_prefilledWeight!))
            ? _prefilledWeight
            : WorkoutService.storedWeight(double.parse(_weight.text)),
        'reps': e.exercise.isTimed ? null : int.parse(_reps.text),
        'durationSeconds':
            e.exercise.isTimed ? int.parse(_duration.text) : null,
        'rpe': _scale == 'rpe' && _effort.text.isNotEmpty
            ? double.parse(_effort.text)
            : null,
        'rir': _scale == 'rir' && _effort.text.isNotEmpty
            ? int.parse(_effort.text)
            : null,
        'details': _session!.sets
                .where(
                    (s) => s.workoutExerciseID == e.id && s.setNumber == number)
                .firstOrNull
                ?.details ??
            {},
      };
      if (_recovery) {
        await WorkoutRecovery.save(widget.sessionID, body);
      } else {
        await WorkoutService.put('/sessions/${widget.sessionID}/sets', body);
      }
      // Reload persisted data before advancing; on an uncertain response, retry the same unique set.
      final updated = WorkoutSession.fromJson(_recovery
          ? await WorkoutRecovery.session(widget.sessionID)
          : await WorkoutService.get('/sessions/${widget.sessionID}'));
      if (!mounted) return;
      setState(() {
        _session = updated;
        _index++;
        while (_index < _sequence.length &&
            _done(_sequence[_index].$1, _sequence[_index].$2)) {
          _index++;
        }
        if (rest &&
            e.restSeconds > 0 &&
            _index < _sequence.length &&
            WorkoutService.preferences['automaticRest'] != false) {
          _restPausedSeconds = 0;
          _restUntil = DateTime.now().add(Duration(seconds: e.restSeconds));
        }
        _prefill();
      });
      if (_recovery) await _overlayPending();
      _updateRestAlert();
      _remember();
    } catch (error) {
      if (mounted) workoutError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finish({bool cancel = false}) async {
    if (_recovery) {
      try {
        await WorkoutRecovery.sync(widget.sessionID);
        _pending = await WorkoutRecovery.pending(widget.sessionID);
      } catch (e) {
        if (mounted) workoutError(context, e);
        return;
      }
      if (_pending > 0) return;
    }
    if (!mounted) return;
    final incomplete =
        _session!.sets.where((s) => !s.isWarmup).length < _sequence.length;
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: WorkoutLabel(cancel
                    ? 'Cancel workout?'
                    : incomplete
                        ? 'Finish with incomplete sets?'
                        : 'Finish workout?'),
                content: WorkoutLabel(cancel
                    ? 'Saved sets remain stored, but this session will not count toward your progress.'
                    : incomplete
                        ? 'Only the sets you completed will count.'
                        : 'Your completed sets will be added to your history and progress.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const WorkoutLabel('Keep training')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: WorkoutLabel(cancel ? 'Cancel workout' : 'Finish'))
                ]));
    if (yes != true || !mounted) return;
    int? historicalDuration;
    if (_session!.historical && !cancel) {
      final input = TextEditingController(text: '60');
      final duration = await workoutDialog<int>(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                      title: const WorkoutLabel('Workout duration'),
                      content: TextField(
                          controller: input,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => update(() {}),
                          decoration: InputDecoration(
                              labelText: 'Minutes'.workoutTr(context))),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const WorkoutLabel('Cancel')),
                        ElevatedButton(
                            onPressed: (int.tryParse(input.text) ?? -1) < 0 ||
                                    (int.tryParse(input.text) ?? 99999) > 10080
                                ? null
                                : () => Navigator.pop(
                                    context, int.parse(input.text) * 60),
                            child: const WorkoutLabel('Save'))
                      ])));
      input.dispose();
      if (duration == null || !mounted) return;
      historicalDuration = duration;
    }
    setState(() => _saving = true);
    try {
      final r = await WorkoutService.put('/sessions/${widget.sessionID}', {
        'status': cancel ? 'cancelled' : 'completed',
        'allowIncomplete': incomplete,
        'notes': _notes.text,
        if (historicalDuration != null) 'durationSeconds': historicalDuration
      });
      if (!mounted) return;
      setState(() {
        _saving = false;
        _allowLeave = true;
      });
      if (cancel) {
        Navigator.pop(context);
        return;
      }
      await Navigator.pushReplacement(context,
          WorkoutRoute(builder: (_) => WorkoutCompletionScreen(summary: r)));
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _valid(String? value,
      {bool integer = false,
      double min = 0,
      double max = 2000,
      bool optional = false}) {
    if ((value ?? '').isEmpty && optional) return null;
    final n = double.tryParse(value ?? '');
    if (n == null ||
        !n.isFinite ||
        n < min ||
        n > max ||
        integer && int.tryParse(value ?? '') == null) {
      return 'Enter a value from $min to $max'.workoutTr(context);
    }
    return null;
  }

  Widget _field(TextEditingController c, String label,
          {bool integer = false,
          double min = 0,
          double max = 2000,
          bool optional = false}) =>
      TextFormField(
          controller: c,
          enabled: !_saving,
          keyboardType: TextInputType.numberWithOptions(decimal: !integer),
          decoration: InputDecoration(labelText: ((label)).workoutTr(context)),
          onChanged: (_) => _remember(),
          validator: (v) => _valid(v,
              integer: integer, min: min, max: max, optional: optional));
  void _restPause() => setState(() {
        if (_restUntil == null) {
          _restUntil =
              DateTime.now().add(Duration(seconds: _restPausedSeconds));
          _restPausedSeconds = 0;
        } else {
          _restPausedSeconds = _restSeconds;
          _restUntil = null;
        }
        _updateRestAlert();
      });
  void _skipRest() {
    setState(() {
      _restUntil = null;
      _restPausedSeconds = 0;
    });
    _updateRestAlert();
  }

  void _extendRest() {
    setState(() {
      if (_restUntil == null) {
        _restPausedSeconds += 30;
      } else {
        _restUntil = _restUntil!.add(const Duration(seconds: 30));
      }
    });
    _updateRestAlert();
  }

  Future<void> _leave() async {
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const WorkoutLabel('Leave active workout?'),
                content: const WorkoutLabel(
                    'Your recorded sets stay saved. You can resume this workout from Workout home.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const WorkoutLabel('Keep training')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const WorkoutLabel('Leave and resume later'))
                ]));
    if (yes != true || !mounted) return;
    _remember();
    if (_recovery) {
      _draftTimer?.cancel();
      await WorkoutRecovery.draft(widget.sessionID, {
        'notes': _notes.text,
        'rows': _rowDrafts,
        'index': _index,
        'weight': _weight.text,
        'reps': _reps.text,
        'duration': _duration.text,
        'effort': _effort.text,
        'scale': _scale,
        'workTimer': _workWatch.toJson(),
        'restUntil': _restUntil?.toIso8601String(),
        'restPausedSeconds': _restPausedSeconds
      });
    }
    if (!mounted) return;
    setState(() => _allowLeave = true);
    Navigator.pop(context);
  }

  Widget _restBar() => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      const Icon(Icons.timer_outlined),
                      const SizedBox(width: 10),
                      const WorkoutLabel('Rest'),
                      const Spacer(),
                      WorkoutLabel(workoutClock(_restSeconds),
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w600))
                    ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  _restUntil = null;
                                  _restPausedSeconds = 0;
                                });
                                _updateRestAlert();
                              },
                              child: const WorkoutLabel('Skip')),
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  if (_restUntil == null) {
                                    _restPausedSeconds += 30;
                                  } else {
                                    _restUntil = _restUntil!
                                        .add(const Duration(seconds: 30));
                                  }
                                });
                                _updateRestAlert();
                              },
                              child: const WorkoutLabel('+30 sec')),
                          TextButton(
                              onPressed: _restPause,
                              child: WorkoutLabel(
                                  _restUntil == null ? 'Resume' : 'Pause'))
                        ])
                  ])))));
  @override
  Widget build(BuildContext context) {
    final s = _session;
    final screen = PopScope(
        canPop: !_saving && (_allowLeave || s?.status != 'active'),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_saving) _leave();
        },
        child: WorkoutScaffold(
            bottomNavigationBar:
                _view != 'guided' && _resting ? _restBar() : null,
            appBar: AppBar(
                title: WorkoutLabel(s?.dayName ?? WorkoutText.title),
                actions: [
                  if (s?.status == 'active')
                    IconButton(
                        tooltip: (('Finish workout')).workoutTr(context),
                        onPressed: _saving ? null : () => _finish(),
                        icon: const Icon(Icons.check_circle_outline)),
                  PopupMenuButton<String>(
                      tooltip: (('Workout view')).workoutTr(context),
                      initialValue: _view,
                      onSelected: (v) => setState(() => _view = v),
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'cards',
                                child: WorkoutLabel('Exercise cards')),
                            PopupMenuItem(
                                value: 'compact',
                                child: WorkoutLabel('Compact set rows')),
                            PopupMenuItem(
                                value: 'guided',
                                child: WorkoutLabel('Guided set entry'))
                          ])
                ]),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? WorkoutFailure(error: _error!, retry: _load)
                    : s == null
                        ? const SizedBox.shrink()
                        : s.status != 'active'
                            ? Center(
                                child: WorkoutLabel(
                                    'This workout has ${s.status == 'completed' ? 'completed' : 'been cancelled'}.'))
                            : ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                    if (s.offline) const WorkoutOfflineNotice(),
                                    WorkoutLabel(s.planName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    if (_pending > 0)
                                      Card(
                                          child: ListTile(
                                              leading: const Icon(
                                                  Icons.cloud_upload_outlined),
                                              title: WorkoutLabel(
                                                  '$_pending sets waiting to sync'),
                                              subtitle: const WorkoutLabel(
                                                  'Saved on this device. Reconnect before finishing.'),
                                              trailing: TextButton(
                                                  onPressed: _sync,
                                                  child: const WorkoutLabel(
                                                      'Sync now')))),
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                        value: _sequence.isEmpty
                                            ? 0
                                            : (s.sets
                                                        .where(
                                                            (s) => !s.isWarmup)
                                                        .length /
                                                    _sequence.length)
                                                .clamp(0, 1)),
                                    const SizedBox(height: 8),
                                    WorkoutLabel(
                                        '${s.sets.length} / ${_sequence.length} sets saved'),
                                    const SizedBox(height: 16),
                                    if (_resting && _view == 'guided')
                                      Card(
                                          child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(children: [
                                                WorkoutLabel('Rest',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge),
                                                WorkoutLabel(
                                                    workoutClock(_restSeconds),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .displaySmall),
                                                Wrap(spacing: 8, children: [
                                                  TextButton(
                                                      onPressed: _skipRest,
                                                      child: const WorkoutLabel(
                                                          'Skip')),
                                                  TextButton(
                                                      onPressed: _extendRest,
                                                      child: const WorkoutLabel(
                                                          '+30 sec')),
                                                  TextButton(
                                                      onPressed: _restPause,
                                                      child: WorkoutLabel(
                                                          _restUntil == null
                                                              ? 'Resume'
                                                              : 'Pause'))
                                                ])
                                              ]))),
                                    if (_view == 'guided' &&
                                        _index < _sequence.length)
                                      _currentCard(),
                                    if (_view != 'guided' ||
                                        s.exercises.isEmpty)
                                      ..._exerciseCards(),
                                    const SizedBox(height: 12),
                                    WorkoutLabel('Saved sets',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    if (_view == 'guided')
                                      ...s.exercises.map((e) => Card(
                                              child: ExpansionTile(
                                                  title: WorkoutLabel(
                                                      e.exercise.name),
                                                  subtitle: WorkoutLabel(
                                                      '${s.sets.where((v) => v.workoutExerciseID == e.id).length} / ${e.sets} sets'),
                                                  children: [
                                                for (int n = 1;
                                                    n <= e.sets;
                                                    n++)
                                                  ListTile(
                                                      title: WorkoutLabel(
                                                          'Set $n'),
                                                      subtitle: WorkoutLabel(_setLabel(
                                                          s.sets
                                                              .where((v) =>
                                                                  v.workoutExerciseID ==
                                                                      e.id &&
                                                                  v.setNumber ==
                                                                      n)
                                                              .firstOrNull,
                                                          e)),
                                                      trailing: IconButton(
                                                          tooltip: ('Edit set')
                                                              .workoutTr(
                                                                  context),
                                                          icon: const Icon(Icons
                                                              .edit_outlined),
                                                          onPressed: _saving
                                                              ? null
                                                              : () =>
                                                                  setState(() {
                                                                    _index = _sequence.indexWhere((v) =>
                                                                        v.$1.id ==
                                                                            e.id &&
                                                                        v.$2 == n);
                                                                    _prefill();
                                                                  })))
                                              ]))),
                                    const SizedBox(height: 16),
                                    TextField(
                                        controller: _notes,
                                        onChanged: (_) => _remember(),
                                        enabled: !_saving,
                                        maxLength: 5000,
                                        decoration: InputDecoration(
                                            labelText: (('Workout notes'))
                                                .workoutTr(context))),
                                    WorkoutMediaPanel(
                                        sessionID: widget.sessionID),
                                    ElevatedButton.icon(
                                        onPressed: _saving || s.sets.isEmpty
                                            ? null
                                            : () => _finish(),
                                        icon: const Icon(
                                            Icons.check_circle_outline),
                                        label: WorkoutLabel(_saving
                                            ? 'Saving…'
                                            : 'Finish workout')),
                                    TextButton(
                                        onPressed: _saving
                                            ? null
                                            : () => _finish(cancel: true),
                                        child: const WorkoutLabel(
                                            'Cancel workout')),
                                    const WorkoutLabel(
                                        'You can leave this screen and resume your saved workout later.',
                                        textAlign: TextAlign.center),
                                  ])));
    return Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent || _saving || _session == null) {
            return KeyEventResult.ignored;
          }
          final focused = FocusManager.instance.primaryFocus?.context;
          if (focused?.widget is EditableText ||
              focused?.findAncestorWidgetOfExactType<EditableText>() != null) {
            return KeyEventResult.ignored;
          }
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.space && _resting) {
            _restPause();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.enter && _index < _sequence.length) {
            if (_view == 'guided') {
              _save();
            } else {
              final item = _sequence[_index];
              _editRichSet(item.$1, item.$2);
            }
            return KeyEventResult.handled;
          }
          if ((key == LogicalKeyboardKey.arrowLeft ||
                  key == LogicalKeyboardKey.arrowRight) &&
              _sequence.isNotEmpty) {
            setState(() {
              _index = (_index + (key == LogicalKeyboardKey.arrowLeft ? -1 : 1))
                  .clamp(0, _sequence.length - 1);
              _prefill();
            });
            _remember();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: screen);
  }

  String _setLabel(WorkoutSet? s, WorkoutExercise e) {
    if (s == null) return 'Not recorded';
    final load = (s.weight ?? 0) > 0
        ? '${e.exercise.isBodyweight ? '+' : ''}${workoutValue(WorkoutService.displayWeight(s.weight!))} ${WorkoutService.unit}'
        : e.exercise.isBodyweight
            ? 'Bodyweight'
            : '0 ${WorkoutService.unit}';
    return '${e.exercise.isTimed ? '${s.durationSeconds} sec${(s.weight ?? 0) > 0 ? ' · $load' : ''}' : '$load × ${s.reps}'}${s.rpe == null ? '' : ' · RPE ${workoutValue(s.rpe)}'}${s.rir == null ? '' : ' · RIR ${s.rir}'}';
  }

  Widget _currentCard() {
    final (e, number, _) = _sequence[_index];
    final previous = _session!.previous[e.exercise.id] ?? [];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
                key: _form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: WorkoutLabel(e.exercise.name,
                                style: Theme.of(context).textTheme.titleLarge)),
                        IconButton(
                            tooltip:
                                (('Exercise instructions')).workoutTr(context),
                            onPressed: () => Navigator.push(
                                context,
                                WorkoutRoute(
                                    builder: (_) => WorkoutExerciseDetail(
                                        exercise: e.exercise))),
                            icon: const Icon(Icons.info_outline))
                      ]),
                      if (e.supersetGroup.isNotEmpty)
                        Chip(
                            label: WorkoutLabel('Superset ${e.supersetGroup}')),
                      WorkoutLabel(
                          'Target: ${e.sets} × ${e.exercise.isTimed ? '${e.durationSeconds} sec' : '${e.reps} reps'}${(e.weight ?? 0) > 0 ? ' · ${e.exercise.isBodyweight ? '+' : ''}${workoutValue(WorkoutService.displayWeight(e.weight!))} ${WorkoutService.unit}' : ''}'),
                      if (e.notes.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: WorkoutLabel(e.notes)),
                      if (previous.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const WorkoutLabel('Previous workout'),
                        ...previous.map((v) => WorkoutLabel(_setLabel(v, e)))
                      ],
                      const SizedBox(height: 16),
                      WorkoutLabel('Set $number / ${e.sets}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (e.supportsLoad && (e.hasPrescribedLoad || _addedLoad))
                        _field(
                            _weight,
                            e.exercise.isBodyweight
                                ? 'Added weight (${WorkoutService.unit})'
                                : 'Weight (${WorkoutService.unit})',
                            max: WorkoutService.displayWeight(2000)),
                      if (e.exercise.isBodyweight &&
                          !_addedLoad &&
                          !e.hasPrescribedLoad)
                        TextButton.icon(
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                      _addedLoad = true;
                                      _remember();
                                    }),
                            icon: const Icon(Icons.add_rounded),
                            label: const WorkoutLabel('Add external load')),
                      const SizedBox(height: 12),
                      if (e.exercise.isTimed) ...[
                        _field(_duration, 'Duration (sec)',
                            integer: true, min: 1, max: 86400),
                        Row(children: [
                          WorkoutLabel(
                              _workSeconds <= (e.durationSeconds ?? 30)
                                  ? workoutClock(
                                      (e.durationSeconds ?? 30) - _workSeconds)
                                  : '+${workoutClock(_workSeconds - (e.durationSeconds ?? 30))}',
                              style: Theme.of(context).textTheme.titleLarge),
                          const Spacer(),
                          TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                        if (_workRunning) {
                                          _workWatch.stop();
                                          _duration.text =
                                              '${_workWatch.elapsed.inSeconds.clamp(1, 86400)}';
                                        } else {
                                          _restUntil = null;
                                          _restPausedSeconds = 0;
                                          _updateRestAlert();
                                          _workWatch.start();
                                        }
                                        _workRunning = !_workRunning;
                                        _remember();
                                      }),
                              child: WorkoutLabel(_workRunning
                                  ? 'Stop work timer'
                                  : 'Start work timer'))
                        ])
                      ] else
                        _field(_reps, 'Repetitions',
                            integer: true, min: 1, max: 1000),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _scale,
                          decoration: InputDecoration(
                              labelText:
                                  (('Effort (optional)')).workoutTr(context)),
                          items: const [
                            DropdownMenuItem(
                                value: 'off', child: WorkoutLabel('Off')),
                            DropdownMenuItem(
                                value: 'rpe',
                                child: WorkoutLabel('RPE · effort 1–10')),
                            DropdownMenuItem(
                                value: 'rir',
                                child:
                                    WorkoutLabel('RIR · reps remaining 0–10'))
                          ],
                          onChanged: _saving
                              ? null
                              : (v) => setState(() {
                                    _scale = v!;
                                    _effort.clear();
                                  })),
                      if (_scale != 'off')
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _field(_effort, _scale.toUpperCase(),
                                integer: _scale == 'rir',
                                min: _scale == 'rpe' ? 1 : 0,
                                max: 10,
                                optional: true)),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: _saving || _workRunning ? null : _save,
                              icon: const Icon(Icons.check_rounded),
                              label: WorkoutLabel(
                                  _saving ? 'Saving…' : 'Save set'))),
                    ]))));
  }
}

class WorkoutCompletionScreen extends StatelessWidget {
  final Map<String, dynamic> summary;
  const WorkoutCompletionScreen({super.key, required this.summary});
  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      appBar: AppBar(title: const WorkoutLabel('Workout completed')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Icon(Icons.check_circle_rounded,
            size: 72, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        ...{
          'Duration':
              '${(workoutInt(summary['durationSeconds']) / 60).round()} min',
          'Exercises': '${summary['exerciseCount']}',
          'Sets': '${summary['setCount']}',
          'Volume': '${workoutValue(workoutNumber(summary['volume']))} kg',
          'New PRs': '${summary['newPRs']}'
        }.entries.map((e) => Card(
            child: ListTile(
                title: WorkoutLabel(e.key),
                trailing: WorkoutLabel(e.value,
                    style: Theme.of(context).textTheme.titleMedium)))),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const WorkoutLabel('Done')),
      ]));
}
