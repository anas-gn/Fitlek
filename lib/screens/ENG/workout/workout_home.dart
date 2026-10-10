import '../../../services/notification_service.dart';
import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import '../../../services/apiService.dart';
import '../../../services/workout_file.dart';
import 'workout_ui.dart';
import 'exercise_library.dart';
import 'active_workout.dart';
import 'workout_progress.dart';
import 'workout_builder.dart';
import 'workout_preferences.dart';
import 'workout_tools.dart';
import 'workout_check_in.dart';
import 'workout_bodyweight.dart';
import 'workout_calendar.dart';
import 'workout_planning.dart';
import 'workout_timer_bar.dart';
import 'workout_pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class WorkoutHomeScreen extends StatefulWidget {
  final bool coach;
  final DateTime Function()? clock;
  const WorkoutHomeScreen({super.key, this.coach = false, this.clock});
  @override
  State<WorkoutHomeScreen> createState() => _WorkoutShellState();
}

class _WorkoutShellState extends State<WorkoutHomeScreen> {
  final _navigator = GlobalKey<NavigatorState>();
  final _overview = GlobalKey<_WorkoutOverviewState>();
  final _timer = WorkoutTimerController();
  int _tab = 0;
  bool _active = false;
  void _select(int index) {
    if (index == 2) {
      _overview.currentState?._startCurrent();
      return;
    }
    if (index == _tab && index > 2) return;
    setState(() => _tab = index);
    if (index < 2) {
      if (_overview.currentState?._activeRouteOpen == true) {
        _navigator.currentState?.push(WorkoutRoute(
            builder: (_) => _WorkoutOverview(
                clock: widget.clock,
                initialSection: index,
                resume: () => _overview.currentState?._startCurrent())));
        return;
      }
      _navigator.currentState?.popUntil((route) => route.isFirst);
      _overview.currentState?._setSection(index);
      _overview.currentState?._load();
    } else {
      _navigator.currentState?.push(WorkoutRoute(
          builder: (_) => index == 3
              ? WorkoutProgressScreen(clock: widget.clock)
              : const WorkoutExerciseLibrary()));
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coach) return _WorkoutOverview(coach: true, clock: widget.clock);
    return WorkoutScope(
        builder: (context) => WorkoutTimerHost(
            timer: _timer,
            child: NavigatorPopHandler(
                onPopWithResult: (_) => _navigator.currentState?.maybePop(),
                child: Scaffold(
                    body: Column(children: [
                      Expanded(
                          child: Navigator(
                              key: _navigator,
                              onGenerateRoute: (_) => WorkoutRoute(
                                  builder: (_) => _WorkoutOverview(
                                      key: _overview,
                                      clock: widget.clock,
                                      exit: Navigator.of(context).canPop()
                                          ? () =>
                                              Navigator.of(context).maybePop()
                                          : null,
                                      onActiveChanged: (active) {
                                        if (mounted && active != _active) {
                                          setState(() => _active = active);
                                        }
                                      })))),
                      ValueListenableBuilder<WorkoutTimerDisplay?>(
                          valueListenable: _timer,
                          builder: (timerContext, timer, child) => timer == null
                              ? const SizedBox.shrink()
                              : WorkoutTimerBar(timer: timer))
                    ]),
                    bottomNavigationBar: SafeArea(
                        top: false,
                        child: Align(
                            heightFactor: 1,
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 560),
                                child: Material(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    child: Row(
                                        children: List.generate(5, (index) {
                                      final labels = [
                                        'Home',
                                        'Plan',
                                        _active ? 'Resume' : 'Start',
                                        'Stats',
                                        'Exercises'
                                      ];
                                      final icons = [
                                        Icons.home_outlined,
                                        Icons.calendar_today_outlined,
                                        _active
                                            ? Icons.play_arrow_rounded
                                            : Icons.fitness_center_rounded,
                                        Icons.bar_chart_rounded,
                                        Icons.format_list_bulleted
                                      ];
                                      return Expanded(
                                          child: InkWell(
                                              key: ValueKey(
                                                  'workout-tab-$index'),
                                              onTap: () => _select(index),
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    index == 2
                                                                        ? 14
                                                                        : 7),
                                                            decoration: index ==
                                                                    2
                                                                ? BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: _active
                                                                        ? Colors
                                                                            .orange
                                                                        : Theme.of(context)
                                                                            .colorScheme
                                                                            .primary)
                                                                : null,
                                                            child: Icon(
                                                                icons[index],
                                                                size: 22,
                                                                color: index ==
                                                                        2
                                                                    ? Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onPrimary
                                                                    : index ==
                                                                            _tab
                                                                        ? Theme.of(context)
                                                                            .colorScheme
                                                                            .primary
                                                                        : Theme.of(context)
                                                                            .colorScheme
                                                                            .onSurfaceVariant)),
                                                        const SizedBox(
                                                            height: 3),
                                                        WorkoutLabel(
                                                            labels[index],
                                                            style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: index == _tab ||
                                                                        index ==
                                                                            2
                                                                    ? FontWeight
                                                                        .w600
                                                                    : FontWeight
                                                                        .w400,
                                                                color: index ==
                                                                            _tab ||
                                                                        index ==
                                                                            2
                                                                    ? Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                    : Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurfaceVariant))
                                                      ]))));
                                    }))))))))));
  }
}

class _WorkoutOverview extends StatefulWidget {
  final bool coach;
  const _WorkoutOverview(
      {super.key,
      this.coach = false,
      this.clock,
      this.exit,
      this.onActiveChanged,
      this.resume,
      this.initialSection = 0});
  final VoidCallback? resume;
  final VoidCallback? exit;
  final DateTime Function()? clock;
  final int initialSection;
  final ValueChanged<bool>? onActiveChanged;
  @override
  State<_WorkoutOverview> createState() => _WorkoutOverviewState();
}

class _WorkoutOverviewState extends State<_WorkoutOverview> {
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  int _section = 0;
  bool _starting = false, _activeRouteOpen = false;
  List<Map<String, dynamic>>? _weekly;
  List<WorkoutPlan> _plans = [];
  List<Map<String, dynamic>> _clients = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _recent;
  String? _activeName;
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
    return _weekly == null
        ? days.where((d) => d.dayOfWeek == date.weekday).toList()
        : days
            .where((d) => _weekly!.any((w) =>
                workoutInt(w['id']) == d.id &&
                workoutInt(w['dayOfWeek']) == date.weekday))
            .toList();
  }

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
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
        _weekly =
            schedule['week'] is List ? workoutRows(schedule['week']) : null;
        _overrides = (schedule['overrideDates'] as List? ?? [])
            .map((v) => '$v'.substring(0, 10))
            .toSet();
        if (!widget.coach) {
          _activeID = results[2]['session'] == null
              ? null
              : workoutInt(results[2]['session']['id']);
          _activeName = results[2]['session']?['prescription']?['dayName'];
          _recent = workoutRows(results[3]['data']).firstOrNull;
        }
      });
      widget.onActiveChanged?.call(_activeID != null);
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _open(Widget page) async {
    final active = page is ActiveWorkoutScreen;
    if (active) _activeRouteOpen = true;
    await Navigator.push(
        context,
        WorkoutRoute(
            builder: (_) => page,
            settings: RouteSettings(name: active ? '/active' : null)));
    if (active) _activeRouteOpen = false;
    if (mounted) await _load();
  }

  Future<void> _newRoutine() async {
    if (!widget.coach) {
      await _open(const WorkoutBuilderScreen(personal: true));
      return;
    }
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

  Future<void> _loadStarter() async {
    try {
      final result = await WorkoutService.post('/program/starter', {});
      if (mounted) {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: WorkoutLabel(
                  '${result['routineCount'] ?? 3} starter routines loaded · Mon / Wed / Fri')));
        }
      }
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
      if (!mounted) return;
      if (!widget.coach &&
          plan is Map &&
          (plan['format'] == 'sirvya-workout-program' ||
              plan['opengym_plan'] == 1)) {
        await _importProgram(Map<String, dynamic>.from(plan));
        return;
      }
      if (!mounted || plan is! Map || plan['days'] is! List) {
        throw const WorkoutApiException('invalid_workout', 400);
      }
      final days = workoutRows(plan['days']);
      final yes = await workoutDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                  title: const WorkoutLabel('Import workout plan?'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WorkoutLabel('${plan['name']}'),
                        const SizedBox(height: 12),
                        WorkoutLabel(
                            '${days.length} routines · ${days.fold<int>(0, (n, d) => n + workoutRows(d['exercises']).length)} exercises'),
                        for (final day in days)
                          WorkoutLabel(
                              '${day['name']} · ${workoutRows(day['exercises']).length} exercises'),
                        const SizedBox(height: 12),
                        const WorkoutLabel(
                            'Adds a new plan as a draft. Your existing routines and weekly schedule remain available.')
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const WorkoutLabel('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const WorkoutLabel('Import'))
                  ]));
      if (yes != true) return;
      await WorkoutService.post('/plans/import',
          {'plan': plan, if (widget.coach) 'clientID': _clientID});
      if (mounted) await _load();
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _importProgram(Map<String, dynamic> program) async {
    final preview = await WorkoutService.post(
        '/program/import-preview', {'program': program});
    if (!mounted) return;
    var replaceWeek = false;
    final yes = await workoutSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (sheetContext, update) => SafeArea(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(sheetContext).height * .8),
                    child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(20),
                        children: [
                          const WorkoutLabel('Import weekly plan',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w600)),
                          WorkoutLabel(
                              '${preview['routineCount']} routines · ${preview['exerciseCount']} exercises · ${preview['scheduledDays']} training days'),
                          const SizedBox(height: 12),
                          for (final day
                              in workoutRows(preview['plan']?['days']))
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: WorkoutLabel('${day['name']}'),
                                subtitle: WorkoutLabel(
                                    '${workoutRows(day['exercises']).length} exercises')),
                          if (workoutInt(preview['dropped']) > 0)
                            WorkoutLabel(
                                '${preview['dropped']} exercises could not be resolved and will be omitted.'),
                          CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const WorkoutLabel(
                                  'Use the shared week schedule'),
                              subtitle: const WorkoutLabel(
                                  'Replaces all seven weekdays. Days left empty in the file become rest days. Your existing routines are kept.'),
                              value: replaceWeek,
                              onChanged: (v) =>
                                  update(() => replaceWeek = v == true)),
                          const WorkoutLabel(
                              'Adds routines with new IDs and reuses matching custom exercises.'),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, true),
                              child: const WorkoutLabel('Import')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, false),
                              child: const WorkoutLabel('Cancel')),
                        ])))));
    if (yes != true) return;
    await WorkoutService.post(
        '/program/import', {'program': program, 'replaceWeek': replaceWeek});
    if (mounted) await _load();
  }

  Future<void> _exportProgram() async {
    try {
      final data = await WorkoutService.get('/program/export?format=opengym');
      data.remove('ok');
      final saved = await saveWorkoutJson('sirvya-weekly-plan.json', data);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: WorkoutLabel('Weekly plan exported')));
      }
    } catch (error) {
      if (mounted) workoutError(context, error);
    }
  }

  Future<void> _export(WorkoutPlan p) async {
    try {
      final data = await WorkoutService.get('/plans/${p.id}/export');
      data.remove('ok');
      final saved = await saveWorkoutJson('sirvya-plan-${p.id}.json', data);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: WorkoutLabel('Workout plan exported')));
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _start(WorkoutDay day) => _begin([day.id]);

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

  void _setSection(int value) => setState(() => _section = value);

  List<WorkoutDay> get _days => [
        for (final p in _plans)
          if (p.status == 'assigned') ...p.days
      ];

  List<WorkoutDay> _baseDays(int weekday) => _days
      .where((d) => _weekly == null
          ? d.dayOfWeek == weekday
          : _weekly!.any((w) =>
              workoutInt(w['id']) == d.id &&
              workoutInt(w['dayOfWeek']) == weekday))
      .toList();

  Future<void> _startCurrent() async {
    if (_activeRouteOpen) {
      Navigator.of(context).popUntil(
          (route) => route.settings.name == '/active' || route.isFirst);
      return;
    }
    if (_activeID != null) {
      if (widget.resume != null) {
        widget.resume!();
        return;
      }
      await _open(
          ActiveWorkoutScreen(sessionID: _activeID!, clock: widget.clock));
      return;
    }
    final today = _scheduled(_now);
    if (today.length == 1) {
      await _start(today.single);
      return;
    }
    await _startChooser();
  }

  Future<void> _startChooser() async {
    final today = _scheduled(_now);
    final chosen = await workoutSheet<WorkoutDay>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .8),
                child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const WorkoutLabel('Start workout',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600)),
                      if (today.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const WorkoutLabel('Today’s workout'),
                        ...today.map((d) => ListTile(
                            title: WorkoutLabel(d.name),
                            subtitle:
                                WorkoutLabel('${d.exercises.length} exercises'),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () => Navigator.pop(context, d)))
                      ],
                      const SizedBox(height: 12),
                      const WorkoutLabel('Other routines'),
                      ..._days.where((d) => !today.contains(d)).map((d) =>
                          ListTile(
                              title: WorkoutLabel(d.name),
                              subtitle: WorkoutLabel(
                                  '${d.exercises.length} exercises'),
                              trailing: const Icon(Icons.play_arrow),
                              onTap: () => Navigator.pop(context, d))),
                      TextButton.icon(
                          onPressed: () => Navigator.pop(context,
                              WorkoutDay(id: -1, name: 'Freestyle workout')),
                          icon: const Icon(Icons.shuffle),
                          label: const WorkoutLabel('Freestyle workout')),
                      if (_days.length > 1)
                        TextButton(
                            onPressed: () => Navigator.pop(context,
                                WorkoutDay(id: -2, name: 'Combined routines')),
                            child: const WorkoutLabel('Combine routines')),
                    ]))));
    if (chosen == null || !mounted) return;
    if (chosen.id == -2) {
      await _startSelection(initial: today.map((d) => d.id).toList());
      return;
    }
    if (chosen.id == -1) {
      await _begin([]);
      return;
    }
    await _start(chosen);
  }

  Future<void> _begin(List<int> ids, {DateTime? date}) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final historical = date != null &&
          date.isBefore(DateTime(_now.year, _now.month, _now.day));
      if (!historical && _preferences['bodyweightCheckIn'] != false) {
        final checkIn = await workoutBodyweightCheckIn(context,
            starting: true,
            readings: workoutWeightReadings(_stats['bodyweight']),
            current: workoutNumber(workoutWeightReadings(_stats['bodyweight'])
                .lastOrNull?['weight']));
        if (!mounted || checkIn == null) return;
      }
      final result = await WorkoutService.post('/sessions', {
        if (ids.isEmpty) 'freestyle': true else 'workoutDayIDs': ids,
        if (historical)
          'startedAt':
              date.add(const Duration(hours: 12)).toUtc().toIso8601String()
      });
      if (mounted) {
        setState(() => _activeID = workoutInt(result['id']));
        widget.onActiveChanged?.call(true);
        await _open(ActiveWorkoutScreen(
            sessionID: workoutInt(result['id']), clock: widget.clock));
      }
    } catch (error) {
      if (mounted) workoutError(context, error);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _assignWeekday(int weekday) async {
    final result = await workoutRoutineChoice(context,
        title: WorkoutText.weekdays[weekday - 1],
        routines: _days,
        selected: _baseDays(weekday).map((day) => day.id));
    if (result == null || !mounted) return;
    try {
      await WorkoutService.put('/week', {
        'weekday': weekday,
        'dayIDs': result.dayIDs,
        'reset': result.action == 'reset'
      });
      if (mounted) await _load();
    } catch (error) {
      if (mounted) workoutError(context, error);
    }
  }

  Future<void> _moveDay(DateTime from) async {
    final to = await showDatePicker(
        context: context,
        initialDate: from.add(const Duration(days: 1)),
        firstDate: _now.subtract(const Duration(days: 365)),
        lastDate: _now.add(const Duration(days: 730)));
    if (to == null || !mounted || _dateKey(to) == _dateKey(from)) return;
    try {
      await WorkoutService.post('/schedule/move',
          {'fromDate': _dateKey(from), 'toDate': _dateKey(to)});
      if (mounted) await _load();
    } catch (error) {
      if (mounted) workoutError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      maxWidth: !widget.coach && _section == 1 ? 1100 : 640,
      appBar: AppBar(
          leading: !widget.coach && _section == 0 && widget.exit != null
              ? IconButton(
                  tooltip: 'Back to SIRVYA'.workoutTr(context),
                  onPressed: widget.exit,
                  icon: const Icon(Icons.chevron_left))
              : null,
          automaticallyImplyLeading: widget.coach,
          titleSpacing: 16,
          toolbarHeight: widget.coach ? 56 : 76,
          titleTextStyle: TextStyle(
              fontFamily: 'SirvyaWorkout',
              fontSize: widget.coach ? 22 : 34,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface),
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            WorkoutLabel(widget.coach
                ? 'Client training'
                : _section == 1
                    ? 'Plan'
                    : 'SIRVYA Workout'),
            if (!widget.coach)
              WorkoutLabel(
                  _section == 1
                      ? 'Your weekly routine'
                      : MaterialLocalizations.of(context).formatFullDate(_now),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w400)),
          ]),
          actions: [
            if (_section == 1 && !widget.coach)
              IconButton(
                  tooltip: 'Export weekly plan'.workoutTr(context),
                  onPressed: _exportProgram,
                  icon: const Icon(Icons.ios_share)),
            if (_section == 1 || widget.coach)
              IconButton(
                  tooltip: 'Import plan'.workoutTr(context),
                  onPressed:
                      widget.coach && _clientID == null ? null : _importPlan,
                  icon: const Icon(Icons.file_download_outlined)),
            IconButton(
                tooltip: 'Workout preferences'.workoutTr(context),
                onPressed: () => _open(const WorkoutPreferencesScreen()),
                icon: const Icon(Icons.tune_rounded))
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? WorkoutFailure(error: _error!, retry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_offline) const WorkoutOfflineNotice(),
                        if (widget.coach)
                          ..._coachBody()
                        else if (_section == 1)
                          WorkoutColumns(
                              first: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _planBody().take(5).toList()),
                              second: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _planBody().skip(5).toList()))
                        else
                          ..._dashboard()
                      ])));

  List<Widget> _dashboard() {
    final now = _now;
    final frequency = workoutRows(_stats['frequency']);
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final trained = frequency.where((f) {
      final date = DateTime.tryParse('${f['date']}');
      return date != null &&
          !date.isBefore(monday) &&
          date.isBefore(monday.add(const Duration(days: 7)));
    }).fold<int>(
        0,
        (n, f) =>
            n +
            workoutInt(f['count'] ?? f['workouts'] ?? f['workoutCount'] ?? 1));
    final planned = List.generate(7, (i) => _baseDays(i + 1))
        .where((d) => d.isNotEmpty)
        .length;
    return [
      _weekStrip(),
      if (_days.isEmpty && _activeID == null)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WorkoutLabel('Build your weekly routine',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const WorkoutLabel(
                          'Choose a starter plan or create your own routine.'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                          onPressed: _loadStarter,
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const WorkoutLabel('Load starter plan (PPL)')),
                      TextButton(
                          onPressed: () => _setSection(1),
                          child: const WorkoutLabel('Build my own plan'))
                    ]))),
      WorkoutBodyweightCard(
          readings: workoutRows(_stats['bodyweight']),
          goal: workoutNumber(
              _stats['bodyweightGoal'] ?? _preferences['bodyweightGoal']),
          reload: _load),
      Card(
          child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined,
                  color: Colors.orange),
              title: WorkoutLabel(
                  '${_stats['currentWeeklyStreak'] ?? 0} week streak',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              subtitle: WorkoutLabel(
                  '$trained${planned == 0 ? '' : ' / $planned'} this week · ${_stats['workoutCount'] ?? 0} workouts total'),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _calendar)),
      if (_recent != null)
        Card(
            child: ListTile(
                leading: const Icon(Icons.history),
                title: const WorkoutLabel('Recent workout'),
                subtitle: WorkoutLabel(
                    '${_recent!['prescription']['dayName']} · ${workoutDate(_recent!['startedAt'])}'),
                onTap: () => _open(WorkoutHistoryDetail(
                    sessionID: workoutInt(_recent!['id']))))),
      TextButton.icon(
          onPressed: () => _open(const WorkoutToolsScreen()),
          icon: const Icon(Icons.calculate_outlined),
          label: const WorkoutLabel('Training tools'))
    ];
  }

  Future<void> _calendar() async {
    final activity = workoutRows(
        _stats['yearActivity'] ?? _stats['activity'] ?? _stats['frequency']);
    final date = await workoutCalendar(context,
        activity: activity,
        initialDate: _now,
        today: _now,
        planned: (date) => _scheduled(date).isNotEmpty,
        overrides: _overrides);
    if (date == null || !mounted) return;
    if (!await workoutOpenRecordedDate(context, date, activity) && mounted) {
      await _chooseDay(date);
    }
    if (mounted) await _load();
  }

  List<Widget> _planBody() => [
        const SizedBox.shrink(),
        const SizedBox(height: 4),
        const WorkoutLabel('Week schedule',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
            child: Column(children: [
          for (var day = 1; day <= 7; day++) ...[
            if (day > 1) const Divider(height: 1, indent: 16),
            ListTile(
                dense: true,
                minTileHeight: 48,
                title: Row(children: [
                  SizedBox(
                      width: 98,
                      child: WorkoutLabel(WorkoutText.weekdays[day - 1],
                          style: const TextStyle(fontSize: 14))),
                  Expanded(
                      child: WorkoutLabel(
                          _baseDays(day).isEmpty
                              ? 'Rest day'
                              : _baseDays(day).map((d) => d.name).join(' + '),
                          style: const TextStyle(fontSize: 14)))
                ]),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _assignWeekday(day))
          ]
        ])),
        Row(children: [
          const Expanded(
              child: WorkoutLabel('Routines',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
          TextButton.icon(
              onPressed: _newRoutine,
              icon: const Icon(Icons.add),
              label: const WorkoutLabel('New'))
        ]),
        if (_plans.isEmpty)
          const WorkoutLabel('Create a routine or choose a starter plan.'),
        if (_plans.isNotEmpty) _routineList()
      ];

  Widget _routineList() => Card(
          child: Column(children: [
        for (final plan in _plans)
          for (final day in plan.days) ...[
            if (day != _plans.first.days.first)
              const Divider(height: 1, indent: 16),
            ListTile(
                leading: Icon(workoutRoutineIcons[day.configuration['icon']] ??
                    Icons.fitness_center),
                title: WorkoutLabel(day.name),
                subtitle: WorkoutLabel(
                    '${day.exercises.length} exercises · ${day.exercises.fold<int>(0, (n, e) => n + e.sets)} sets${plan.coachID == 0 ? '' : ' · Coach plan'}'),
                onTap: () => plan.coachID == 0
                    ? _open(WorkoutBuilderScreen(
                        plan: plan, personal: true, initialDayID: day.id))
                    : _open(WorkoutDayScreen(
                        day: day,
                        onStart: plan.status == 'assigned'
                            ? () => _start(day)
                            : null)),
                trailing: PopupMenuButton<String>(
                    tooltip: 'Routine actions'.workoutTr(context),
                    onSelected: (action) {
                      if (action == 'delete') _deleteRoutine(plan, day);
                      if (action == 'copy') {
                        _open(WorkoutBuilderScreen(
                            plan: plan,
                            personal: true,
                            duplicate: true,
                            initialDayID: day.id));
                      }
                      if (action == 'pdf') printWorkoutPlan(plan);
                      if (action == 'preview') {
                        _open(WorkoutDayScreen(
                            day: day,
                            onStart: plan.status == 'assigned'
                                ? () => _start(day)
                                : null));
                      }
                    },
                    itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'preview',
                              child: WorkoutLabel('Preview routine')),
                          const PopupMenuItem(
                              value: 'copy',
                              child: WorkoutLabel('Duplicate routine')),
                          const PopupMenuItem(
                              value: 'pdf',
                              child: WorkoutLabel('Print / save PDF')),
                          if (plan.coachID == 0)
                            const PopupMenuItem(
                                value: 'delete',
                                child: WorkoutLabel('Delete routine'))
                        ]))
          ]
      ]));

  List<Widget> _coachBody() => [
        if (_clients.isEmpty)
          const WorkoutLabel(
              'Link a client in My Clients to create a workout plan.')
        else
          DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _clientID,
              decoration:
                  InputDecoration(labelText: 'Client'.workoutTr(context)),
              items: _clients
                  .map((c) => DropdownMenuItem(
                      value: workoutInt(c['id']),
                      child:
                          WorkoutLabel('${c['firstName']} ${c['lastName']}')))
                  .toList(),
              onChanged: (id) {
                setState(() => _clientID = id);
                _load();
              }),
        const SizedBox(height: 12),
        ElevatedButton.icon(
            onPressed: _clientID == null ? null : _newRoutine,
            icon: const Icon(Icons.add),
            label: const WorkoutLabel('Create workout plan')),
        if (_clientID != null)
          Wrap(spacing: 8, children: [
            TextButton(
                onPressed: () =>
                    _open(WorkoutProgressScreen(clientID: _clientID)),
                child: const WorkoutLabel('Progress')),
            TextButton(
                onPressed: () =>
                    _open(WorkoutHistoryScreen(clientID: _clientID)),
                child: const WorkoutLabel('History'))
          ]),
        ..._plans.map(_planCard)
      ];

  Widget _planCard(WorkoutPlan plan) => Card(
          child: Column(children: [
        ListTile(
            title: WorkoutLabel(plan.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: plan.description.isEmpty
                ? null
                : WorkoutLabel(plan.description),
            trailing: PopupMenuButton<String>(
                tooltip: 'Plan actions'.workoutTr(context),
                onSelected: (action) {
                  if (action == 'edit' || action == 'copy') {
                    _open(WorkoutBuilderScreen(
                        clientID: plan.clientID,
                        plan: plan,
                        personal: !widget.coach,
                        duplicate: action == 'copy'));
                  }
                  if (action == 'archive') _archive(plan);
                  if (action == 'export') _export(plan);
                  if (action == 'pdf') printWorkoutPlan(plan);
                },
                itemBuilder: (_) => [
                      if ((widget.coach || plan.coachID == 0) &&
                          plan.status != 'archived')
                        const PopupMenuItem(
                            value: 'edit', child: WorkoutLabel('Edit plan')),
                      const PopupMenuItem(
                          value: 'copy', child: WorkoutLabel('Duplicate plan')),
                      const PopupMenuItem(
                          value: 'export', child: WorkoutLabel('Export plan')),
                      const PopupMenuItem(
                          value: 'pdf',
                          child: WorkoutLabel('Print / save PDF')),
                      if ((widget.coach || plan.coachID == 0) &&
                          plan.status != 'archived')
                        const PopupMenuItem(
                            value: 'archive',
                            child: WorkoutLabel('Archive plan'))
                    ])),
        for (final day in plan.days)
          ListTile(
              leading: Icon(workoutRoutineIcons[day.configuration['icon']] ??
                  Icons.fitness_center),
              title: WorkoutLabel(day.name),
              subtitle: WorkoutLabel('${day.exercises.length} exercises'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.coach || plan.coachID == 0)
                  PopupMenuButton<String>(
                      tooltip: 'Routine actions'.workoutTr(context),
                      onSelected: (action) {
                        if (action == 'delete') _deleteRoutine(plan, day);
                        if (action == 'preview') {
                          _open(WorkoutDayScreen(
                              day: day,
                              onStart:
                                  widget.coach ? null : () => _start(day)));
                        }
                      },
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'preview',
                                child: WorkoutLabel('Preview routine')),
                            PopupMenuItem(
                                value: 'delete',
                                child: WorkoutLabel('Delete routine'))
                          ]),
                const Icon(Icons.chevron_right)
              ]),
              onTap: () => !widget.coach && plan.coachID == 0
                  ? _open(WorkoutBuilderScreen(
                      plan: plan, personal: true, initialDayID: day.id))
                  : _open(WorkoutDayScreen(
                      day: day,
                      onStart: widget.coach || plan.status != 'assigned'
                          ? null
                          : () => _start(day))))
      ]));

  Future<void> _deleteRoutine(WorkoutPlan plan, WorkoutDay day) async {
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: WorkoutLabel('Delete ${day.name}?'),
                content: const WorkoutLabel(
                    'Removes this routine from the weekly plan and date overrides. Recorded workouts remain in history.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const WorkoutLabel('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const WorkoutLabel('Delete'))
                ]));
    if (yes != true) return;
    try {
      WorkoutService.checked(await ApiService.delete(
          '/workout/plans/${plan.id}/days/${day.id}?revision=${plan.revision}'));
      if (mounted) await _load();
    } catch (error) {
      if (mounted) workoutError(context, error);
    }
  }

  Widget _weekStrip() {
    final now = _now;
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(
            days:
                (now.weekday - workoutInt(_preferences['weekStart'] ?? 1) + 7) %
                    7))
        .add(Duration(days: _weekOffset * 7));
    final frequency = workoutRows(_stats['frequency']);
    final todayDays = _scheduled(now);
    final changed = _overrides.contains(_dateKey(now));
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                IconButton(
                    tooltip: 'Previous week'.workoutTr(context),
                    onPressed: () => setState(() => _weekOffset--),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                    child: WorkoutLabel(
                        _weekOffset == 0
                            ? 'This week'
                            : '${workoutDate(start)} – ${workoutDate(start.add(const Duration(days: 6)))}',
                        textAlign: TextAlign.center)),
                IconButton(
                    tooltip: 'Next week'.workoutTr(context),
                    onPressed: () => setState(() => _weekOffset++),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right))
              ]),
              Row(
                  children: List.generate(7, (i) {
                final date = start.add(Duration(days: i));
                final key = _dateKey(date);
                final today = key == _dateKey(now);
                final done =
                    frequency.any((f) => '${f['date']}'.startsWith(key));
                final planned = _scheduled(date).isNotEmpty;
                return Expanded(
                    child: InkWell(
                        onTap: () => _chooseDay(date),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.transparent),
                            child: Column(children: [
                              WorkoutLabel(
                                  WorkoutText.weekdays[date.weekday - 1]
                                      .substring(0, 3),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                              const SizedBox(height: 6),
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: AspectRatio(
                                      aspectRatio: 1,
                                      child: DecoratedBox(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: today
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Colors.transparent),
                                          child: Center(
                                              child: WorkoutLabel('${date.day}',
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      height: 1,
                                                      fontWeight: today
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      color: today
                                                          ? Colors.black
                                                          : null)))))),
                              const SizedBox(height: 8),
                              Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: done
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : !planned
                                              ? Colors.transparent
                                              : _overrides.contains(key)
                                                  ? Colors.orange
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: .4)))
                            ]))));
              })),
              const SizedBox(height: 12),
              Ink(
                  decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                      dense: true,
                      minTileHeight: 56,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      leading: Icon(
                          _activeID != null
                              ? Icons.timer_outlined
                              : todayDays.isEmpty
                                  ? Icons.nights_stay_outlined
                                  : Icons.fitness_center,
                          color: _activeID != null
                              ? Colors.orange
                              : Theme.of(context).colorScheme.primary),
                      title: WorkoutLabel('Today',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      subtitle: WorkoutLabel(
                          _activeID != null
                              ? _activeName ?? 'Workout in progress'
                              : todayDays.isEmpty
                                  ? 'Rest day'
                                  : '${todayDays.map((d) => d.name).join(' + ')}${changed ? ' · rescheduled' : ''}',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface)),
                      trailing: _activeID == null && todayDays.isEmpty
                          ? const Icon(Icons.add)
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: WorkoutLabel(
                                      _activeID != null ? 'Resume' : 'Start',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)))),
                      onTap: _starting ? null : () => _activeID != null || todayDays.isNotEmpty ? _startCurrent() : _chooseDay(now)))
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
    await _begin(result, date: date);
  }

  Future<void> _chooseDay(DateTime date) async {
    final selected = _scheduled(date).map((day) => day.id).toList();
    final base = _baseDays(date.weekday);
    final result = await workoutRoutineChoice(context,
        title: workoutDate(date),
        routines: _days,
        selected: selected,
        weeklyContext:
            base.isEmpty ? 'Rest day' : base.map((day) => day.name).join(' + '),
        changed: _overrides.contains(_dateKey(date)),
        allowMove: selected.isNotEmpty,
        allowStart: selected.isNotEmpty || date.isBefore(_now));
    if (result == null || !mounted) return;
    if (result.action == 'move') {
      await _moveDay(date);
      return;
    }
    if (result.action == 'start') {
      await _startSelection(initial: result.dayIDs, date: date);
      return;
    }
    try {
      await WorkoutService.put('/schedule', {
        'date': _dateKey(date),
        'dayIDs': result.dayIDs,
        'reset': result.action == 'reset'
      });
      if (mounted) await _load();
    } catch (error) {
      if (mounted) workoutError(context, error);
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
