import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'exercise_library_screen.dart';
import 'guided_workout_screen.dart';
import 'premium_progress_screen.dart';

class PremiumHomeScreen extends StatefulWidget {
  final int clientID;

  const PremiumHomeScreen({super.key, required this.clientID});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen> {
  bool _loading = true;
  List<dynamic> _routines = [];
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      ApiService.get('/premium/workouts/routines'),
      ApiService.get('/premium/workouts/history'),
    ]);
    if (!mounted) return;
    setState(() {
      _routines = results[0]['ok'] == true && results[0]['data'] is List
          ? results[0]['data'] as List
          : [];
      _history = results[1]['ok'] == true && results[1]['data'] is List
          ? results[1]['data'] as List
          : [];
      _loading = false;
    });
  }

  Future<void> _createRoutine() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New routine'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Routine name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final result = await ApiService.post('/premium/workouts/routines', {'name': name});
    if (!mounted) return;
    if (result['ok'] != true) {
      ApiService.showError(context, result['message']?.toString() ?? 'Unable to create routine.');
      return;
    }
    await _loadData();
  }

  Future<void> _startRoutine(dynamic routine) async {
    final routineID = int.tryParse('${routine['id']}');
    if (routineID == null) return;
    final result = await ApiService.post('/premium/workouts/sessions', {'routineID': routineID});
    if (!mounted) return;
    if (result['ok'] != true) {
      ApiService.showError(context, result['message']?.toString() ?? 'Unable to start workout.');
      return;
    }
    final sessionID = int.tryParse('${result['id']}');
    if (sessionID == null) return;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => GuidedWorkoutScreen(sessionID: sessionID, routineID: routineID),
    ));
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sirvya Premium'),
        actions: [IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your training space',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Your Premium access is active. Build a routine and start tracking your training.'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _createRoutine,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create routine'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Browse exercise library'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumProgressScreen())),
            icon: const Icon(Icons.insights_rounded),
            label: const Text('View progress'),
          ),
          const SizedBox(height: 24),
          Text('Your routines', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_routines.isEmpty)
            const Text('No routines yet. Create your first plan above.')
          else
            ..._routines.map((routine) => _FeatureCard(
                  icon: Icons.fitness_center_rounded,
                  title: routine['name']?.toString() ?? 'Routine',
                  subtitle: '${routine['exerciseCount'] ?? 0} exercises',
                  onTap: () => _startRoutine(routine),
                  trailing: IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ExerciseLibraryScreen(routineID: int.tryParse('${routine['id']}')),
                    )),
                    icon: const Icon(Icons.add_rounded),
                  ),
                )),
          const SizedBox(height: 24),
          Text('Recent workouts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (!_loading && _history.isEmpty)
            const Text('Completed workouts will appear here.')
          else
            ..._history.take(5).map((session) => _FeatureCard(
                  icon: Icons.history_rounded,
                  title: session['routineName']?.toString() ?? 'Workout',
                  subtitle: '${session['setCount'] ?? 0} sets • ${session['status'] ?? ''}',
                )),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _FeatureCard({required this.icon, required this.title, required this.subtitle, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
