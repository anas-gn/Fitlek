import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  final int? routineID;
  const ExerciseLibraryScreen({super.key, this.routineID});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  List<dynamic> _exercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final query = _search.text.trim();
    final result = await ApiService.get('/premium/workouts/exercises${query.isEmpty ? '' : '?search=${Uri.encodeQueryComponent(query)}'}');
    if (!mounted) return;
    setState(() {
      _exercises = result['ok'] == true && result['data'] is List ? result['data'] as List : [];
      _loading = false;
    });
  }

  Future<void> _add(dynamic exercise) async {
    if (widget.routineID == null) return;
    final result = await ApiService.post(
      '/premium/workouts/routines/${widget.routineID}/exercises',
      {'exerciseID': exercise['id'], 'targetSets': 3, 'targetReps': exercise['exerciseType'] == 'reps' ? 10 : null},
    );
    if (!mounted) return;
    if (result['ok'] == true) {
      ApiService.showSuccess(context, 'Exercise added to routine.');
    } else {
      ApiService.showError(context, result['message']?.toString() ?? 'Unable to add exercise.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search exercises',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.arrow_forward_rounded)),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                    ? const Center(child: Text('No exercises found.'))
                    : ListView.builder(
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.fitness_center_rounded)),
                            title: Text(exercise['name']?.toString() ?? 'Exercise'),
                            subtitle: Text('${exercise['muscleGroup'] ?? 'General'} • ${exercise['equipment'] ?? 'Bodyweight'}'),
                            trailing: widget.routineID == null ? null : IconButton(
                              onPressed: () => _add(exercise),
                              icon: const Icon(Icons.add_circle_outline_rounded),
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
