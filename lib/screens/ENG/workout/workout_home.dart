import '../../../services/notification_service.dart';
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'workout_ui.dart';
import 'exercise_library.dart';
import 'active_workout.dart';
import 'workout_progress.dart';
import 'workout_builder.dart';
import 'workout_preferences.dart';
import 'workout_tools.dart';
import 'workout_check_in.dart';
import 'workout_pdf.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class WorkoutHomeScreen extends StatefulWidget {
  final bool coach;
  const WorkoutHomeScreen({super.key, this.coach = false});
  @override
  State<WorkoutHomeScreen> createState() => _WorkoutHomeScreenState();
}

class _WorkoutHomeScreenState extends State<WorkoutHomeScreen> {
  List<WorkoutPlan> _plans = [];
  List<Map<String, dynamic>> _clients = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _recent;
  int? _clientID, _activeID;
  Object? _error;
  bool _loading = true;
  int _request = 0;
  int _weekOffset = 0;
  Map<String, dynamic> _preferences = {};
  List<Map<String, dynamic>> _schedule = [];
  bool _offline = false;
  Set<String> _overrides = {};
  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  List<WorkoutDay> _scheduled(DateTime date) {
    final days = [
      for (final p in _plans)
        if (p.status == 'assigned') ...p.days
    ];
    if (_overrides.contains(_dateKey(date))) {
      final ids = _schedule
          .where((r) => '${r['workoutDate']}'.startsWith(_dateKey(date)))
          .map((r) => workoutInt(r['workoutDayID']))
          .toSet();
      return days.where((d) => ids.contains(d.id)).toList();
    }
    return days.where((d) => d.dayOfWeek == date.weekday).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => NotificationService.instance.openPendingWorkoutNotification());
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.coach) {
        final clients =
            workoutRows((await WorkoutService.get('/clients'))['data']);
        if (!mounted || request != _request) return;
        _clients = clients;
        if (!_clients.any((c) => workoutInt(c['id']) == _clientID)) {
          _clientID =
              _clients.isEmpty ? null : workoutInt(_clients.first['id']);
        }
        if (_clientID == null) {
          setState(() {
            _plans = [];
            _stats = {};
          });
          return;
        }
      }
      final results = await Future.wait<dynamic>([
        WorkoutService.plans(clientID: widget.coach ? _clientID : null),
        WorkoutService.get(
            '/stats${widget.coach ? '?clientID=$_clientID' : ''}'),
        if (!widget.coach) WorkoutService.get('/sessions/active'),
        if (!widget.coach) WorkoutService.get('/history?page=1'),
        WorkoutService.get('/preferences'),
        WorkoutService.get(
            '/schedule${widget.coach ? '?clientID=$_clientID' : ''}'),
      ]);
      if (!mounted || request != _request) return;
      setState(() {
        _plans = results[0] as List<WorkoutPlan>;
        _stats = results[1];
        _offline = results.whereType<Map>().any((r) => r['offline'] == true);
        _preferences = results[widget.coach ? 2 : 4];
        WorkoutService.preferences = _preferences;
        final schedule = results[widget.coach ? 3 : 5];
        _schedule = workoutRows(schedule['data']);
        _overrides = (schedule['overrideDates'] as List? ?? [])
            .map((v) => '$v'.substring(0, 10))
            .toSet();
        if (!widget.coach) {
          _activeID = results[2]['session'] == null
              ? null
              : workoutInt(results[2]['session']['id']);
          _recent = workoutRows(results[3]['data']).firstOrNull;
        }
      });
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, WorkoutRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  Future<void> _newRoutine() async {
    try {
      final templates =
          workoutRows((await WorkoutService.get('/templates'))['data']);
      if (!mounted) return;
      final choice = await workoutSheet<Map<String, dynamic>>(
          context: context,
          builder: (context) => SafeArea(
                  child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      children: [
                    const WorkoutLabel('Create routine',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                    ListTile(
                        title: const WorkoutLabel('Blank routine'),
                        leading: const Icon(Icons.add),
                        onTap: () =>
                            Navigator.pop(context, <String, dynamic>{})),
                    ...templates.map((t) => ListTile(
                        title: WorkoutLabel('${t['name']}'),
                        subtitle: WorkoutLabel(
                            '${(t['days'] as List).length} workout days'),
                        onTap: () => Navigator.pop(context, t)))
                  ])));
      if (choice == null || !mounted) return;
      final plan = choice.isEmpty
          ? null
          : WorkoutPlan.fromJson(
              {...choice, 'clientID': _clientID ?? 0, 'status': 'draft'});
      await _open(WorkoutBuilderScreen(
          personal: !widget.coach,
          clientID: widget.coach ? _clientID : null,
          plan: plan,
          duplicate: plan != null));
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _importPlan() async {
    try {
      final files = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['json'], withData: true);
      if (files == null || files.files.single.bytes == null) return;
      final plan = jsonDecode(utf8.decode(files.files.single.bytes!));
      await WorkoutService.post('/plans/import',
          {'plan': plan, if (widget.coach) 'clientID': _clientID});
      if (mounted) await _load();
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _export(WorkoutPlan p) async {
    try {
      final data = await WorkoutService.get('/plans/${p.id}/export');
      data.remove('ok');
      await Clipboard.setData(ClipboardData(
          text: const JsonEncoder.withIndent('  ').convert(data)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: WorkoutLabel(
                'Plan JSON copied. It contains no account details.')));
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _start(WorkoutDay day) async {
    try {
      if (_preferences['bodyweightCheckIn'] == true) {
        await workoutBodyweightCheckIn(context,
            current: workoutNumber(
                workoutRows(_stats['bodyweight']).lastOrNull?['weight']));
        if (!mounted) return;
      }
      final r =
          await WorkoutService.post('/sessions', {'workoutDayID': day.id});
      if (mounted) {
        await _open(ActiveWorkoutScreen(sessionID: workoutInt(r['id'])));
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _archive(WorkoutPlan p) async {
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const WorkoutLabel('Archive plan?'),
                content: const WorkoutLabel(
                    'The plan will leave the client’s assigned plans. Saved workouts remain in history.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const WorkoutLabel(WorkoutText.cancel)),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const WorkoutLabel('Archive'))
                ]));
    if (yes != true) return;
    try {
      await WorkoutService.archive(p.id);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final scheduled = _scheduled(now);
    final upcoming = [
      for (int i = 1; i <= 7; i++) ..._scheduled(now.add(Duration(days: i)))
    ];
    return WorkoutScaffold(
        appBar: AppBar(title: const WorkoutLabel('SIRVYA Workout'), actions: [
          IconButton(
              tooltip: (('Import plan')).workoutTr(context),
              onPressed: widget.coach && _clientID == null ? null : _importPlan,
              icon: const Icon(Icons.file_download_outlined)),
          IconButton(
              tooltip: (('Workout preferences')).workoutTr(context),
              onPressed: () => _open(const WorkoutPreferencesScreen()),
              icon: const Icon(Icons.tune_rounded)),
          IconButton(
              tooltip: (('Refresh')).workoutTr(context),
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded))
        ]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? WorkoutFailure(error: _error!, retry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_offline) const WorkoutOfflineNotice(),
                          if (widget.coach) ...[
                            if (_clients.isEmpty)
                              const Card(
                                  child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: WorkoutLabel(
                                          'Link a client in My Clients to create a workout plan.')))
                            else
                              DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: _clientID,
                                  decoration: InputDecoration(
                                      labelText:
                                          (('Client')).workoutTr(context)),
                                  items: _clients
                                      .map((c) => DropdownMenuItem(
                                          value: workoutInt(c['id']),
                                          child: WorkoutLabel(
                                              '${c['firstName']} ${c['lastName']}')))
                                      .toList(),
                                  onChanged: (id) {
                                    setState(() => _clientID = id);
                                    _load();
                                  }),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                                onPressed:
                                    _clientID == null ? null : _newRoutine,
                                icon: const Icon(Icons.add_rounded),
                                label:
                                    const WorkoutLabel('Create workout plan')),
                          ] else ...[
                            _weekStrip(),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                                onPressed: () => _startSelection(),
                                icon: const Icon(Icons.play_arrow),
                                label: const WorkoutLabel('Start workout')),
                            if (_activeID != null)
                              Card(
                                  child: ListTile(
                                      leading:
                                          const Icon(Icons.play_circle_rounded),
                                      title: const WorkoutLabel(
                                          WorkoutText.resume),
                                      subtitle: const WorkoutLabel(
                                          'Continue from your saved sets'),
                                      onTap: () => _open(ActiveWorkoutScreen(
                                          sessionID: _activeID!)),
                                      trailing: const Icon(
                                          Icons.chevron_right_rounded))),
                            WorkoutLabel('Today’s workout',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            if (scheduled.isEmpty)
                              const Card(
                                  child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: WorkoutLabel(
                                          'No workout scheduled today. You can choose a day from your plan.'))),
                            ...scheduled.map((d) => Card(
                                child: ListTile(
                                    title: WorkoutLabel(d.name),
                                    subtitle: WorkoutLabel(
                                        '${d.exercises.length} exercises'),
                                    trailing:
                                        const Icon(Icons.play_arrow_rounded),
                                    onTap: () => _open(WorkoutDayScreen(
                                        day: d, onStart: () => _start(d)))))),
                            if (upcoming.isNotEmpty)
                              Card(
                                  child: ListTile(
                                      title: const WorkoutLabel(
                                          'Upcoming workout'),
                                      subtitle: WorkoutLabel(
                                          '${upcoming.first.name}${upcoming.first.dayOfWeek == null ? '' : ' · ${WorkoutText.weekdays[upcoming.first.dayOfWeek! - 1]}'}'),
                                      onTap: () => _open(WorkoutDayScreen(
                                          day: upcoming.first,
                                          onStart: () =>
                                              _start(upcoming.first))))),
                          ],
                          const SizedBox(height: 12),
                          if (!widget.coach)
                            OutlinedButton.icon(
                                onPressed: _newRoutine,
                                icon: const Icon(Icons.add_rounded),
                                label: const WorkoutLabel('Create routine')),
                          if (!widget.coach && _recent != null)
                            Card(
                                child: ListTile(
                              leading: const Icon(Icons.history_rounded),
                              title: const WorkoutLabel('Recent workout'),
                              subtitle: WorkoutLabel(
                                  '${_recent!['prescription']['dayName']} · ${workoutDate(_recent!['startedAt'])}'),
                              onTap: () => _open(WorkoutHistoryDetail(
                                  sessionID: workoutInt(_recent!['id']))),
                            )),
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _metric(
                                            '${_stats['workoutCount'] ?? 0}',
                                            'Workouts'),
                                        _metric('${_stats['setCount'] ?? 0}',
                                            'Sets'),
                                        _metric(
                                            '${workoutValue(workoutNumber(_stats['volume']) ?? 0)} kg',
                                            'Volume')
                                      ]))),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            if (!widget.coach)
                              OutlinedButton.icon(
                                  onPressed: () async {
                                    await workoutBodyweightCheckIn(context,
                                        current: workoutNumber(
                                            workoutRows(_stats['bodyweight'])
                                                .lastOrNull?['weight']));
                                    if (mounted) await _load();
                                  },
                                  icon:
                                      const Icon(Icons.monitor_weight_outlined),
                                  label: const WorkoutLabel(
                                      'Body weight check-in')),
                            OutlinedButton.icon(
                                onPressed: () =>
                                    _open(const WorkoutToolsScreen()),
                                icon: const Icon(Icons.calculate_outlined),
                                label: const WorkoutLabel('Training tools')),
                            OutlinedButton.icon(
                                onPressed: () =>
                                    _open(const WorkoutExerciseLibrary()),
                                icon: const Icon(Icons.menu_book_rounded),
                                label: const WorkoutLabel('Exercises')),
                            if (!widget.coach || _clientID != null) ...[
                              OutlinedButton.icon(
                                  onPressed: () => _open(WorkoutHistoryScreen(
                                      clientID:
                                          widget.coach ? _clientID : null)),
                                  icon: const Icon(Icons.history_rounded),
                                  label: const WorkoutLabel('History')),
                              OutlinedButton.icon(
                                  onPressed: () => _open(WorkoutProgressScreen(
                                      clientID:
                                          widget.coach ? _clientID : null)),
                                  icon: const Icon(Icons.insights_rounded),
                                  label:
                                      const WorkoutLabel(WorkoutText.progress))
                            ],
                          ]),
                          const SizedBox(height: 24),
                          WorkoutLabel(
                              widget.coach ? 'Client plans' : 'My plans',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          if (_plans.isEmpty)
                            WorkoutLabel(widget.coach
                                ? 'Create your first plan for this client.'
                                : WorkoutText.noPlans),
                          ..._plans.map((p) => Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                              child: WorkoutLabel(p.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium)),
                                          PopupMenuButton<String>(
                                              tooltip: (('Plan actions'))
                                                  .workoutTr(context),
                                              onSelected: (action) {
                                                if (action == 'edit') {
                                                  _open(WorkoutBuilderScreen(
                                                      clientID: p.clientID,
                                                      plan: p,
                                                      personal: !widget.coach));
                                                }
                                                if (action == 'copy') {
                                                  _open(WorkoutBuilderScreen(
                                                      clientID: p.clientID,
                                                      plan: p,
                                                      personal: !widget.coach,
                                                      duplicate: true));
                                                }
                                                if (action == 'archive') {
                                                  _archive(p);
                                                }
                                                if (action == 'export') {
                                                  _export(p);
                                                }
                                                if (action == 'pdf') {
                                                  printWorkoutPlan(p)
                                                      .catchError((e) {
                                                    if (context.mounted) {
                                                      workoutError(context, e);
                                                    }
                                                  });
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                    if (widget.coach ||
                                                        p.coachID == 0)
                                                      const PopupMenuItem(
                                                          value: 'edit',
                                                          child: WorkoutLabel(
                                                              'Edit plan')),
                                                    const PopupMenuItem(
                                                        value: 'copy',
                                                        child: WorkoutLabel(
                                                            'Duplicate plan')),
                                                    const PopupMenuItem(
                                                        value: 'export',
                                                        child: WorkoutLabel(
                                                            'Export plan')),
                                                    const PopupMenuItem(
                                                        value: 'pdf',
                                                        child: WorkoutLabel(
                                                            'Print / save PDF')),
                                                    if ((widget.coach ||
                                                            p.coachID == 0) &&
                                                        p.status != 'archived')
                                                      const PopupMenuItem(
                                                          value: 'archive',
                                                          child: WorkoutLabel(
                                                              'Archive plan'))
                                                  ])
                                        ]),
                                        if (p.description.isNotEmpty)
                                          WorkoutLabel(p.description),
                                        ...p.days.map((d) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: WorkoutLabel(d.name),
                                            subtitle: WorkoutLabel(
                                                '${d.exercises.length} exercises${d.dayOfWeek == null ? '' : ' · ${WorkoutText.weekdays[d.dayOfWeek! - 1]}'}'),
                                            trailing: const Icon(
                                                Icons.chevron_right_rounded),
                                            onTap: () => _open(WorkoutDayScreen(
                                                day: d,
                                                onStart: widget.coach
                                                    ? null
                                                    : () => _start(d))))),
                                      ])))),
                        ])));
  }

  Widget _metric(String value, String label) => Expanded(
          child: Column(children: [
        WorkoutLabel(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        WorkoutLabel(label)
      ]));
  Widget _weekStrip() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(
            days:
                (now.weekday - workoutInt(_preferences['weekStart'] ?? 1) + 7) %
                    7))
        .add(Duration(days: _weekOffset * 7));
    final frequency = workoutRows(_stats['frequency']);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                IconButton(
                    tooltip: (('Previous week')).workoutTr(context),
                    onPressed: () => setState(() => _weekOffset--),
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                    child: WorkoutLabel(
                        _weekOffset == 0 ? 'This week' : workoutDate(start),
                        textAlign: TextAlign.center)),
                IconButton(
                    tooltip: (('Next week')).workoutTr(context),
                    onPressed: () => setState(() => _weekOffset++),
                    icon: const Icon(Icons.chevron_right))
              ]),
              Row(
                  children: List.generate(7, (i) {
                final d = start.add(Duration(days: i));
                final today = d.year == now.year &&
                    d.month == now.month &&
                    d.day == now.day;
                final trained = frequency.any((f) =>
                    DateTime.tryParse(f['date'])?.day == d.day &&
                    DateTime.tryParse(f['date'])?.month == d.month &&
                    DateTime.tryParse(f['date'])?.year == d.year);
                final planned = _scheduled(d).isNotEmpty;
                return Expanded(
                    child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _chooseDay(d),
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: today ? const Color(0x2242d46b) : null),
                            child: Column(children: [
                              WorkoutLabel(
                                  WorkoutText.weekdays[d.weekday - 1]
                                      .substring(0, 1),
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              WorkoutLabel('${d.day}',
                                  style: TextStyle(
                                      fontWeight: today
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      fontSize: 20)),
                              const SizedBox(height: 8),
                              Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: trained
                                          ? const Color(0xff42d46b)
                                          : planned
                                              ? Colors.orange
                                              : Colors.transparent))
                            ]))));
              }))
            ])));
  }

  Future<void> _startSelection({List<int>? initial, DateTime? date}) async {
    final days = [
      for (final p in _plans)
        if (p.status == 'assigned') ...p.days
    ];
    final chosen = (initial ?? []).toSet();
    final result = await workoutSheet<List<int>>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.8),
                    child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        children: [
                          const WorkoutLabel('Start workout',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w600)),
                          ...days.map((d) => CheckboxListTile(
                              title: WorkoutLabel(d.name),
                              subtitle: WorkoutLabel(
                                  '${d.exercises.length} exercises'),
                              value: chosen.contains(d.id),
                              onChanged: (v) => update(() {
                                    if (v == true) {
                                      chosen.add(d.id);
                                    } else {
                                      chosen.remove(d.id);
                                    }
                                  }))),
                          ElevatedButton(
                              onPressed: chosen.isEmpty
                                  ? null
                                  : () =>
                                      Navigator.pop(context, chosen.toList()),
                              child: const WorkoutLabel(
                                  'Start selected routines')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, <int>[]),
                              child: const WorkoutLabel('Freestyle workout')),
                        ])))));
    if (result == null || !mounted) return;
    try {
      final r = await WorkoutService.post('/sessions', {
        if (result.isEmpty) 'freestyle': true else 'workoutDayIDs': result,
        if (date != null &&
            date.isBefore(DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day)))
          'startedAt':
              date.add(const Duration(hours: 12)).toUtc().toIso8601String()
      });
      if (mounted) {
        await _open(ActiveWorkoutScreen(sessionID: workoutInt(r['id'])));
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _chooseDay(DateTime date) async {
    final days = [
      for (final p in _plans)
        if (p.status == 'assigned') ...p.days
    ];
    final selected = _scheduled(date).map((d) => d.id).toSet();
    final result = await workoutSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.8),
                    child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        children: [
                          WorkoutLabel(workoutDate(date),
                              style: Theme.of(context).textTheme.titleLarge),
                          ...days.map((d) => CheckboxListTile(
                              title: WorkoutLabel(d.name),
                              subtitle: WorkoutLabel(
                                  '${d.exercises.length} exercises'),
                              value: selected.contains(d.id),
                              onChanged: (v) => update(() {
                                    if (v == true) {
                                      selected.add(d.id);
                                    } else {
                                      selected.remove(d.id);
                                    }
                                  }))),
                          if (days.isEmpty)
                            const WorkoutLabel(
                                'Create a routine or ask your coach for a plan.'),
                          ElevatedButton(
                              onPressed: () => Navigator.pop(context, 'save'),
                              child: WorkoutLabel(selected.isEmpty
                                  ? 'Save rest day'
                                  : 'Save schedule')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, 'reset'),
                              child:
                                  const WorkoutLabel('Use routine schedule')),
                          if (selected.isNotEmpty ||
                              date.isBefore(DateTime.now()))
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'start'),
                                child: const WorkoutLabel(
                                    'Start selected routines')),
                        ])))));
    if (result == null || !mounted) return;
    if (result == 'start') {
      await _startSelection(initial: selected.toList(), date: date);
      return;
    }
    try {
      await WorkoutService.put('/schedule', {
        'date': _dateKey(date),
        'dayIDs': selected.toList(),
        'reset': result == 'reset'
      });
      if (mounted) await _load();
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }
}

class WorkoutDayScreen extends StatelessWidget {
  final WorkoutDay day;
  final Future<void> Function()? onStart;
  const WorkoutDayScreen({super.key, required this.day, this.onStart});
  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      appBar: AppBar(title: WorkoutLabel(day.name)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        ...day.exercises.map((e) => Card(
            child: ListTile(
                title: WorkoutLabel(e.exercise.name),
                subtitle: WorkoutLabel(
                    '${e.sets} × ${e.exercise.isTimed ? '${e.durationSeconds ?? 0} sec' : '${e.reps ?? 0} reps'} · ${workoutValue(e.weight)} kg · ${e.restSeconds} sec rest${e.supersetGroup.isEmpty ? '' : '\nSuperset ${e.supersetGroup}'}${e.notes.isEmpty ? '' : '\n${e.notes}'}'),
                onTap: () => Navigator.push(
                    context,
                    WorkoutRoute(
                        builder: (_) =>
                            WorkoutExerciseDetail(exercise: e.exercise)))))),
        if (onStart != null) _StartWorkoutButton(start: onStart!),
      ]));
}

class _StartWorkoutButton extends StatefulWidget {
  final Future<void> Function() start;
  const _StartWorkoutButton({required this.start});
  @override
  State<_StartWorkoutButton> createState() => _StartWorkoutButtonState();
}

class _StartWorkoutButtonState extends State<_StartWorkoutButton> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                await widget.start();
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      icon: const Icon(Icons.play_arrow_rounded),
      label: WorkoutLabel(_busy ? 'Starting…' : WorkoutText.start));
}
