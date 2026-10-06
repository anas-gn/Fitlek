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
import 'workout_muscles.dart';
import 'workout_demonstration.dart';
import 'workout_timer_bar.dart';
import 'workout_builder.dart';

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
  final DateTime Function()? clock;
  const ActiveWorkoutScreen({super.key, required this.sessionID, this.clock});
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
  late final PersistentWorkoutTimer _workWatch;
  DateTime _now() => widget.clock?.call() ?? DateTime.now();
  bool _workAlerted = false;
  Map<String, dynamic>? _workSet;
  int _workTargetSeconds = 0, _unitIndex = 0;
  int _restTotalSeconds = 0;
  WorkoutTimerController? _timerHost;
  final Set<int> _confirmedExercises = {};
  bool _completionShown = false;
  double? _prefilledWeight;
  bool _addedLoad = false;
  Timer? _ticker;
  int _elapsedSecond = -1;
  bool _workRunning = false;
  int _workSeconds = 0, _restPausedSeconds = 0;
  DateTime? _restUntil;
  String _scale = 'off';
  int _index = 0;
  String _view = WorkoutService.preferences['view'] ?? 'cards';
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
      : (_restUntil!.difference(_now()).inMilliseconds / 1000)
          .ceil()
          .clamp(0, 86400);
  bool get _resting => _restSeconds > 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timerHost = WorkoutTimerHost.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    _workWatch = PersistentWorkoutTimer(clock: _now);
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
      final elapsedSecond = _session == null
          ? 0
          : _now().difference(_session!.startedAt).inSeconds;
      final elapsedChanged =
          _session?.status == 'active' && elapsedSecond != _elapsedSecond;
      _elapsedSecond = elapsedSecond;
      if (_workRunning || hadRest || elapsedChanged) {
        setState(() {
          _workSeconds = _workWatch.elapsed.inSeconds;
          if (_workRunning &&
              !_workAlerted &&
              _workSet != null &&
              _workSeconds >= _workTargetSeconds) {
            _workAlerted = true;
            if (WorkoutService.preferences['timerVibration'] == true) {
              HapticFeedback.mediumImpact();
            }
            if (WorkoutService.preferences['timerSound'] == true) {
              SystemSound.play(SystemSoundType.alert);
            }
            unawaited(_finishTimedSet(reachedTarget: true));
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
        _publishTimer();
      }
    });
  }

  @override
  void dispose() {
    if (_session?.status == 'active' && !_allowLeave) {
      _remember(immediate: true);
    }
    _ticker?.cancel();
    _timerHost?.publish(null);
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
        _unitIndex = workoutInt(draft['unitIndex']);
        _confirmedExercises.addAll(
            (draft['confirmedExercises'] as List? ?? []).map(workoutInt));
        _completionShown = draft['completionShown'] == true;
        if (draft['workSet'] is Map) {
          _workSet = Map<String, dynamic>.from(draft['workSet']);
          _workTargetSeconds = workoutInt(draft['workTargetSeconds']);
          _workWatch
              .restore(Map<String, dynamic>.from(draft['workTimer'] ?? {}));
          _workRunning = _workWatch.isRunning;
          _workSeconds = _workWatch.elapsed.inSeconds;
          _workAlerted = false;
          if (_workSet != null &&
              _session!.sets.any((s) =>
                  s.workoutExerciseID == _workSet!['workoutExerciseID'] &&
                  s.setNumber == _workSet!['setNumber'])) {
            _cancelWork();
          }
        }
        _notes.text = draft['notes'] ?? session.notes;
        _restUntil = DateTime.tryParse(draft['restUntil'] ?? '');
        _restPausedSeconds = workoutInt(draft['restPausedSeconds']);
        _restTotalSeconds =
            workoutInt(draft['restTotalSeconds'] ?? _restSeconds);
        if (draft['index'] == _index) {
          _weight.text = draft['weight'] ?? _weight.text;
          _reps.text = draft['reps'] ?? _reps.text;
          _duration.text = draft['duration'] ?? _duration.text;
          _effort.text = draft['effort'] ?? '';
          _scale = draft['scale'] ?? _scale;
          _addedLoad = draft['addedLoad'] == true || _addedLoad;
          if (_workSet == null && draft['workSet'] == null) {
            _workWatch
                .restore(Map<String, dynamic>.from(draft['workTimer'] ?? {}));
            _workRunning = _workWatch.isRunning;
            _workSeconds = _workWatch.elapsed.inSeconds;
          }
        }
      }
      final groups = workoutExerciseGroups(session.exercises);
      if (draft.isEmpty) {
        final first = groups.indexWhere((g) => !g.every(_exerciseDone));
        _unitIndex = first < 0 ? 0 : first;
      }
      if (groups.isNotEmpty) {
        _unitIndex = _unitIndex.clamp(0, groups.length - 1);
      }
      _notificationTimerAction();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
      _publishTimer();
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
    final draft = _draft();
    if (immediate) {
      WorkoutRecovery.draft(widget.sessionID, draft).catchError((_) {});
    } else {
      _draftTimer = Timer(
          const Duration(milliseconds: 250),
          () => WorkoutRecovery.draft(widget.sessionID, draft)
              .catchError((_) {}));
    }
  }

  Map<String, dynamic> _draft() => {
        'rows': _rowDrafts,
        'index': _index,
        'weight': _weight.text,
        'reps': _reps.text,
        'duration': _duration.text,
        'effort': _effort.text,
        'scale': _scale,
        'addedLoad': _addedLoad,
        'workTimer': _workWatch.toJson(),
        'workSet': _workSet,
        'workTargetSeconds': _workTargetSeconds,
        'unitIndex': _unitIndex,
        'confirmedExercises': _confirmedExercises.toList(),
        'completionShown': _completionShown,
        'notes': _notes.text,
        'restUntil': _restUntil?.toIso8601String(),
        'restPausedSeconds': _restPausedSeconds,
        'restTotalSeconds': _restTotalSeconds
      };

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
      if (_session!.status != 'active') {
        _cancelWork();
        _skipRest();
        return;
      }
      await _overlayPending();
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  bool _exerciseDone(WorkoutExercise e) =>
      List.generate(e.sets, (i) => i + 1).every((n) => _done(e, n));

  WorkoutTimerDisplay? get _timerDisplay {
    if (_workSet != null) {
      return WorkoutTimerDisplay(
          work: true,
          remaining: (_workTargetSeconds - _workWatch.elapsed.inSeconds)
              .clamp(0, 86400),
          total: _workTargetSeconds,
          label: _session?.exercises
                  .where((e) => e.id == _workSet!['workoutExerciseID'])
                  .firstOrNull
                  ?.exercise
                  .name ??
              'Work',
          cancel: _cancelWork,
          done: () => _finishTimedSet(),
          busy: _saving);
    }
    if (!_resting) return null;
    return WorkoutTimerDisplay(
        work: false,
        remaining: _restSeconds,
        total: _restTotalSeconds,
        label: 'Rest',
        paused: _restUntil == null,
        cancel: _skipRest,
        done: _skipRest,
        adjust: _adjustRest,
        pause: _restPause);
  }

  void _publishTimer() => _timerHost?.publish(_timerDisplay);

  void _startTimedSet(Map<String, dynamic> payload) {
    if (_saving || _workSet != null || _session == null) return;
    final e = _session!.exercises
        .where((e) => e.id == payload['workoutExerciseID'])
        .firstOrNull;
    final seconds = workoutInt(payload['durationSeconds']);
    if (e == null ||
        !e.exercise.isTimed ||
        e.exercise.type == 'cardio' ||
        seconds < 1 ||
        seconds > 86400 ||
        _done(e, workoutInt(payload['setNumber']))) {
      return;
    }
    setState(() {
      _restUntil = null;
      _restPausedSeconds = 0;
      _workSet = Map<String, dynamic>.from(payload);
      _workTargetSeconds = seconds;
      _workWatch
        ..stop()
        ..reset()
        ..start();
      _workRunning = true;
      _workAlerted = false;
      _workSeconds = 0;
    });
    _remember(immediate: true);
    _publishTimer();
    unawaited(_updateRestAlert());
  }

  Future<void> _finishTimedSet({bool reachedTarget = false}) async {
    if (_workSet == null || _saving) return;
    final payload = Map<String, dynamic>.from(_workSet!);
    final elapsed = reachedTarget
        ? _workTargetSeconds
        : _workWatch.elapsed.inSeconds.clamp(1, _workTargetSeconds);
    _workWatch.stop();
    _workRunning = false;
    // Clear before recording so the shared set-completion path can start rest.
    _workSet = null;
    payload['durationSeconds'] = elapsed;
    if (!await _record(payload) && mounted) {
      setState(() {
        _workSet = payload;
        _workTargetSeconds = elapsed;
      });
    }
    if (!mounted) return;
    setState(() {});
    _remember(immediate: true);
    _publishTimer();
  }

  void _cancelWork() {
    if (!mounted) return;
    setState(() {
      _workSet = null;
      _workRunning = false;
      _workWatch
        ..stop()
        ..reset();
      _workSeconds = 0;
      _workAlerted = false;
    });
    _remember(immediate: true);
    _publishTimer();
    unawaited(_updateRestAlert());
  }

  void _adjustRest(int seconds) {
    final next = (_restSeconds + seconds).clamp(0, 86400);
    setState(() {
      if (_restUntil == null) {
        _restPausedSeconds = next;
      } else {
        _restUntil = next == 0 ? null : _now().add(Duration(seconds: next));
        _restPausedSeconds = 0;
      }
    });
    unawaited(_updateRestAlert());
  }

  Future<void> _afterSet(WorkoutExercise e) async {
    if (!mounted || !_exerciseDone(e) || _pending > 0) return;
    final groups = workoutExerciseGroups(_session!.exercises);
    final groupIndex = groups.indexWhere((g) => g.any((v) => v.id == e.id));
    final complete = groups[groupIndex].every(_exerciseDone);
    final loaded = e.exercise.type == 'reps' &&
        (!e.exercise.isBodyweight ||
            _session!.sets.any(
                (s) => s.workoutExerciseID == e.id && (s.weight ?? 0) > 0));
    bool advance = false;
    if (loaded && !_confirmedExercises.contains(e.id)) {
      _confirmedExercises.add(e.id);
      final highest = _session!.sets
          .where((s) => s.workoutExerciseID == e.id && !s.isWarmup)
          .fold<double>(e.workingWeight ?? 0,
              (best, s) => (s.weight ?? 0) > best ? s.weight! : best);
      final input = TextEditingController(
          text: workoutValue(WorkoutService.displayWeight(highest)));
      final result = await workoutSheet<(double, bool)>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24,
                  24 + MediaQuery.viewInsetsOf(sheetContext).bottom),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WorkoutLabel('${e.exercise.name} done',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const WorkoutLabel(
                        'Confirm the weight you worked with. Your highest becomes the default next time.'),
                    const SizedBox(height: 16),
                    WorkoutNumberStepper(
                        controller: input,
                        label: 'Working weight (${WorkoutService.unit})',
                        step: WorkoutService.displayWeight(2.5),
                        onChanged: () {},
                        max: WorkoutService.displayWeight(2000)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () {
                          final weight = double.tryParse(input.text);
                          if (weight == null ||
                              !weight.isFinite ||
                              weight < 0 ||
                              WorkoutService.storedWeight(weight) > 2000) {
                            return;
                          }
                          Navigator.pop(sheetContext,
                              (WorkoutService.storedWeight(weight), complete));
                        },
                        child: WorkoutLabel(
                            complete && groupIndex < groups.length - 1
                                ? 'Save & next exercise'
                                : 'Save weight')),
                    TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const WorkoutLabel('Just close'))
                  ])));
      input.dispose();
      if (!mounted) return;
      if (result != null) {
        try {
          await WorkoutService.put('/exercises/${e.exercise.id}/working-weight',
              {'weight': result.$1});
          advance = result.$2;
        } catch (error) {
          _confirmedExercises.remove(e.id);
          if (mounted) workoutError(context, error);
        }
      }
      _remember();
    }
    if (!mounted || !complete) return;
    if (advance && groupIndex < groups.length - 1) {
      _navigateUnit(groupIndex + 1);
    }
    if (groupIndex == groups.length - 1 && !_completionShown) {
      _completionShown = true;
      _remember();
      final finish = await workoutDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                  title: const WorkoutLabel('That’s the whole workout!'),
                  content: const WorkoutLabel(
                      'Every exercise in this unit is done. Finish up, or keep going and add another exercise.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const WorkoutLabel('Continue workout')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const WorkoutLabel('Finish workout'))
                  ]));
      if (finish == true && mounted) await _finish();
    }
  }

  void _navigateUnit(int index) {
    final groups = workoutExerciseGroups(_session!.exercises);
    if (index < 0 || index >= groups.length) return;
    setState(() {
      _unitIndex = index;
      _index = _sequence.indexWhere((v) => v.$1.id == groups[index].first.id);
      _prefill();
    });
    _remember();
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
      final unit = workoutExerciseGroups(_session!.exercises)
          .firstWhere((g) => g.any((v) => v.id == e.id));
      final unitDone = unit.every(_exerciseDone);
      if (unitDone) {
        _skipRest();
      } else if (unit.last.id == e.id &&
          e.restSeconds > 0 &&
          WorkoutService.preferences['automaticRest'] != false &&
          _workSet == null) {
        _restPausedSeconds = 0;
        _restTotalSeconds = e.restSeconds;
        _restUntil = _now().add(Duration(seconds: e.restSeconds));
        unawaited(_updateRestAlert());
      }
      _index = 0;
      while (_index < _sequence.length &&
          _done(_sequence[_index].$1, _sequence[_index].$2)) {
        _index++;
      }
      _rowDrafts.remove('${body['workoutExerciseID']}:${body['setNumber']}');
      _remember();
      _publishTimer();
      unawaited(_afterSet(e));
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
    _publishTimer();
    final work = _workSet != null && _workRunning;
    final seconds = work
        ? (_workTargetSeconds - _workWatch.elapsed.inSeconds).clamp(0, 86400)
        : _restUntil == null
            ? 0
            : _restSeconds;
    final local = await NotificationService.instance.scheduleWorkoutRest(
        widget.sessionID, seconds,
        title: 'SIRVYA Workout',
        body:
            (work ? 'Timed set complete' : 'Rest complete').workoutTr(context),
        work: work,
        sound: WorkoutService.preferences['timerSound'] == true,
        vibration: WorkoutService.preferences['timerVibration'] == true);
    if (_recovery && WorkoutService.preferences.isNotEmpty) {
      WorkoutService.put('/sessions/${widget.sessionID}/rest-alert', {
        'seconds': local ? 0 : seconds,
        'kind': work ? 'work' : 'rest'
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
        _restUntil = _now().add(Duration(seconds: _restSeconds + 15));
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
      _completionShown = false;
      _confirmedExercises.remove(e.id);
      await WorkoutRecovery.draft(widget.sessionID, _draft());
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
    await workoutPickExercise(context,
        onSelect: (pickerContext, exercise) async {
      final configured =
          await workoutConfigureExercise(pickerContext, exercise: exercise);
      if (configured == null || !mounted) return;
      _completionShown = false;
      await _changeExecution([..._session!.exercises, configured]);
      if (mounted && _session != null) {
        _navigateUnit(workoutExerciseGroups(_session!.exercises).length - 1);
      }
    });
  }

  Widget _exerciseTag(String text) => DecoratedBox(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(5)),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: WorkoutLabel(workoutExerciseTitle(text),
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))));

  double _previousBest(WorkoutExercise e) {
    final weights = [
      e.exercise.bestWeight,
      e.workingWeight ?? 0,
      ...(_session!.previous[e.exercise.id] ?? [])
          .where((s) => !s.isWarmup)
          .map((s) => s.weight ?? 0)
    ]..sort();
    return weights.last;
  }

  String _previousLabel(WorkoutSet s, WorkoutExercise e) => e.exercise.isTimed
      ? _setLabel(s, e)
      : '${workoutValue(WorkoutService.displayWeight(s.weight ?? 0))}×${s.reps}${s.rir == null ? s.rpe == null ? '' : ' (RPE ${workoutValue(s.rpe)})' : ' (RIR ${workoutValue(s.rir)})'}';

  Future<void> _resizeSets(WorkoutExercise e, int sets) async {
    final list = [..._session!.exercises];
    list[list.indexOf(e)] = WorkoutExercise.fromJson({
      ...e.toJson(),
      'id': e.id,
      'targetSets': sets,
      'name': e.exercise.name,
      'muscleGroup': e.exercise.muscleGroup,
      'equipment': e.exercise.equipment,
      'exerciseType': e.exercise.type,
      'isBodyweight': e.exercise.isBodyweight
    });
    await _changeExecution(list);
  }

  Iterable<Widget> _exerciseCards() {
    final exercises = _session!.exercises;
    final groups = workoutExerciseGroups(exercises);
    final unitIndex =
        groups.isEmpty ? 0 : _unitIndex.clamp(0, groups.length - 1);
    final shown = _view == 'compact'
        ? exercises
        : groups.isEmpty
            ? <WorkoutExercise>[]
            : groups[unitIndex];
    return [
      if (groups.isNotEmpty && _view == 'cards') ...[
        WorkoutLabel(
            '${shown.length > 1 ? 'Superset' : 'Exercise'} ${unitIndex + 1} / ${groups.length}',
            style: Theme.of(context).textTheme.bodySmall),
        if (shown.length > 1)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: WorkoutLabel(
                  'Superset · do these back-to-back, rest after both')),
      ],
      ...shown.map((e) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_view != 'compact')
              WorkoutDemonstrationPanel(exercise: e.exercise, compact: true),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: WorkoutLabel(workoutExerciseTitle(e.exercise.name),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4))),
              IconButton(
                  tooltip: 'Exercise details'.workoutTr(context),
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Navigator.push(
                      context,
                      WorkoutRoute(
                          builder: (_) =>
                              WorkoutExerciseDetail(exercise: e.exercise)))),
              PopupMenuButton<String>(
                  tooltip: (('Exercise actions')).workoutTr(context),
                  onSelected: (action) async {
                    final list = [...exercises], index = list.indexOf(e);
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
                                  s.workoutExerciseID == e.id && s.isWarmup)
                              .length;
                      await _editRichSet(e, n, warmup: true);
                    }
                    if (action == 'remove') {
                      list.remove(e);
                      await _changeExecution(list);
                    }
                    if (action == 'up' && index > 0) {
                      await _changeExecution(moveWorkoutGroup(list, index, -1));
                    }
                    if (action == 'down' && index < list.length - 1) {
                      await _changeExecution(moveWorkoutGroup(list, index, 1));
                    }
                    if (action == 'swap') {
                      if (!mounted) return;
                      final replacement = await Navigator.push<Exercise>(
                          context,
                          WorkoutRoute(
                              builder: (_) => const WorkoutExerciseLibrary(
                                  selecting: true)));
                      if (replacement == null) return;
                      list[index] = WorkoutExercise(
                          id: e.id,
                          exercise: replacement,
                          sets: e.sets,
                          reps: replacement.isTimed ? null : e.reps ?? 10,
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
                            value: 'add', child: WorkoutLabel('Add set')),
                        PopupMenuItem(
                            value: 'warmup',
                            child: WorkoutLabel('Add warm-up')),
                        PopupMenuItem(
                            value: 'swap',
                            child: WorkoutLabel('Swap exercise')),
                        PopupMenuItem(
                            value: 'up', child: WorkoutLabel('Move up')),
                        PopupMenuItem(
                            value: 'down', child: WorkoutLabel('Move down')),
                        PopupMenuItem(
                            value: 'remove',
                            child: WorkoutLabel('Remove exercise'))
                      ])
            ]),
            if (_view != 'compact') ...[
              Wrap(spacing: 5, runSpacing: 5, children: [
                _exerciseTag(e.exercise.muscleGroup),
                _exerciseTag(e.exercise.equipment),
                if (_previousBest(e) > 0)
                  _exerciseTag(
                      'Best: ${workoutValue(WorkoutService.displayWeight(_previousBest(e)))} ${WorkoutService.unit}'),
              ]),
              if (e.notes.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: WorkoutLabel(e.notes)),
              if (e.configuration['targetRpe'] != null ||
                  e.configuration['targetRir'] != null)
                WorkoutLabel(
                    'Target effort: ${e.configuration['targetRpe'] != null ? 'RPE ${e.configuration['targetRpe']}' : 'RIR ${e.configuration['targetRir']}'}'),
              if (_view != 'cards')
                WorkoutLabel(
                    'Plan: ${e.sets} × ${e.exercise.type == 'cardio' ? '${workoutValue((e.durationSeconds ?? 1200) / 60)} min @ ${e.configuration['speedKmh'] ?? 8} km/h' : e.exercise.isTimed ? '${e.durationSeconds} sec' : '${e.reps} reps'}'),
              if (e.recommendation['reason'] != null &&
                  e.recommendation['policy'] != 'off')
                WorkoutLabel(
                    'Progression: ${e.recommendation['reason'].toString().replaceAll('_', ' ')}',
                    style: const TextStyle(fontSize: 13)),
              if ((_session!.previous[e.exercise.id] ?? []).isNotEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: WorkoutLabel(
                        'Last time${_session!.previous[e.exercise.id]!.first.performedAt == null ? '' : ' (${workoutDate(_session!.previous[e.exercise.id]!.first.performedAt)})'}: ${_session!.previous[e.exercise.id]!.where((s) => !s.isWarmup).map((s) => _previousLabel(s, e)).join(', ')}',
                        style: const TextStyle(fontSize: 13)))
            ],
            if (e.supersetGroup.isNotEmpty)
              Chip(label: WorkoutLabel('Superset ${e.supersetGroup}')),
            const SizedBox(height: 12),
            Card(
                margin: EdgeInsets.zero,
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(children: [
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
                        if (e.exercise.isBodyweight && !e.hasPrescribedLoad)
                          const SizedBox(width: 48),
                        Expanded(
                            child: WorkoutLabel(
                                e.exercise.type == 'cardio'
                                    ? 'MIN'
                                    : e.exercise.isTimed
                                        ? 'SEC'
                                        : 'REPS',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11))),
                        if (e.exercise.type == 'cardio')
                          const Expanded(
                              child: WorkoutLabel('KM/H',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11))),
                        if (!e.exercise.isTimed &&
                            ['rpe', 'rir']
                                .contains(WorkoutService.preferences['effort']))
                          Expanded(
                              child: WorkoutLabel(
                                  '${WorkoutService.preferences['effort']}'
                                      .toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11))),
                        if (e.exercise.type == 'timed')
                          const SizedBox(width: 36),
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
                            previous: workoutPreviousSet(
                                e, _session!.previous[e.exercise.id] ?? [], n),
                            onStartTimed: e.exercise.type == 'timed'
                                ? _startTimedSet
                                : null,
                            workTimerRunning: _workSet != null,
                            busy: _saving,
                            onSave: _record,
                            draft: _rowDrafts['${e.id}:$n']
                                as Map<String, dynamic>?,
                            onDraft: (draft) {
                              _rowDrafts['${e.id}:$n'] = draft;
                              _remember();
                            },
                            onUndo: () => _undo(e, n),
                            onDetails: () => _editRichSet(e, n)),
                      Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          children: [
                            TextButton.icon(
                                onPressed: _saving ||
                                        e.sets <= 1 ||
                                        _session!.sets.any((s) =>
                                            s.workoutExerciseID == e.id &&
                                            s.setNumber == e.sets)
                                    ? null
                                    : () => _resizeSets(e, e.sets - 1),
                                icon: const Icon(Icons.remove, size: 16),
                                label: const WorkoutLabel('Remove set')),
                            TextButton.icon(
                                onPressed: _saving || e.sets >= 30
                                    ? null
                                    : () => _resizeSets(e, e.sets + 1),
                                icon: const Icon(Icons.add, size: 16),
                                label: const WorkoutLabel('Add set')),
                          ])
                    ]))),
            const SizedBox(height: 12),
          ])),
      if (_view == 'cards' && groups.isNotEmpty)
        Row(children: [
          TextButton.icon(
              onPressed: _saving || unitIndex == 0
                  ? null
                  : () => _navigateUnit(unitIndex - 1),
              icon: const Icon(Icons.chevron_left),
              label: const WorkoutLabel('Previous')),
          const Spacer(),
          TextButton.icon(
              onPressed: _saving || unitIndex == groups.length - 1
                  ? null
                  : () => _navigateUnit(unitIndex + 1),
              icon: const Icon(Icons.chevron_right),
              label: const WorkoutLabel('Next'))
        ]),
      OutlinedButton.icon(
          onPressed: _saving ? null : _addExercise,
          icon: const Icon(Icons.add),
          label: const WorkoutLabel('Add exercise')),
      TextButton(
          onPressed: _saving ? null : () => _finish(),
          child: WorkoutLabel(
              'Finish workout${_session!.sets.where((s) => !s.isWarmup).length >= _sequence.length && _sequence.isNotEmpty ? '' : ' early'}'))
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
    _effort.clear();
    if (_index >= _sequence.length) return;
    final (e, number, _) = _sequence[_index];
    final saved = _session!.sets
        .where((s) => s.workoutExerciseID == e.id && s.setNumber == number)
        .firstOrNull;
    final previous =
        workoutPreviousSet(e, _session!.previous[e.exercise.id] ?? [], number);
    final values = WorkoutSetPrefill(e, saved: saved, previous: previous);
    _prefilledWeight = values.weight;
    _addedLoad = values.weight > 0;
    _scale = WorkoutService.preferences['effort'] ?? 'off';
    _weight.text = workoutValue(WorkoutService.displayWeight(values.weight));
    _reps.text = '${values.reps}';
    _duration.text = '${values.seconds}';
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
    if (_saving || _index >= _sequence.length) return;
    final (e, number, _) = _sequence[_index];
    if (!_form.currentState!.validate()) return;
    final body = <String, dynamic>{
      'workoutExerciseID': e.id,
      'setNumber': number,
      'weight': e.supportsLoad
          ? (_prefilledWeight != null &&
                  _weight.text ==
                      workoutValue(
                          WorkoutService.displayWeight(_prefilledWeight!))
              ? _prefilledWeight
              : WorkoutService.storedWeight(double.parse(_weight.text)))
          : 0,
      'reps': e.exercise.isTimed ? null : int.parse(_reps.text),
      'durationSeconds': e.exercise.isTimed ? int.parse(_duration.text) : null,
      'rpe': !e.exercise.isTimed && _scale == 'rpe' && _effort.text.isNotEmpty
          ? double.parse(_effort.text)
          : null,
      'rir': !e.exercise.isTimed && _scale == 'rir' && _effort.text.isNotEmpty
          ? double.parse(_effort.text)
          : null,
      'details': _session!.sets
              .where(
                  (s) => s.workoutExerciseID == e.id && s.setNumber == number)
              .firstOrNull
              ?.details ??
          {},
    };
    if (await _record(body) && mounted) setState(_prefill);
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
    final yes = !cancel && !incomplete
        ? true
        : await workoutDialog<bool>(
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
                          child: WorkoutLabel(
                              cancel ? 'Cancel workout' : 'Finish'))
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
        _restUntil = null;
        _restPausedSeconds = 0;
        _workSet = null;
        _workWatch.stop();
        _workRunning = false;
      });
      _timerHost?.publish(null);
      await _updateRestAlert();
      if (_recovery) await WorkoutRecovery.draft(widget.sessionID, {});
      if (!mounted) return;
      if (cancel) {
        Navigator.pop(context);
        return;
      }
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => WorkoutScope(
              builder: (context) => PopScope(
                  canPop: false,
                  child: Dialog(
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: 300,
                              maxHeight:
                                  MediaQuery.sizeOf(context).height * .9),
                          child: WorkoutCompletionScreen(
                              summary: r,
                              session: _session,
                              inDialog: true))))));
      if (mounted) Navigator.pop(context);
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
          _restUntil = _now().add(Duration(seconds: _restPausedSeconds));
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
      await WorkoutRecovery.draft(widget.sessionID, _draft());
    }
    if (!mounted) return;
    setState(() => _allowLeave = true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final screen = PopScope(
        canPop: !_saving && (_allowLeave || s?.status != 'active'),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_saving) _leave();
        },
        child: WorkoutScaffold(
            bottomNavigationBar: _timerHost == null && _timerDisplay != null
                ? WorkoutTimerBar(timer: _timerDisplay!)
                : null,
            appBar: AppBar(
                centerTitle: true,
                toolbarHeight: 70,
                title: Column(children: [
                  WorkoutLabel(s?.dayName ?? WorkoutText.title),
                  if (s != null)
                    WorkoutLabel(
                        '${workoutClock(_now().difference(s.startedAt).inSeconds.clamp(0, 604800))} · ${s.sets.where((v) => !v.isWarmup).length}/${_sequence.length} sets',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w400))
                ]),
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
                                padding: const EdgeInsets.all(16),
                                children: [
                                    if (s.offline) const WorkoutOfflineNotice(),
                                    if (_view == 'guided')
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
                                    if (_view == 'guided')
                                      WorkoutLabel(
                                          '${s.sets.where((v) => !v.isWarmup).length} / ${_sequence.length} sets saved'),
                                    const SizedBox(height: 4),
                                    if (_view == 'guided' &&
                                        _index < _sequence.length)
                                      _currentCard(),
                                    if (_view != 'guided' ||
                                        s.exercises.isEmpty)
                                      ..._exerciseCards(),
                                    const SizedBox(height: 12),
                                    if (_view == 'guided')
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
    return '${e.exercise.isTimed ? e.exercise.type == 'cardio' ? '${workoutValue((s.durationSeconds ?? 0) / 60)} min · ${workoutValue((workoutNumber(s.details['distanceMeters']) ?? 0) / (s.durationSeconds ?? 1) * 3.6)} km/h' : '${s.durationSeconds} sec${(s.weight ?? 0) > 0 ? ' · $load' : ''}' : '$load × ${s.reps}'}${s.rpe == null ? '' : ' · RPE ${workoutValue(s.rpe)}'}${s.rir == null ? '' : ' · RIR ${s.rir}'}';
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
                        TextButton.icon(
                            onPressed: _saving || _workSet != null
                                ? null
                                : () {
                                    if (!_form.currentState!.validate()) return;
                                    _startTimedSet({
                                      'workoutExerciseID': e.id,
                                      'setNumber': number,
                                      'durationSeconds':
                                          int.parse(_duration.text),
                                      'weight': e.supportsLoad
                                          ? WorkoutService.storedWeight(
                                              double.parse(_weight.text))
                                          : 0,
                                      'reps': null,
                                      'details': <String, dynamic>{}
                                    });
                                  },
                            icon: const Icon(Icons.play_arrow),
                            label: const WorkoutLabel('Start set'))
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
                                integer: false,
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
  final WorkoutSession? session;
  final bool inDialog;
  const WorkoutCompletionScreen(
      {super.key, required this.summary, this.session, this.inDialog = false});
  @override
  Widget build(BuildContext context) {
    final seconds = workoutInt(summary['durationSeconds']);
    final content = ListView(
        shrinkWrap: inDialog,
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          WorkoutLabel('Workout complete!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _CompletionMetrics(metrics: {
            'Duration':
                '${seconds ~/ 60} min${seconds % 60 == 0 ? '' : ' ${seconds % 60} sec'}',
            'Volume':
                '${workoutValue(WorkoutService.displayWeight(workoutNumber(summary['volume']) ?? 0))} ${WorkoutService.unit}',
            'Sets': '${summary['setCount'] ?? 0}',
            'PRs':
                workoutInt(summary['newPRs']) > 0 ? '${summary['newPRs']}' : '—'
          }),
          for (final record in workoutRows(summary['loadRecords']))
            ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: WorkoutLabel('New PR: ${record['name']}'),
                subtitle: WorkoutLabel(
                    '${workoutValue(WorkoutService.displayWeight(workoutNumber(record['weight']) ?? 0))} ${WorkoutService.unit}')),
          for (final record in workoutRows(summary['estimatedRecords']))
            ListTile(
                leading: const Icon(Icons.show_chart),
                title: WorkoutLabel('Best estimated 1RM: ${record['name']}'),
                subtitle: WorkoutLabel(
                    '${workoutValue(WorkoutService.displayWeight(workoutNumber(record['estimated1RM']) ?? 0))} ${WorkoutService.unit}')),
          if (session != null) ...[
            const SizedBox(height: 16),
            WorkoutLabel('What you just trained',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            WorkoutMuscleCoverage(
                showList: false,
                showLegend: false,
                load: workoutMuscleCoverage(session!.exercises,
                    performed: session!.sets)),
          ],
          const SizedBox(height: 14),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const WorkoutLabel('Nice!')),
        ]);
    return inDialog ? content : WorkoutScaffold(body: content);
  }
}

class _CompletionMetrics extends StatelessWidget {
  const _CompletionMetrics({required this.metrics});
  final Map<String, String> metrics;
  @override
  Widget build(BuildContext context) {
    final entries = metrics.entries.toList();
    return Column(children: [
      for (var row = 0; row < entries.length; row += 2)
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var index = row;
                  index < row + 2 && index < entries.length;
                  index++) ...[
                if (index > row) const SizedBox(width: 12),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WorkoutLabel(entries[index].key,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                              const SizedBox(height: 6),
                              WorkoutLabel(entries[index].value,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600)),
                            ])))
              ]
            ]))
    ]);
  }
}
