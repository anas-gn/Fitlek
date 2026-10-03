import 'workout_media.dart';
import 'workout_transfer.dart';
import 'workout_balance.dart';
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'workout_charts.dart';
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
      appBar: AppBar(title: const WorkoutLabel(WorkoutText.history), actions: [
        IconButton(
            tooltip: 'Transfer workout history'.workoutTr(context),
            icon: const Icon(Icons.import_export),
            onPressed: () async {
              await Navigator.push(
                  context,
                  WorkoutRoute(
                      builder: (_) =>
                          WorkoutTransferScreen(clientID: widget.clientID)));
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
                      padding: const EdgeInsets.all(20),
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
                                leading: const Icon(Icons.history_rounded),
                                title:
                                    WorkoutLabel(s['prescription']['dayName']),
                                subtitle: WorkoutLabel(
                                    '${workoutDate(s['startedAt'])} · ${(workoutInt(s['durationSeconds']) / 60).round()} min\n${s['summary']['setCount']} sets · ${workoutValue(workoutNumber(s['summary']['volume']))} kg'),
                                trailing:
                                    const Icon(Icons.chevron_right_rounded),
                                onTap: () => Navigator.push(
                                    context,
                                    WorkoutRoute(
                                        builder: (_) => WorkoutHistoryDetail(
                                            sessionID:
                                                workoutInt(s['id']))))))),
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
                              '${_session!.dayName}\n${_session!.sets.map((s) => 'Set ${s.setNumber}: ${s.weight ?? 0} kg × ${s.reps ?? s.durationSeconds}').join('\n')}'));
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
                              'Volume: ${workoutValue(workoutNumber(_data['summary']['volume']))} kg'))),
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
                                        'Prescribed: ${targets['targetSets']} × ${e.exercise.isTimed ? '${targets['targetDurationSeconds']} sec' : '${targets['targetReps']} reps · ${workoutValue(workoutNumber(targets['targetWeight']))} kg'}');
                                  }),
                                ..._session!.sets
                                    .where((s) => s.workoutExerciseID == e.id)
                                    .map((s) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title:
                                            WorkoutLabel('Set ${s.setNumber}'),
                                        subtitle: WorkoutLabel(
                                            '${e.exercise.isTimed ? '${s.durationSeconds} sec' : '${workoutValue(s.weight)} kg × ${s.reps}'}${s.rpe == null ? '' : ' · RPE ${workoutValue(s.rpe)}'}${s.rir == null ? '' : ' · RIR ${s.rir}'}'))),
                              ])))),
                ]));
}

class WorkoutProgressScreen extends StatefulWidget {
  final int? clientID;
  const WorkoutProgressScreen({super.key, this.clientID});
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
                              : '${s['weight']} kg × ${s['reps']}'),
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
  Map<String, dynamic>? _stats;
  Object? _error;
  int _days = 90;
  String _heatmap = 'durationSeconds', _metric = 'weight';
  int? _exerciseID;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await WorkoutService.get(
          '/stats?days=$_days${widget.clientID == null ? '' : '&clientID=${widget.clientID}'}');
      if (mounted) setState(() => _stats = r);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return WorkoutScaffold(
        appBar: AppBar(title: const WorkoutLabel(WorkoutText.progress)),
        body: _error != null
            ? WorkoutFailure(error: _error!, retry: _load)
            : stats == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (stats['offline'] == true)
                            const WorkoutOfflineNotice(),
                          SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(
                                    value: 30, label: WorkoutLabel('30 days')),
                                ButtonSegment(
                                    value: 90, label: WorkoutLabel('90 days')),
                                ButtonSegment(
                                    value: 365, label: WorkoutLabel('Year'))
                              ],
                              selected: {
                                _days
                              },
                              onSelectionChanged: (v) {
                                setState(() => _days = v.first);
                                _load();
                              }),
                          const SizedBox(height: 16),
                          if (stats['adherence'] != null)
                            Card(
                                child: ListTile(
                                    leading: const Icon(Icons.event_available),
                                    title: WorkoutLabel(
                                        'Schedule adherence: ${stats['adherence']['percent'] ?? '—'}%'),
                                    subtitle: WorkoutLabel(
                                        '${stats['adherence']['performed']} / ${stats['adherence']['expected']} scheduled routines completed\nMeasured against your current schedule.'))),
                          Card(
                              child: ListTile(
                                  leading: const Icon(
                                      Icons.local_fire_department_outlined),
                                  title: WorkoutLabel(
                                      'Training streak: ${stats['currentStreak'] ?? 0} days'),
                                  subtitle: WorkoutLabel(
                                      'Longest streak: ${stats['longestStreak'] ?? 0} days · ${stats['prCount'] ?? 0} record events'))),
                          if (stats['workload'] != null)
                            Card(
                                child: ListTile(
                                    title: const WorkoutLabel(
                                        'Recent training load'),
                                    subtitle: WorkoutLabel(
                                        'Last 7 days: ${stats['workload']['recentSets']} sets\nPrevious 7 days: ${stats['workload']['previousSets']} sets'))),
                          Card(
                              child: ListTile(
                                  title: WorkoutLabel(
                                      '${stats['workoutCount']} workouts · ${stats['setCount']} sets'),
                                  subtitle: WorkoutLabel(
                                      'Total volume: ${workoutValue(workoutNumber(stats['volume']))} kg'))),
                          const SizedBox(height: 16),
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: WorkoutMetric(
                                                '${(workoutInt(stats['totalDurationSeconds']) / 3600).toStringAsFixed(1)} h',
                                                'Training time')),
                                        Expanded(
                                            child: WorkoutMetric(
                                                '${stats['totalReps'] ?? 0}',
                                                'Repetitions')),
                                        Expanded(
                                            child: WorkoutMetric(
                                                '${stats['hardSets'] ?? 0}',
                                                'Hard sets'))
                                      ]))),
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(children: [
                                    Row(children: [
                                      const Expanded(
                                          child: WorkoutLabel('Activity')),
                                      DropdownButton<String>(
                                          value: _heatmap,
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'durationSeconds',
                                                child: WorkoutLabel('Time')),
                                            DropdownMenuItem(
                                                value: 'volume',
                                                child: WorkoutLabel('Volume'))
                                          ],
                                          onChanged: (v) =>
                                              setState(() => _heatmap = v!))
                                    ]),
                                    WorkoutActivityGrid(
                                        days: _days,
                                        activity:
                                            workoutRows(stats['activity']),
                                        metric: _heatmap)
                                  ]))),
                          _exerciseChart(stats),
                          WorkoutBalanceCard(
                              records: workoutRows(stats['records'])),
                          if (stats['effortDistribution'] != null)
                            ...['rpe', 'rir'].map((scale) {
                              final values = Map<String, dynamic>.from(
                                  stats['effortDistribution'][scale] ?? {});
                              return values.isEmpty
                                  ? const SizedBox.shrink()
                                  : Card(
                                      child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                WorkoutLabel(
                                                    '${scale.toUpperCase()} distribution',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium),
                                                Wrap(
                                                    spacing: 8,
                                                    children: values.entries
                                                        .map((v) => Chip(
                                                            label: WorkoutLabel(
                                                                '${scale.toUpperCase()} ${v.key}: ${v.value} sets')))
                                                        .toList())
                                              ])));
                            }),
                          if (workoutRows(stats['bodyweight']).isNotEmpty)
                            Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const WorkoutLabel('Body weight',
                                              style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 16),
                                          if (stats['bodyweightGoal'] != null)
                                            WorkoutLabel(
                                                'Goal: ${workoutValue(WorkoutService.displayWeight(workoutNumber(stats['bodyweightGoal'])!))} ${WorkoutService.unit}'),
                                          WorkoutLineChart(
                                              label: 'Body weight',
                                              values: workoutRows(
                                                      stats['bodyweight'])
                                                  .map((r) =>
                                                      workoutNumber(
                                                          r['weight']) ??
                                                      0)
                                                  .toList())
                                        ]))),
                          if (workoutRows(stats['muscles']).isNotEmpty)
                            Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const WorkoutLabel('Muscle balance',
                                              style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 12),
                                          ...workoutRows(stats['muscles']).map(
                                              (m) => Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  child: Column(children: [
                                                    Row(children: [
                                                      Expanded(
                                                          child: WorkoutLabel(
                                                              '${m['name']}')),
                                                      WorkoutLabel(
                                                          '${m['sets']} sets · ${m['hardSets']} hard')
                                                    ]),
                                                    const SizedBox(height: 6),
                                                    LinearProgressIndicator(
                                                        value: (workoutInt(
                                                                    m['sets']) /
                                                                (workoutInt(stats[
                                                                            'setCount']) ==
                                                                        0
                                                                    ? 1
                                                                    : workoutInt(
                                                                        stats[
                                                                            'setCount'])))
                                                            .clamp(0, 1))
                                                  ])))
                                        ]))),
                          WorkoutLabel('Workout frequency',
                              style: Theme.of(context).textTheme.titleLarge),
                          if (workoutRows(stats['frequency']).isEmpty)
                            const WorkoutLabel(
                                'Complete a workout to see your progress.'),
                          ..._weeks(workoutRows(stats['frequency']))
                              .entries
                              .map((e) => Card(
                                  child: ListTile(
                                      title: WorkoutLabel(
                                          'Week of ${workoutDate(e.key)}'),
                                      trailing: WorkoutLabel(
                                          '${e.value} workouts')))),
                          const SizedBox(height: 24),
                          WorkoutLabel('Personal records',
                              style: Theme.of(context).textTheme.titleLarge),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: WorkoutLabel(
                                  'Estimated 1RM uses loaded repetition sets of 1–12 reps. Bodyweight and timed exercises use reps or duration.')),
                          ...workoutRows(stats['records']).map((r) => Card(
                              child: ExpansionTile(
                                  title: WorkoutLabel('${r['name']}'),
                                  subtitle: WorkoutLabel(r['exerciseType'] !=
                                          'reps'
                                      ? 'Longest set: ${r['durationSeconds']} sec'
                                      : r['isBodyweight'] == 1 ||
                                              r['isBodyweight'] == true
                                          ? 'Best repetitions: ${r['reps']}'
                                          : 'Heaviest: ${workoutValue(workoutNumber(r['weight']))} kg · Est. 1RM: ${workoutValue(workoutNumber(r['estimated1RM']))} kg'),
                                  children: workoutRows(r['points'])
                                      .reversed
                                      .map((p) => ListTile(
                                          title: WorkoutLabel(
                                              workoutDate(p['date'])),
                                          subtitle: WorkoutLabel(
                                              r['exerciseType'] != 'reps'
                                                  ? '${p['durationSeconds']} sec'
                                                  : '${workoutValue(workoutNumber(p['weight']))} kg · ${p['reps']} reps · ${workoutValue(workoutNumber(p['volume']))} kg volume'),
                                          onTap: () => Navigator.push(
                                              context,
                                              WorkoutRoute(
                                                  builder: (_) => WorkoutHistoryDetail(
                                                      sessionID: workoutInt(p['sessionID']))))))
                                      .toList()))),
                        ])));
  }

  Widget _exerciseChart(Map<String, dynamic> stats) {
    final records = workoutRows(stats['records']);
    if (records.isEmpty) return const SizedBox.shrink();
    if (!records.any((r) => workoutInt(r['exerciseID']) == _exerciseID)) {
      _exerciseID = workoutInt(records.first['exerciseID']);
    }
    final record = records
            .firstWhere((r) => workoutInt(r['exerciseID']) == _exerciseID),
        timed = record['exerciseType'] != 'reps';
    final metrics = timed
        ? {
            'durationSeconds': 'Duration',
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
    if (!metrics.containsKey(_metric)) _metric = metrics.keys.first;
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
              Wrap(
                  spacing: 6,
                  children: metrics.entries
                      .map((e) => ChoiceChip(
                          label: WorkoutLabel(e.value),
                          selected: _metric == e.key,
                          onSelected: (_) => setState(() => _metric = e.key)))
                      .toList()),
              const SizedBox(height: 16),
              WorkoutLineChart(
                  label: metrics[_metric]!,
                  values: workoutRows(record['points'])
                      .where((p) => p[_metric] != null)
                      .map((p) => workoutNumber(p[_metric]) ?? 0)
                      .toList())
            ])));
  }

  Map<String, int> _weeks(List<Map<String, dynamic>> frequency) {
    final weeks = <String, int>{};
    for (final f in frequency) {
      final d = DateTime.parse(f['date']);
      final monday = d
          .subtract(Duration(days: d.weekday - 1))
          .toIso8601String()
          .substring(0, 10);
      weeks[monday] = (weeks[monday] ?? 0) + workoutInt(f['count']);
    }
    return Map.fromEntries(weeks.entries.toList().reversed.take(12));
  }
}
