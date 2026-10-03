import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class GuidedWorkoutScreen extends StatefulWidget {
  final int sessionID;
  final int routineID;

  const GuidedWorkoutScreen({
    super.key,
    required this.sessionID,
    required this.routineID,
  });

  @override
  State<GuidedWorkoutScreen> createState() => _GuidedWorkoutScreenState();
}

class _GuidedWorkoutScreenState extends State<GuidedWorkoutScreen> {
  bool _loading = true;
  bool _finishing = false;
  String _routineName = 'Workout';
  List<dynamic> _exercises = [];
  final Map<int, List<_SetDraft>> _drafts = {};
  Timer? _restTimer;
  int _restSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final drafts in _drafts.values) {
      for (final draft in drafts) {
        draft.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadRoutine() async {
    final result = await ApiService.get('/premium/workouts/routines/${widget.routineID}');
    if (!mounted) return;
    if (result['ok'] != true || result['routine'] is! Map) {
      ApiService.showError(context, result['message']?.toString() ?? 'Unable to load routine.');
      Navigator.pop(context);
      return;
    }
    final exercises = result['exercises'] is List ? result['exercises'] as List : <dynamic>[];
    setState(() {
      _routineName = result['routine']['name']?.toString() ?? 'Workout';
      _exercises = exercises;
      for (final exercise in exercises) {
        final id = int.tryParse('${exercise['exerciseID']}');
        if (id != null) {
          final count = int.tryParse('${exercise['targetSets']}') ?? 3;
          _drafts[id] = List.generate(count, (_) => _SetDraft());
        }
      }
      _loading = false;
    });
  }

  Future<bool> _saveSet(int exerciseID, int setNumber, _SetDraft draft) async {
    final result = await ApiService.post(
      '/premium/workouts/sessions/${widget.sessionID}/sets',
      {
        'exerciseID': exerciseID,
        'setNumber': setNumber,
        'weight': double.tryParse(draft.weight.text),
        'reps': int.tryParse(draft.reps.text),
        'durationSeconds': int.tryParse(draft.duration.text),
      },
    );
    if (!mounted) return false;
    if (result['ok'] != true) {
      ApiService.showError(context, result['message']?.toString() ?? 'Unable to save set.');
      return false;
    }
    _startRestTimer(90);
    return true;
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() => _restSeconds = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restSeconds <= 1) {
        timer.cancel();
        setState(() => _restSeconds = 0);
      } else {
        setState(() => _restSeconds--);
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    for (final entry in _drafts.entries) {
      for (var index = 0; index < entry.value.length; index++) {
        final draft = entry.value[index];
        if (draft.hasValue && !await _saveSet(entry.key, index + 1, draft)) {
          if (mounted) setState(() => _finishing = false);
          return;
        }
      }
    }
    final result = await ApiService.post('/premium/workouts/sessions/${widget.sessionID}/finish', {});
    if (!mounted) return;
    setState(() => _finishing = false);
    if (result['ok'] != true) {
      ApiService.showError(context, result['message']?.toString() ?? 'Unable to finish workout.');
      return;
    }
    ApiService.showSuccess(context, 'Workout completed.');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_routineName),
        actions: [
          TextButton(
            onPressed: _loading || _finishing ? null : _finish,
            child: _finishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Finish'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? const Center(child: Text('This routine has no exercises yet.'))
              : Column(
                  children: [
                    if (_restSeconds > 0)
                      MaterialBanner(
                        content: Text('Rest timer: ${_restSeconds ~/ 60}:${(_restSeconds % 60).toString().padLeft(2, '0')}'),
                        leading: const Icon(Icons.timer_outlined),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _restTimer?.cancel();
                              setState(() => _restSeconds = 0);
                            },
                            child: const Text('Skip'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    final id = int.parse('${exercise['exerciseID']}');
                    final drafts = _drafts[id] ?? <_SetDraft>[];
                    final timed = exercise['exerciseType'] == 'timed';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${index + 1}. ${exercise['exerciseName'] ?? 'Exercise'}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(timed ? 'Target: ${exercise['targetDurationSeconds'] ?? 30}s' : 'Target: ${exercise['targetSets'] ?? 3} × ${exercise['targetReps'] ?? 10}'),
                            const SizedBox(height: 12),
                            ...drafts.asMap().entries.map((entry) => _SetRow(
                              number: entry.key + 1,
                              draft: entry.value,
                              timed: timed,
                              onSave: () => _saveSet(id, entry.key + 1, entry.value),
                            )),
                          ],
                        ),
                      ),
                    );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SetDraft {
  final weight = TextEditingController();
  final reps = TextEditingController();
  final duration = TextEditingController();

  bool get hasValue => weight.text.isNotEmpty || reps.text.isNotEmpty || duration.text.isNotEmpty;

  void dispose() {
    weight.dispose();
    reps.dispose();
    duration.dispose();
  }
}

class _SetRow extends StatelessWidget {
  final int number;
  final _SetDraft draft;
  final bool timed;
  final Future<bool> Function() onSave;

  const _SetRow({required this.number, required this.draft, required this.timed, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('$number', style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: TextField(controller: draft.weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'kg', isDense: true))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: timed ? draft.duration : draft.reps, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: timed ? 'seconds' : 'reps', isDense: true))),
          IconButton(onPressed: () async { await onSave(); }, icon: const Icon(Icons.check_circle_outline_rounded)),
        ],
      ),
    );
  }
}
