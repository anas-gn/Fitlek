import 'workout_media.dart';
import 'workout_transfer.dart';
import 'workout_balance.dart';
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'workout_muscles.dart';
import 'workout_charts.dart';
import 'workout_bodyweight.dart';
import 'workout_calendar.dart';
import 'workout_set_row.dart';
import 'workout_builder.dart';
import '../../../services/apiService.dart';
import 'package:flutter/services.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  final int? clientID;
  const WorkoutHistoryScreen({super.key, this.clientID});
  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  Object? _error;
  bool _loading = true, _more = false;
  bool _offline = false;
  int _page = 1;
  int _total = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final page = more ? _page + 1 : 1;
    try {
      final r = await WorkoutService.get(
          '/history?page=$page${widget.clientID == null ? '' : '&clientID=${widget.clientID}'}');
      if (mounted) {
        setState(() {
          _history = more
              ? [..._history, ...workoutRows(r['data'])]
              : workoutRows(r['data']);
          _page = page;
          _more = r['hasMore'] == true;
          _total = workoutInt(r['total'] ?? _history.length);
          _offline = r['offline'] == true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      appBar: WorkoutPageHeader(
          textScale: MediaQuery.textScalerOf(context).scale(14) / 14,
          title: 'History',
          subtitle: '$_total workouts',
          back: true,
          actions: [
            IconButton(
                tooltip: 'Transfer workout history'.workoutTr(context),
                icon: const Icon(Icons.import_export),
                onPressed: () async {
                  await Navigator.push(
                      context,
                      WorkoutRoute(
                          builder: (_) => WorkoutTransferScreen(
                              clientID: widget.clientID)));
                  if (mounted) await _load();
                })
          ]),
      body: _error != null
          ? WorkoutFailure(error: _error!, retry: _load)
          : _loading && _history.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_offline) const WorkoutOfflineNotice(),
                        if (_history.isEmpty)
                          const Card(
                              child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: WorkoutLabel(
                                      'Completed workouts will appear here.'))),
                        ..._history.map((s) => Card(
                            child: ListTile(
                                leading: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.fitness_center,
                                        size: 16, color: Colors.white)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 2),
                                titleTextStyle: TextStyle(
                                    fontFamily: 'SirvyaWorkout',
                                    fontSize: 15,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                subtitleTextStyle: TextStyle(
                                    fontFamily: 'SirvyaWorkout',
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                                title:
                                    WorkoutLabel(s['prescription']['dayName']),
                                subtitle: WorkoutLabel('${workoutDate(s['startedAt'])} · ${(workoutInt(s['durationSeconds']) / 60).round()} min · ${s['summary']['setCount']} sets · ${workoutValue(WorkoutService.displayWeight(workoutNumber(s['summary']['volume']) ?? 0))} ${WorkoutService.unit}'),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () => Navigator.push(context, WorkoutRoute(builder: (_) => WorkoutHistoryDetail(sessionID: workoutInt(s['id']))))))),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else if (_more)
                          OutlinedButton(
                              onPressed: () => _load(more: true),
                              child: const WorkoutLabel('Load more')),
                      ])));
}

class WorkoutHistoryDetail extends StatefulWidget {
  final int sessionID;
  const WorkoutHistoryDetail({super.key, required this.sessionID});
  @override
  State<WorkoutHistoryDetail> createState() => _WorkoutHistoryDetailState();
}

class _WorkoutHistoryDetailState extends State<WorkoutHistoryDetail> {
  WorkoutSession? _session;
  Map<String, dynamic> _data = {};
  Object? _error;
  bool _client = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await WorkoutService.get('/sessions/${widget.sessionID}');
      final role = await ApiService.getRole();
      if (mounted) {
        setState(() {
          _data = r;
          _session = WorkoutSession.fromJson(r);
          _client = role == 'client';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push<bool>(context,
        WorkoutRoute(builder: (_) => _WorkoutHistoryEditor(data: _data)));
    if (result == true && mounted) await _load();
  }

  Future<void> _delete() async {
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const WorkoutLabel('Delete workout?'),
                content: const WorkoutLabel(
                    'This removes the saved workout and recalculates your statistics.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const WorkoutLabel('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const WorkoutLabel('Delete'))
                ]));
    if (yes != true) return;
    try {
      WorkoutService.checked(
          await ApiService.delete('/workout/sessions/${widget.sessionID}'));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _routine() async {
    final user = await ApiService.getUserData();
    if (!mounted || user == null) return;
    final p = WorkoutPlan.fromJson({
      'name': _session!.dayName,
      'clientID': user['id'],
      'status': 'draft',
      'days': [
        {
          'name': _session!.dayName,
          'exercises': _data['prescription']['exercises']
        }
      ]
    });
    await Navigator.push(
        context,
        WorkoutRoute(
            builder: (_) => WorkoutBuilderScreen(
                plan: p, personal: true, duplicate: true)));
  }

  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      appBar: AppBar(
          title: WorkoutLabel(_session?.dayName ?? WorkoutText.history),
          actions: [
            if (_client && _session != null)
              PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _edit();
                    if (v == 'delete') _delete();
                    if (v == 'routine') _routine();
                    if (v == 'copy') {
                      Clipboard.setData(ClipboardData(
                          text:
                              '${_session!.dayName}\n${_session!.sets.map((s) => 'Set ${s.setNumber}: ${workoutValue(WorkoutService.displayWeight(s.weight ?? 0))} ${WorkoutService.unit} × ${s.reps ?? s.durationSeconds}').join('\n')}'));
                    }
                  },
                  itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'edit', child: WorkoutLabel('Edit workout')),
                        PopupMenuItem(
                            value: 'routine',
                            child: WorkoutLabel('Save as routine')),
                        PopupMenuItem(
                            value: 'copy',
                            child: WorkoutLabel('Copy workout summary')),
                        PopupMenuItem(
                            value: 'delete',
                            child: WorkoutLabel('Delete workout'))
                      ])
          ]),
      body: _error != null
          ? WorkoutFailure(error: _error!, retry: _load)
          : _session == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(20), children: [
                  if (_session!.offline) const WorkoutOfflineNotice(),
                  WorkoutLabel(
                      '${_session!.planName} · ${workoutDate(_session!.startedAt)}',
                      style: Theme.of(context).textTheme.titleMedium),
                  Card(
                      child: ListTile(
                          title: WorkoutLabel(
                              '${(workoutInt(_data['durationSeconds']) / 60).round()} min · ${_data['summary']['setCount']} sets'),
                          subtitle: WorkoutLabel(
                              'Volume: ${workoutValue(WorkoutService.displayWeight(workoutNumber(_data['summary']['volume']) ?? 0))} ${WorkoutService.unit}'))),
                  if ((_data['notes'] ?? '').toString().isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: WorkoutLabel('${_data['notes']}')),
                  WorkoutMediaPanel(sessionID: widget.sessionID),
                  ..._session!.exercises.map((e) => Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                WorkoutLabel(e.exercise.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                WorkoutLabel(
                                    'Target: ${e.sets} × ${e.exercise.isTimed ? '${e.durationSeconds} sec' : '${e.reps} reps'}'),
                                if (e.configuration['targetRpe'] != null ||
                                    e.configuration['targetRir'] != null)
                                  WorkoutLabel(
                                      'Target effort: ${e.configuration['targetRpe'] != null ? 'RPE ${e.configuration['targetRpe']}' : 'RIR ${e.configuration['targetRir']}'}'),
                                if (_data['originalPrescription'] != null)
                                  Builder(builder: (context) {
                                    final original = workoutRows(
                                            _data['originalPrescription']
                                                ['exercises'])
                                        .where(
                                            (r) => workoutInt(r['id']) == e.id)
                                        .firstOrNull;
                                    if (original == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final targets = Map<String, dynamic>.from(
                                        original['originalTargets'] ??
                                            original);
                                    return WorkoutLabel(
                                        'Prescribed: ${targets['targetSets']} × ${e.exercise.isTimed ? '${targets['targetDurationSeconds']} sec' : '${targets['targetReps']} reps · ${workoutValue(WorkoutService.displayWeight(workoutNumber(targets['targetWeight']) ?? 0))} ${WorkoutService.unit}'}');
                                  }),
                                ..._session!.sets
                                    .where((s) => s.workoutExerciseID == e.id)
                                    .map((s) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title:
                                            WorkoutLabel('Set ${s.setNumber}'),
                                        subtitle: WorkoutLabel(
                                            '${e.exercise.isTimed ? '${s.durationSeconds} sec' : '${workoutValue(WorkoutService.displayWeight(s.weight ?? 0))} ${WorkoutService.unit} × ${s.reps}'}${s.rpe == null ? '' : ' · RPE ${workoutValue(s.rpe)}'}${s.rir == null ? '' : ' · RIR ${workoutValue(s.rir)}'}'))),
                              ])))),
                ]));
}

class WorkoutProgressScreen extends StatefulWidget {
  final int? clientID;
  final DateTime Function()? clock;
  const WorkoutProgressScreen({super.key, this.clientID, this.clock});
  @override
  State<WorkoutProgressScreen> createState() => _WorkoutProgressScreenState();
}

class _WorkoutHistoryEditor extends StatefulWidget {
  final Map<String, dynamic> data;
  const _WorkoutHistoryEditor({required this.data});
  @override
  State<_WorkoutHistoryEditor> createState() => _WorkoutHistoryEditorState();
}

class _WorkoutHistoryEditorState extends State<_WorkoutHistoryEditor> {
  late WorkoutSession _session;
  late List<Map<String, dynamic>> _sets;
  late DateTime _started;
  final _notes = TextEditingController(), _duration = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _saving = false, _excluded = false;
  @override
  void initState() {
    super.initState();
    _session = WorkoutSession.fromJson(widget.data);
    _sets = _session.sets.map((s) => s.toJson()).toList();
    _started = _session.startedAt;
    _notes.text = _session.notes;
    _duration.text = '${workoutInt(widget.data['durationSeconds'])}';
    _excluded = widget.data['excludedFromProgression'] == 1;
  }

  @override
  void dispose() {
    _notes.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final e =
        _session.exercises.firstWhere((e) => e.id == row['workoutExerciseID']);
    final result = await workoutSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (_) => WorkoutRichSetEditor(
            exercise: e,
            number: workoutInt(row['setNumber']),
            saved: WorkoutSet.fromJson(row),
            warmup: row['details']?['phase'] == 'warmup'));
    if (result != null && mounted) {
      setState(() => _sets[_sets.indexOf(row)] = result);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await WorkoutService.put('/sessions/${_session.id}/history', {
        'revision': _session.revision,
        'startedAt': _started.toUtc().toIso8601String(),
        'durationSeconds': int.parse(_duration.text),
        'notes': _notes.text,
        'excludedFromProgression': _excluded,
        'sets': _sets
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      appBar: AppBar(title: const WorkoutLabel('Edit workout')),
      body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: const WorkoutLabel('Workout date'),
                subtitle: WorkoutLabel(workoutDate(_started)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: _started,
                      firstDate: DateTime(1970),
                      lastDate: DateTime.now());
                  if (date != null && mounted) {
                    setState(() => _started = DateTime(date.year, date.month,
                        date.day, _started.hour, _started.minute));
                  }
                }),
            TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: (('Duration (sec)')).workoutTr(context)),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 0 || n > 604800
                      ? (((('Enter 0–604800 seconds').workoutTr(context))))
                      : null;
                }),
            const SizedBox(height: 12),
            TextFormField(
                controller: _notes,
                maxLines: 3,
                maxLength: 5000,
                decoration: InputDecoration(
                    labelText: (('Workout notes')).workoutTr(context))),
            SwitchListTile(
                title: const WorkoutLabel('Exclude from progression'),
                subtitle: const WorkoutLabel(
                    'Keep this workout in history and statistics.'),
                value: _excluded,
                onChanged: (v) => setState(() => _excluded = v)),
            ..._session.exercises.map((e) => Card(
                    child: Column(children: [
                  ListTile(title: WorkoutLabel(e.exercise.name)),
                  ..._sets.where((s) => s['workoutExerciseID'] == e.id).map(
                      (s) => ListTile(
                          title: WorkoutLabel('Set ${s['setNumber']}'),
                          subtitle: WorkoutLabel(e.exercise.isTimed
                              ? '${s['durationSeconds']} sec'
                              : '${s['weight']} ${WorkoutService.unit} × ${s['reps']}'),
                          onTap: () => _edit(s),
                          trailing: IconButton(
                              tooltip: (('Remove set')).workoutTr(context),
                              onPressed: () => setState(() => _sets.remove(s)),
                              icon: const Icon(Icons.close))))
                ]))),
            ElevatedButton(
                onPressed: _saving ? null : _save,
                child: WorkoutLabel(_saving ? 'Saving…' : 'Save workout'))
          ])));
}

class _WorkoutProgressScreenState extends State<WorkoutProgressScreen> {
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  Map<String, dynamic>? _stats, _muscleStats, _effortStats;
  List<Map<String, dynamic>> _recent = [];
  Object? _error;
  int _days = 90, _muscleDays = 7, _effortDays = 90;
  int _muscleRequest = 0, _effortRequest = 0;
  bool _muscleLoading = false, _effortLoading = false;
  bool _hardMuscles = false;
  final String _heatmap = 'durationSeconds';
  String _metric = 'weight';
  int? _exerciseID;
  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _clientQuery =>
      widget.clientID == null ? '' : 'clientID=${widget.clientID}';

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        WorkoutService.get('/stats?$_clientQuery'),
        WorkoutService.get(
            '/history?page=1${widget.clientID == null ? '' : '&clientID=${widget.clientID}'}'),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0];
          _recent = workoutRows(results[1]['data']).take(6).toList();
        });
        await Future.wait([_loadMuscles(), _loadEffort()]);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadMuscles() async {
    final request = ++_muscleRequest;
    setState(() => _muscleLoading = true);
    try {
      final value = _muscleDays == 0
          ? _stats!
          : await WorkoutService.get(
              '/stats?${_muscleDays == 7 ? 'window=week' : 'days=$_muscleDays'}&$_clientQuery');
      if (mounted && request == _muscleRequest) {
        setState(() => _muscleStats = value);
      }
    } catch (error) {
      if (mounted && request == _muscleRequest) workoutError(context, error);
    } finally {
      if (mounted && request == _muscleRequest) {
        setState(() => _muscleLoading = false);
      }
    }
  }

  Future<void> _loadEffort() async {
    final request = ++_effortRequest;
    setState(() => _effortLoading = true);
    try {
      final value = _effortDays == 0
          ? _stats!
          : await WorkoutService.get('/stats?days=$_effortDays&$_clientQuery');
      if (mounted && request == _effortRequest) {
        setState(() => _effortStats = value);
      }
    } catch (error) {
      if (mounted && request == _effortRequest) workoutError(context, error);
    } finally {
      if (mounted && request == _effortRequest) {
        setState(() => _effortLoading = false);
      }
    }
  }

  Widget _range(int selected, ValueChanged<int> change,
          {bool week = false, bool weight = false}) =>
      Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: WorkoutSegments<int>(
              selected: selected,
              onChanged: change,
              choices: {
                if (week) 7: 'Week',
                30: weight ? '1M' : '30d',
                90: weight ? '3M' : '90d',
                if (!week) 365: '1Y',
                0: 'All'
              }));

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return WorkoutScaffold(
        maxWidth: 1100,
        appBar: WorkoutPageHeader(
            textScale: MediaQuery.textScalerOf(context).scale(14) / 14,
            title: 'Stats',
            subtitle: 'Progress & history',
            back: widget.clientID != null,
            actions: [
              IconButton(
                  tooltip: 'History'.workoutTr(context),
                  icon: const Icon(Icons.history),
                  onPressed: () => Navigator.push(
                      context,
                      WorkoutRoute(
                          builder: (_) =>
                              WorkoutHistoryScreen(clientID: widget.clientID))))
            ]),
        body: _error != null
            ? WorkoutFailure(error: _error!, retry: _load)
            : stats == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (stats['offline'] == true)
                            const WorkoutOfflineNotice(),
                          WorkoutMetricGrid(valueColors: {
                            if (workoutNumber(stats['overview']
                                        ?['bodyweightDelta30']) !=
                                    null &&
                                workoutNumber(stats['overview']
                                        ?['bodyweightDelta30']) !=
                                    0)
                              'Weight 30d': _weightDeltaColor(stats),
                          }, metrics: {
                            'Workouts':
                                '${stats['overview']?['workoutCount'] ?? stats['workoutCount'] ?? 0}',
                            'This month':
                                '${stats['overview']?['monthWorkouts'] ?? 0}',
                            'Week streak':
                                '${stats['overview']?['weeklyStreak'] ?? stats['currentWeeklyStreak'] ?? 0}',
                            'Weight 30d': stats['overview']
                                        ?['bodyweightDelta30'] ==
                                    null
                                ? '—'
                                : '${workoutNumber(stats['overview']['bodyweightDelta30'])! > 0 ? '+' : ''}${workoutValue(WorkoutService.displayWeight(workoutNumber(stats['overview']['bodyweightDelta30'])!))} ${WorkoutService.unit}',
                          }),
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const WorkoutLabel(
                                            'Activity — last 12 months · by time trained',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xff8e8e93))),
                                        const SizedBox(height: 12),
                                        WorkoutActivityGrid(
                                            today: _now,
                                            days: 365,
                                            activity: workoutRows(
                                                stats['yearActivity'] ??
                                                    stats['activity']),
                                            metric: _heatmap,
                                            onDay: (date) =>
                                                workoutOpenRecordedDate(
                                                    context,
                                                    date,
                                                    workoutRows(stats[
                                                            'yearActivity'] ??
                                                        stats['activity']))),
                                      ]))),
                          if (workoutInt(stats['workoutCount']) > 0)
                            _muscleCard(_muscleStats ?? stats),
                          if (workoutInt(stats['effortSummary']?['rated']) > 0)
                            _effortCard(_effortStats ?? stats),
                          WorkoutColumns(
                              first: WorkoutBodyweightCard(
                                  readings: workoutRows(stats['bodyweight'])
                                      .where((r) =>
                                          _days == 0 ||
                                          DateTime.tryParse(
                                                      '${r['recordedAt']}')
                                                  ?.isAfter(_now.subtract(
                                                      Duration(days: _days))) ==
                                              true)
                                      .toList(),
                                  goal: workoutNumber(stats['bodyweightGoal']),
                                  reload:
                                      widget.clientID == null ? _load : null,
                                  limit: null,
                                  controls: _range(
                                      _days, (v) => setState(() => _days = v),
                                      weight: true)),
                              second: _exerciseChart(stats)),
                          if (_recent.isNotEmpty) ...[
                            Row(children: [
                              const Expanded(
                                  child: WorkoutLabel('Recent workouts',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))),
                              TextButton(
                                  onPressed: () => Navigator.push(
                                      context,
                                      WorkoutRoute(
                                          builder: (_) => WorkoutHistoryScreen(
                                              clientID: widget.clientID))),
                                  child: WorkoutLabel(
                                      'All ${stats['workoutCount']}'))
                            ]),
                            Card(
                                child: Column(
                                    children: _recent
                                        .map((s) => ListTile(
                                            title: WorkoutLabel(
                                                '${s['prescription']?['dayName'] ?? 'Workout'}'),
                                            subtitle: WorkoutLabel(
                                                '${workoutDate(s['startedAt'])} · ${(workoutInt(s['durationSeconds']) / 60).round()} min · ${s['summary']?['setCount'] ?? 0} sets'),
                                            trailing:
                                                const Icon(Icons.chevron_right),
                                            onTap: () => Navigator.push(
                                                context,
                                                WorkoutRoute(
                                                    builder: (_) =>
                                                        WorkoutHistoryDetail(
                                                            sessionID:
                                                                workoutInt(s[
                                                                    'id']))))))
                                        .toList())),
                          ],
                          ExpansionTile(
                              title: const WorkoutLabel('Training tools'),
                              children: [
                                WorkoutBalanceCard(
                                    clientID: widget.clientID,
                                    records: workoutRows(stats['records'])),
                                if (stats['adherence'] != null)
                                  ListTile(
                                      title: WorkoutLabel(
                                          'Schedule adherence: ${stats['adherence']['percent'] ?? '—'}%'),
                                      subtitle: WorkoutLabel(
                                          '${stats['adherence']['performed']} / ${stats['adherence']['expected']} scheduled routines completed · based on your current schedule')),
                              ]),
                        ])));
  }

  Color _weightDeltaColor(Map<String, dynamic> stats) {
    final delta = workoutNumber(stats['overview']?['bodyweightDelta30']) ?? 0;
    final readings = workoutWeightReadings(stats['bodyweight']);
    final current =
        readings.isEmpty ? 0.0 : workoutNumber(readings.last['weight']) ?? 0;
    final toward = workoutWeightMovesTowardGoal(
        current - delta, current, workoutNumber(stats['bodyweightGoal']));
    return (toward ?? delta < 0)
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
  }

  Widget _muscleCard(Map<String, dynamic> stats) {
    final muscles = workoutRows(stats['muscles']);
    final load = {
      for (final m in muscles)
        '${m['name']}':
            workoutNumber(m[_hardMuscles ? 'hardSets' : 'sets']) ?? 0
    };
    final missed =
        workoutMuscleNames.where((m) => (load[m] ?? 0) == 0).toList();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: WorkoutLabel(
                        _hardMuscles
                            ? 'Muscle balance · by hard sets'
                            : 'Muscle balance · by sets worked',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xff8e8e93)))),
                if (workoutInt(stats['hardSets']) > 0)
                  TextButton.icon(
                      icon: const Icon(Icons.local_fire_department_outlined,
                          size: 16),
                      label: WorkoutLabel(_hardMuscles ? 'Hard' : 'All'),
                      onPressed: () =>
                          setState(() => _hardMuscles = !_hardMuscles))
              ]),
              _range(_muscleDays, (v) {
                setState(() {
                  _muscleDays = v;
                  _hardMuscles = false;
                });
                _loadMuscles();
              }, week: true),
              if (_muscleLoading) const LinearProgressIndicator(),
              if (workoutInt(stats['workoutCount']) == 0)
                const WorkoutLabel('No workouts in this period yet.')
              else ...[
                WorkoutMuscleCoverage(load: load, showList: false),
                for (final m
                    in muscles.where((m) => (load[m['name']] ?? 0) > 0).take(4))
                  ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: WorkoutLabel('${m['name']}'),
                      trailing: WorkoutLabel(
                          '${workoutValue(load[m['name']])} sets')),
                if (missed.isNotEmpty) ...[
                  WorkoutLabel(_hardMuscles
                      ? 'No hard sets in this period'
                      : 'Not trained in this period'),
                  Wrap(
                      spacing: 6,
                      children: missed
                          .map((m) => Chip(label: WorkoutLabel(m)))
                          .toList()),
                ] else
                  const WorkoutLabel(
                      'Every muscle group got some work in this period.'),
              ],
            ])));
  }

  Widget _effortCard(Map<String, dynamic> stats) {
    final summary = Map<String, dynamic>.from(stats['effortSummary'] ?? {});
    final scale = ['rpe', 'rir'].contains(WorkoutService.preferences['effort'])
        ? WorkoutService.preferences['effort']
        : summary['preferredScale'] ?? 'rir';
    final rpe = scale == 'rpe';
    final weeks = workoutRows(summary['weeks']);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const WorkoutLabel('Effort · how close to failure',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              _range(_effortDays, (v) {
                setState(() => _effortDays = v);
                _loadEffort();
              }),
              if (_effortLoading) const LinearProgressIndicator(),
              if (workoutInt(summary['rated']) == 0)
                const WorkoutLabel('No rated sets in this period.'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: WorkoutMetric(
                        summary['averageRir'] == null
                            ? '—'
                            : '${workoutValue(rpe ? 10 - workoutNumber(summary['averageRir'])! : workoutNumber(summary['averageRir']))} ${rpe ? 'RPE' : 'RIR'}',
                        'Average effort')),
                Expanded(
                    child: WorkoutMetric(
                        summary['hardPercent'] == null
                            ? '—'
                            : '${summary['hardPercent']}%',
                        'At RIR 3 or harder'))
              ]),
              const SizedBox(height: 12),
              WorkoutLabel(
                  '${summary['rated']} of ${summary['done']} finished working sets rated'),
              if (workoutInt(summary['rated']) < 5)
                const WorkoutLabel(
                    'At least 5 rated sets are needed for an average.'),
              if (weeks.isNotEmpty)
                WorkoutLineChart(
                    label: 'Weekly effort',
                    invert: !rpe,
                    color: Colors.amber,
                    unit: rpe ? 'RPE' : 'RIR',
                    values: weeks
                        .map((w) => rpe
                            ? 10 - workoutNumber(w['rir'])!
                            : workoutNumber(w['rir'])!)
                        .toList(),
                    dates: weeks
                        .map((w) => DateTime.parse('${w['date']}'))
                        .toList()),
              const SizedBox(height: 12),
              const WorkoutLabel('Where the sets land'),
              for (final bin in workoutRows(summary['histogram']))
                ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: WorkoutLabel(
                        '${rpe ? 'RPE' : 'RIR'} ${bin['tail'] == true ? rpe ? '≤ 6' : '4+' : rpe ? 10 - workoutInt(bin['rir']) : bin['rir']}'),
                    trailing:
                        WorkoutLabel('${bin['count']} · ${bin['percent']}%'))
            ])));
  }

  Widget _exerciseChart(Map<String, dynamic> stats) {
    final records = workoutRows(stats['records']);
    if (records.isEmpty) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WorkoutLabel('Exercise progress',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    WorkoutLabel(
                        'Finish your first workout to see progress curves here.')
                  ])));
    }
    records.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    if (!records.any((r) => workoutInt(r['exerciseID']) == _exerciseID)) {
      _exerciseID = workoutInt(records.first['exerciseID']);
    }
    final record = records
            .firstWhere((r) => workoutInt(r['exerciseID']) == _exerciseID),
        timed = record['exerciseType'] != 'reps';
    final metrics = timed
        ? {
            'durationSeconds': 'Longest hold',
            if (record['exerciseType'] == 'cardio')
              'distanceMeters': 'Distance (metres)',
            if (record['exerciseType'] == 'cardio') 'speedKmh': 'Speed (km/h)'
          }
        : {
            'weight': 'Load',
            'reps': 'Reps',
            'volume': 'Volume',
            if (record['estimated1RM'] != null) 'estimated1RM': 'Estimated 1RM'
          };
    final points = workoutRows(record['points'])
        .where((p) =>
            p['exerciseType'] == null ||
            p['exerciseType'] == record['exerciseType'])
        .toList();
    final effortPoints = workoutRows(stats['effortSummary']?['exercisePoints'])
        .where((p) => workoutInt(p['exerciseID']) == _exerciseID)
        .toList();
    if (effortPoints.length >= 3) metrics['effort'] = 'Effort';
    if (!metrics.containsKey(_metric)) {
      _metric =
          record['exerciseType'] == 'cardio' ? 'speedKmh' : metrics.keys.first;
    }
    final primaryMetrics = <String, String>{
      record['exerciseType'] == 'cardio'
          ? 'speedKmh'
          : timed
              ? 'durationSeconds'
              : 'weight': 'Top set',
      if (metrics.containsKey('estimated1RM')) 'estimated1RM': 'Estimated 1RM',
      if (metrics.containsKey('effort')) 'effort': 'Effort',
    };
    final rpe = WorkoutService.preferences['effort'] == 'rpe';
    final curve = _metric == 'effort'
        ? effortPoints
        : points
            .where((p) =>
                p[_metric] != null && (workoutNumber(p[_metric]) ?? 0) > 0)
            .toList();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (record['relativeStrength'] != null)
                WorkoutLabel(
                    'Estimated 1RM / body weight: ${workoutValue(workoutNumber(record['relativeStrength']))}×'),
              DropdownButtonFormField<int>(
                  initialValue: _exerciseID,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: (('Exercise progress')).workoutTr(context)),
                  items: records
                      .map((r) => DropdownMenuItem(
                          value: workoutInt(r['exerciseID']),
                          child: WorkoutLabel('${r['name']}',
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _exerciseID = v)),
              const SizedBox(height: 12),
              if (primaryMetrics.length > 1)
                WorkoutSegments<String>(
                    selected: [
                      'weight',
                      'durationSeconds',
                      'speedKmh',
                      'estimated1RM',
                      'effort'
                    ].contains(_metric)
                        ? _metric
                        : record['exerciseType'] == 'cardio'
                            ? 'speedKmh'
                            : timed
                                ? 'durationSeconds'
                                : 'weight',
                    choices: primaryMetrics,
                    onChanged: (value) => setState(() => _metric = value)),
              ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const WorkoutLabel('More progress metrics',
                      style: TextStyle(fontSize: 13)),
                  children: [
                    Wrap(
                        spacing: 6,
                        children: metrics.entries
                            .map((e) => ChoiceChip(
                                label: WorkoutLabel(e.value),
                                selected: _metric == e.key,
                                onSelected: (_) =>
                                    setState(() => _metric = e.key)))
                            .toList())
                  ]),
              const SizedBox(height: 16),
              WorkoutLineChart(
                  label: metrics[_metric]!,
                  invert: _metric == 'effort' && !rpe,
                  color: _metric == 'effort' ? Colors.amber : Colors.blue,
                  values: curve
                      .map((p) => _metric == 'effort'
                          ? (rpe
                              ? 10 - workoutNumber(p['rir'])!
                              : workoutNumber(p['rir'])!)
                          : ['weight', 'volume', 'estimated1RM']
                                  .contains(_metric)
                              ? WorkoutService.displayWeight(
                                  workoutNumber(p[_metric]) ?? 0)
                              : workoutNumber(p[_metric]) ?? 0)
                      .toList(),
                  dates:
                      curve.map((p) => DateTime.parse('${p['date']}')).toList(),
                  unit: _metric == 'effort'
                      ? (rpe ? 'RPE' : 'RIR')
                      : ['weight', 'volume', 'estimated1RM'].contains(_metric)
                          ? WorkoutService.unit
                          : _metric == 'durationSeconds'
                              ? 'sec'
                              : _metric == 'speedKmh'
                                  ? 'km/h'
                                  : _metric == 'distanceMeters'
                                      ? 'm'
                                      : 'reps'),
              if (_metric == 'estimated1RM' &&
                  record['estimated1RMSource'] is Map)
                ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: WorkoutLabel(
                        'Best estimated 1RM: ${workoutValue(WorkoutService.displayWeight(workoutNumber(record['estimated1RM']) ?? 0))} ${WorkoutService.unit}'),
                    subtitle: WorkoutLabel(
                        '${workoutValue(WorkoutService.displayWeight(workoutNumber(record['estimated1RMSource']['weight']) ?? 0))} ${WorkoutService.unit} × ${record['estimated1RMSource']['reps']} · ${workoutDate(record['estimated1RMSource']['date'])}'),
                    onTap: () => Navigator.push(
                        context,
                        WorkoutRoute(
                            builder: (_) => WorkoutHistoryDetail(
                                sessionID: workoutInt(
                                    record['estimated1RMSource']
                                        ['sessionID']))))),
              for (final p in points.reversed.take(5))
                ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: WorkoutLabel(workoutDate(p['date'])),
                    subtitle: WorkoutLabel(timed
                        ? '${p['durationSeconds']} sec${record['exerciseType'] == 'cardio' ? ' · ${workoutValue(workoutNumber(p['speedKmh']))} km/h' : ''}'
                        : '${workoutValue(WorkoutService.displayWeight(workoutNumber(p['weight']) ?? 0))} ${WorkoutService.unit} × ${p['reps']}'),
                    onTap: () => Navigator.push(
                        context,
                        WorkoutRoute(
                            builder: (_) => WorkoutHistoryDetail(
                                sessionID: workoutInt(p['sessionID']))))),
            ])));
  }
}
