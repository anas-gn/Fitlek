import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import '../../../services/apiService.dart';
import 'workout_ui.dart';
import 'workout_progress.dart';
import 'workout_media.dart';
import 'workout_muscles.dart';
import 'workout_builder.dart';
import 'workout_charts.dart';

class WorkoutExerciseLibrary extends StatefulWidget {
  final bool selecting;
  final String? muscleGroup;
  const WorkoutExerciseLibrary(
      {super.key, this.selecting = false, this.muscleGroup});
  @override
  State<WorkoutExerciseLibrary> createState() => _WorkoutExerciseLibraryState();
}

class _WorkoutExerciseLibraryState extends State<WorkoutExerciseLibrary> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Exercise> _exercises = [];
  Map<String, dynamic> _filters = {};
  final Map<String, String?> _selected = {
    'muscleGroup': null,
    'equipment': null,
    'exerciseType': null,
    'secondaryMuscle': null
  };
  Object? _error;
  bool _loading = true, _more = false;
  bool _offline = false;
  int _page = 1, _request = 0;
  bool _favorites = false, _bodyweight = false;
  int _total = 0;
  @override
  void initState() {
    super.initState();
    _selected['muscleGroup'] = widget.muscleGroup;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final request = ++_request;
    final page = more ? _page + 1 : 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profiles =
          WorkoutService.preferences['equipmentProfiles'] as List? ?? [];
      final profile = profiles
          .where((p) =>
              p['name'] == WorkoutService.preferences['activeEquipmentProfile'])
          .firstOrNull;
      final query = {
        'search': _search.text.trim(),
        'page': '$page',
        if (_favorites) 'favorite': 'true',
        if (_bodyweight) 'bodyweight': 'true',
        if (profile != null && (profile['equipment'] as List).isNotEmpty)
          'equipmentList': (profile['equipment'] as List).join(','),
        for (final e in _selected.entries)
          if (e.value != null) e.key: e.value!
      };
      final result = await WorkoutService.get(
          '/exercises?${Uri(queryParameters: query).query}');
      if (!mounted || request != _request) return;
      setState(() {
        final rows =
            workoutRows(result['data']).map(Exercise.fromJson).toList();
        _exercises = more ? [..._exercises, ...rows] : rows;
        _filters = Map<String, dynamic>.from(result['filters']);
        _more = result['hasMore'] == true;
        _page = page;
        _total = workoutInt(result['total']);
        _offline = result['offline'] == true;
      });
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Widget _filter(String key, String label) => SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selected[key],
          decoration: InputDecoration(labelText: ((label)).workoutTr(context)),
          items: [
            const DropdownMenuItem(value: '', child: WorkoutLabel('All')),
            if (_selected[key] != null &&
                !(_filters[key] as List? ?? []).contains(_selected[key]))
              DropdownMenuItem(
                  value: _selected[key], child: WorkoutLabel(_selected[key]!)),
            ...(_filters[key] as List? ?? []).map((v) => DropdownMenuItem(
                value: '$v',
                child: WorkoutLabel('$v', overflow: TextOverflow.ellipsis)))
          ],
          onChanged: (v) {
            setState(() => _selected[key] = v == '' ? null : v);
            _load();
          }));
  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      appBar: AppBar(title: const WorkoutLabel(WorkoutText.library), actions: [
        IconButton(
            tooltip: 'Muscle explorer'.workoutTr(context),
            icon: const Icon(Icons.accessibility_new),
            onPressed: () async {
              final e = await Navigator.push<Exercise>(
                  context,
                  WorkoutRoute(
                      builder: (_) =>
                          WorkoutMuscleExplorer(selecting: widget.selecting)));
              if (widget.selecting && e != null && context.mounted) {
                Navigator.pop(context, e);
              }
            })
      ]),
      body: Column(children: [
        if (_offline) const WorkoutOfflineNotice(),
        Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              TextField(
                  controller: _search,
                  decoration: InputDecoration(
                      labelText: (('Search exercises')).workoutTr(context),
                      prefixIcon: const Icon(Icons.search_rounded)),
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce =
                        Timer(const Duration(milliseconds: 300), () => _load());
                  }),
              const SizedBox(height: 12),
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _filter('muscleGroup', 'Muscle group'),
                    const SizedBox(width: 8),
                    _filter('equipment', 'Equipment'),
                    const SizedBox(width: 8),
                    _filter('exerciseType', 'Type'),
                    const SizedBox(width: 8),
                    _filter('secondaryMuscle', 'Secondary muscle')
                  ])),
              Wrap(spacing: 8, children: [
                FilterChip(
                    label: const WorkoutLabel('Favorites'),
                    selected: _favorites,
                    onSelected: (v) {
                      setState(() => _favorites = v);
                      _load();
                    }),
                FilterChip(
                    label: const WorkoutLabel('Bodyweight'),
                    selected: _bodyweight,
                    onSelected: (v) {
                      setState(() => _bodyweight = v);
                      _load();
                    }),
                ActionChip(
                    label: const WorkoutLabel('Custom exercise'),
                    avatar: const Icon(Icons.add, size: 16),
                    onPressed: _custom)
              ]),
              Align(
                  alignment: Alignment.centerLeft,
                  child: WorkoutLabel('$_total exercises',
                      style: const TextStyle(fontSize: 13)))
            ])),
        Expanded(
            child: _error != null
                ? WorkoutFailure(error: _error!, retry: _load)
                : _loading && _exercises.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _exercises.isEmpty
                        ? const Center(
                            child: WorkoutLabel(
                                'No exercises match these filters.'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: _exercises.length + 1,
                            itemBuilder: (context, i) {
                              if (i == _exercises.length) {
                                return _loading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : _more
                                        ? OutlinedButton(
                                            onPressed: () => _load(more: true),
                                            child:
                                                const WorkoutLabel('Load more'))
                                        : const SizedBox.shrink();
                              }
                              final e = _exercises[i];
                              return Card(
                                  child: ListTile(
                                      leading: const Icon(
                                          Icons.fitness_center_rounded),
                                      title: WorkoutLabel(e.name),
                                      subtitle: WorkoutLabel(
                                          '${e.muscleGroup} · ${e.equipment}'),
                                      onTap: () async {
                                        await Navigator.push(
                                            context,
                                            WorkoutRoute(
                                                builder: (_) =>
                                                    WorkoutExerciseDetail(
                                                        exercise: e)));
                                        if (mounted) await _load();
                                      },
                                      trailing: widget.selecting
                                          ? IconButton(
                                              tooltip: (('Add exercise'))
                                                  .workoutTr(context),
                                              icon:
                                                  const Icon(Icons.add_rounded),
                                              onPressed: () =>
                                                  Navigator.pop(context, e))
                                          : const Icon(
                                              Icons.chevron_right_rounded)));
                            }))
      ]));
  Future<void> _custom() async {
    final result = await workoutSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _CustomExerciseForm());
    if (result == true && mounted) await _load();
  }
}

class WorkoutExerciseDetail extends StatefulWidget {
  final Exercise exercise;
  const WorkoutExerciseDetail({super.key, required this.exercise});
  @override
  State<WorkoutExerciseDetail> createState() => _WorkoutExerciseDetailState();
}

class _WorkoutExerciseDetailState extends State<WorkoutExerciseDetail> {
  Exercise? _exercise;
  Object? _error;
  List<Map<String, dynamic>> _history = [];
  Object? _historyError;
  bool _historyMore = false, _historyLoading = false;
  bool _offline = false;
  int _historyPage = 0, _historyRequest = 0;
  bool _coach = false;
  int? _userID;
  int? _clientID;
  final _personalNotes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result =
          await WorkoutService.get('/exercises/${widget.exercise.id}');
      final e = Exercise.fromJson(result);
      if (mounted) {
        setState(() {
          _exercise = e;
          _offline = result['offline'] == true;
        });
        _personalNotes.text = e.personalNotes;
      }
      try {
        final user = await ApiService.getUserData();
        _userID = user == null ? null : workoutInt(user['id']);
        _coach = await ApiService.getRole() == 'coach';
        if (_coach && _clientID == null) {
          if (mounted) setState(() {});
          return;
        }
        await _loadHistory();
      } catch (e) {
        if (mounted) setState(() => _historyError = e);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadHistory({bool more = false}) async {
    final request = ++_historyRequest;
    final page = more ? _historyPage + 1 : 1;
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final query = {
        'page': '$page',
        if (_clientID != null) 'clientID': '$_clientID'
      };
      final result = await WorkoutService.get(
          '/exercises/${widget.exercise.id}/history?${Uri(queryParameters: query).query}');
      if (!mounted || request != _historyRequest) return;
      setState(() {
        _history = more
            ? [..._history, ...workoutRows(result['data'])]
            : workoutRows(result['data']);
        _historyMore = result['hasMore'] == true;
        _historyPage = page;
        _offline = _offline || result['offline'] == true;
      });
    } catch (e) {
      if (mounted && request == _historyRequest) {
        setState(() => _historyError = e);
      }
    } finally {
      if (mounted && request == _historyRequest) {
        setState(() => _historyLoading = false);
      }
    }
  }

  Future<void> _edit() async {
    final saved = await workoutSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CustomExerciseForm(existing: _exercise));
    if (saved == true && mounted) await _load();
  }

  Future<void> _remove() async {
    final confirmed = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const WorkoutLabel('Remove custom exercise?'),
                content: const WorkoutLabel(
                    'The exercise will be hidden from the library. Existing routines and workout history are kept.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const WorkoutLabel('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const WorkoutLabel('Remove'))
                ]));
    if (confirmed != true) return;
    try {
      WorkoutService.checked(
          await ApiService.delete('/workout/exercises/${widget.exercise.id}'));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _addToRoutine() async {
    try {
      final plans = await WorkoutService.plans();
      final editable = plans
          .where((p) => _coach ? p.coachID == _userID : p.coachID == 0)
          .toList();
      if (!mounted) return;
      final choice = await workoutSheet<(WorkoutPlan?, WorkoutDay?)>(
          context: context,
          builder: (context) => SafeArea(
                  child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      children: [
                    const WorkoutLabel('Add to routine',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                    ListTile(
                        leading: const Icon(Icons.add),
                        title: const WorkoutLabel('Create routine'),
                        onTap: () => Navigator.pop(context, (null, null))),
                    for (final p in editable)
                      for (final d in p.days)
                        ListTile(
                            title: WorkoutLabel(d.name),
                            subtitle: WorkoutLabel(p.name),
                            onTap: () => Navigator.pop(context, (p, d)))
                  ])));
      if (choice == null || !mounted) return;
      int? clientID = choice.$1?.clientID;
      if (_coach && clientID == null) {
        await _selectClient();
        if (!mounted || _clientID == null) return;
        clientID = _clientID;
      }
      await Navigator.push(
          context,
          WorkoutRoute(
              builder: (_) => WorkoutBuilderScreen(
                  personal: !_coach,
                  clientID: clientID,
                  plan: choice.$1,
                  initialExercise: _exercise ?? widget.exercise,
                  initialDayID: choice.$2?.id)));
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Widget _progression(Exercise e) {
    final sessions = <int, double>{};
    final metric = e.isTimed
        ? 'Duration (sec)'
        : e.isBodyweight
            ? 'Repetitions'
            : 'Load (${WorkoutService.unit})';
    for (final row in _history.reversed) {
      if ((row['details'] as Map?)?['phase'] == 'warmup') continue;
      final value = e.isTimed
          ? workoutNumber(row['durationSeconds'])
          : e.isBodyweight
              ? workoutNumber(row['reps'])
              : WorkoutService.displayWeight(workoutNumber(row['weight']) ?? 0);
      final id = workoutInt(row['workoutSessionID']);
      if (value != null && value > (sessions[id] ?? -1)) sessions[id] = value;
    }
    if (sessions.isEmpty) return const SizedBox.shrink();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const WorkoutLabel('Progression',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              WorkoutLabel(metric),
              WorkoutLineChart(values: sessions.values.toList(), label: metric),
              WorkoutLabel(
                  '${workoutDate(_history.last['startedAt'])} – ${workoutDate(_history.first['startedAt'])}',
                  style: const TextStyle(fontSize: 12))
            ])));
  }

  @override
  void dispose() {
    _personalNotes.dispose();
    super.dispose();
  }

  Future<void> _selectClient() async {
    try {
      final rows = workoutRows((await WorkoutService.get('/clients'))['data']);
      if (!mounted) return;
      final id = await workoutSheet<int>(
          context: context,
          builder: (context) => SafeArea(
                  child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      children: [
                    const WorkoutLabel('Select client'),
                    ...rows.map((c) => ListTile(
                        title:
                            WorkoutLabel('${c['firstName']} ${c['lastName']}'),
                        onTap: () =>
                            Navigator.pop(context, workoutInt(c['id']))))
                  ])));
      if (id != null && mounted) {
        setState(() => _clientID = id);
        await _load();
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _preference({bool? favorite}) async {
    try {
      await WorkoutService.put('/exercises/${widget.exercise.id}/preferences', {
        'favorite': favorite ?? _exercise?.favorite ?? false,
        'notes': _personalNotes.text
      });
      await _load();
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  Future<void> _video(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !['http', 'https'].contains(uri.scheme)) return;
    try {
      if (!await launchUrl(uri)) {
        throw const WorkoutApiException('workout_error', 0);
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _exercise ?? widget.exercise;
    return WorkoutScaffold(
        appBar: AppBar(title: WorkoutLabel(e.name), actions: [
          if (e.ownerID != null && e.ownerID == _userID)
            PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? _edit() : _remove(),
                itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'edit', child: WorkoutLabel('Edit exercise')),
                      PopupMenuItem(
                          value: 'remove',
                          child: WorkoutLabel('Remove exercise'))
                    ]),
          IconButton(
              tooltip: (('Favorite exercise')).workoutTr(context),
              onPressed: _exercise == null
                  ? null
                  : () => _preference(favorite: !e.favorite),
              icon: Icon(
                  e.favorite ? Icons.star_rounded : Icons.star_border_rounded))
        ]),
        body: _error != null
            ? WorkoutFailure(error: _error!, retry: _load)
            : _exercise == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(padding: const EdgeInsets.all(20), children: [
                    if (_offline) const WorkoutOfflineNotice(),
                    if (e.imageUrl != null)
                      ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(e.imageUrl!,
                              height: 220,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 100,
                                  child: Center(
                                      child: Icon(Icons.fitness_center_rounded,
                                          size: 48))))),
                    Wrap(spacing: 8, children: [
                      Chip(label: WorkoutLabel(e.muscleGroup)),
                      Chip(label: WorkoutLabel(e.equipment)),
                      Chip(
                          label: WorkoutLabel(e.isTimed
                              ? 'Timed exercise'
                              : e.isBodyweight
                                  ? 'Bodyweight'
                                  : 'Repetitions'))
                    ]),
                    if (e.secondaryMuscles.isNotEmpty)
                      WorkoutLabel(
                          'Secondary muscles: ${e.secondaryMuscles.join(', ')}'),
                    if (e.description != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: WorkoutLabel(e.description!)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                        onPressed: _addToRoutine,
                        icon: const Icon(Icons.add),
                        label: const WorkoutLabel('Add to routine')),
                    const SizedBox(height: 16),
                    WorkoutLabel('Instructions',
                        style: Theme.of(context).textTheme.titleLarge),
                    WorkoutMediaPanel(exerciseID: e.id),
                    ...e.instructions.asMap().entries.map((step) => Card(
                        child: ListTile(
                            leading: CircleAvatar(
                                child: WorkoutLabel('${step.key + 1}')),
                            title: WorkoutLabel(step.value)))),
                    if (e.videoUrl != null)
                      OutlinedButton.icon(
                          onPressed: () => _video(e.videoUrl!),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const WorkoutLabel('Watch demonstration')),
                    const SizedBox(height: 16),
                    TextField(
                        controller: _personalNotes,
                        maxLength: 2000,
                        maxLines: 2,
                        decoration: InputDecoration(
                            labelText: (('Personal exercise notes'))
                                .workoutTr(context),
                            hintText: (('Seat setting, technique cues…'))
                                .workoutTr(context))),
                    TextButton(
                        onPressed: () => _preference(),
                        child: const WorkoutLabel('Save note')),
                    const SizedBox(height: 16),
                    WorkoutLabel('Exercise history',
                        style: Theme.of(context).textTheme.titleLarge),
                    if (_coach)
                      TextButton(
                          onPressed: _selectClient,
                          child: const WorkoutLabel('Select client')),
                    if (_history.isNotEmpty) _progression(e),
                    if (_historyError != null)
                      WorkoutFailure(
                          error: _historyError!,
                          retry: () => _loadHistory(more: _historyPage > 0)),
                    if (_history.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: WorkoutLabel(
                              'No completed sets for this exercise yet.')),
                    ..._history.map((s) => Card(
                        child: ListTile(
                            title: WorkoutLabel(workoutDate(s['startedAt'])),
                            subtitle: WorkoutLabel(e.isTimed
                                ? '${s['durationSeconds']} sec'
                                : '${workoutValue(WorkoutService.displayWeight(workoutNumber(s['weight']) ?? 0))} ${WorkoutService.unit} × ${s['reps']}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                                context,
                                WorkoutRoute(
                                    builder: (_) => WorkoutHistoryDetail(
                                        sessionID: workoutInt(
                                            s['workoutSessionID']))))))),
                    if (_historyLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_historyMore)
                      OutlinedButton(
                          onPressed: () => _loadHistory(more: true),
                          child: const WorkoutLabel('Load more')),
                  ]));
  }
}

class _CustomExerciseForm extends StatefulWidget {
  final Exercise? existing;
  const _CustomExerciseForm({this.existing});
  @override
  State<_CustomExerciseForm> createState() => _CustomExerciseFormState();
}

class _CustomExerciseFormState extends State<_CustomExerciseForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _muscle = TextEditingController(),
      _equipment = TextEditingController(),
      _description = TextEditingController(),
      _secondary = TextEditingController(),
      _instructions = TextEditingController();
  String _type = 'reps';
  bool _bodyweight = false, _saving = false;
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name.text = e?.name ?? '';
    _muscle.text = e?.muscleGroup ?? '';
    _equipment.text = e?.equipment ?? '';
    _description.text = e?.description ?? '';
    _secondary.text = e?.secondaryMuscles.join(', ') ?? '';
    _instructions.text = e?.instructions.join('\n') ?? '';
    _type = e?.type ?? 'reps';
    _bodyweight = e?.isBodyweight ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _muscle,
      _equipment,
      _instructions,
      _description,
      _secondary
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(TextEditingController c, String label,
          {bool required = true, int maxLength = 160}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              controller: c,
              maxLength: maxLength,
              decoration:
                  InputDecoration(labelText: ((label)).workoutTr(context)),
              validator: (v) => required && (v ?? '').trim().isEmpty
                  ? 'Enter $label'.workoutTr(context)
                  : null));
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'name': _name.text,
        'muscleGroup': _muscle.text,
        'equipment': _equipment.text,
        'exerciseType': _type,
        'isBodyweight': _bodyweight,
        'description': _description.text,
        'secondaryMuscles': _secondary.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'instructions': _instructions.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList()
      };
      if (widget.existing == null) {
        await WorkoutService.post('/exercises', body);
      } else {
        await WorkoutService.put('/exercises/${widget.existing!.id}', body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SafeArea(
          child: SingleChildScrollView(
              child: Form(
                  key: _form,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    WorkoutLabel(
                        widget.existing == null
                            ? 'Custom exercise'
                            : 'Edit exercise',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _field(_name, 'Exercise name'),
                    _field(_muscle, 'Muscle group', maxLength: 80),
                    _field(_equipment, 'Equipment',
                        required: false, maxLength: 80),
                    _field(_description, 'Description',
                        required: false, maxLength: 5000),
                    _field(_secondary, 'Secondary muscles (comma separated)',
                        required: false, maxLength: 1600),
                    DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: InputDecoration(
                            labelText: (('Type')).workoutTr(context)),
                        items: const [
                          DropdownMenuItem(
                              value: 'reps',
                              child: WorkoutLabel('Repetitions')),
                          DropdownMenuItem(
                              value: 'timed',
                              child: WorkoutLabel('Timed exercise')),
                          DropdownMenuItem(
                              value: 'cardio', child: WorkoutLabel('Cardio'))
                        ],
                        onChanged: (v) => setState(() => _type = v!)),
                    SwitchListTile(
                        title: const WorkoutLabel('Bodyweight'),
                        value: _bodyweight,
                        onChanged: (v) => setState(() => _bodyweight = v)),
                    TextFormField(
                        controller: _instructions,
                        maxLines: 4,
                        decoration: InputDecoration(
                            labelText: (('Instructions — one step per line'))
                                .workoutTr(context))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child:
                            WorkoutLabel(_saving ? 'Saving…' : 'Save exercise'))
                  ])))));
}
