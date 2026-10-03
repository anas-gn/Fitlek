import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'exercise_library.dart';
import 'workout_ui.dart';

// Original vector illustration; no third-party anatomy assets.
class WorkoutMuscleExplorer extends StatefulWidget {
  final bool selecting;
  const WorkoutMuscleExplorer({super.key, this.selecting = false});
  @override
  State<WorkoutMuscleExplorer> createState() => _WorkoutMuscleExplorerState();
}

class _WorkoutMuscleExplorerState extends State<WorkoutMuscleExplorer> {
  List<String>? _groups;
  Object? _error;
  bool _back = false;
  String? _selected;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await WorkoutService.get('/exercises');
      if (mounted) {
        setState(
            () => _groups = List<String>.from(r['filters']['muscleGroup']));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  String _group(String region) {
    const aliases = {
      'chest': ['chest', 'pectorals'],
      'abs': ['abs', 'core'],
      'shoulders': ['shoulders', 'delts'],
      'biceps': ['biceps', 'upper arms'],
      'triceps': ['triceps'],
      'quads': ['quads', 'quadriceps', 'legs'],
      'hamstrings': ['hamstrings'],
      'glutes': ['glutes'],
      'calves': ['calves'],
      'back': ['back', 'lats'],
      'forearms': ['forearms']
    };
    return (aliases[region] ?? [region])
            .where((v) => _groups?.contains(v) == true)
            .firstOrNull ??
        region;
  }

  Future<void> _open(String name) async {
    final picked = await Navigator.push<Exercise>(
        context,
        WorkoutRoute(
            builder: (_) => WorkoutExerciseLibrary(
                selecting: widget.selecting, muscleGroup: name)));
    if (widget.selecting && picked != null && mounted) {
      Navigator.pop(context, picked);
    }
  }

  @override
  Widget build(BuildContext context) => WorkoutScaffold(
      appBar: AppBar(title: const WorkoutLabel('Muscle explorer')),
      body: _error != null
          ? WorkoutFailure(
              error: _error!,
              retry: () {
                setState(() => _error = null);
                _load();
              })
          : _groups == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(20), children: [
                  SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: false, label: WorkoutLabel('Front')),
                        ButtonSegment(value: true, label: WorkoutLabel('Back'))
                      ],
                      selected: {
                        _back
                      },
                      onSelectionChanged: (v) =>
                          setState(() => _back = v.first)),
                  const SizedBox(height: 16),
                  Center(
                      child: SizedBox(
                          width: 280,
                          height: 380,
                          child: GestureDetector(
                              onTapUp: (tap) {
                                final regions = muscleRegions(_back);
                                for (final r in regions.reversed) {
                                  if (r.$2.contains(tap.localPosition)) {
                                    setState(() => _selected = _group(r.$1));
                                    break;
                                  }
                                }
                              },
                              child: CustomPaint(
                                  painter: _BodyPainter(
                                      back: _back,
                                      selected: _selected,
                                      group: _group,
                                      accent:
                                          Theme.of(context).colorScheme.primary,
                                      surface: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest))))),
                  if (_selected != null)
                    ElevatedButton.icon(
                        onPressed: () => _open(_selected!),
                        icon: const Icon(Icons.search),
                        label: WorkoutLabel('Browse ${_selected!} exercises')),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _groups!
                          .map((g) => ActionChip(
                              label: WorkoutLabel(g),
                              onPressed: () => _open(g)))
                          .toList())
                ]));
}

List<(String, Rect)> muscleRegions(bool back) => [
      ('shoulders', const Rect.fromLTWH(68, 70, 35, 36)),
      ('shoulders', const Rect.fromLTWH(177, 70, 35, 36)),
      (back ? 'back' : 'chest', const Rect.fromLTWH(100, 76, 80, 55)),
      (back ? 'back' : 'abs', const Rect.fromLTWH(110, 134, 60, 62)),
      (back ? 'triceps' : 'biceps', const Rect.fromLTWH(64, 110, 31, 52)),
      (back ? 'triceps' : 'biceps', const Rect.fromLTWH(185, 110, 31, 52)),
      ('forearms', const Rect.fromLTWH(51, 167, 28, 65)),
      ('forearms', const Rect.fromLTWH(201, 167, 28, 65)),
      (back ? 'glutes' : 'quads', const Rect.fromLTWH(97, 201, 41, 66)),
      (back ? 'glutes' : 'quads', const Rect.fromLTWH(142, 201, 41, 66)),
      (back ? 'hamstrings' : 'quads', const Rect.fromLTWH(98, 259, 35, 50)),
      (back ? 'hamstrings' : 'quads', const Rect.fromLTWH(147, 259, 35, 50)),
      ('calves', const Rect.fromLTWH(99, 310, 29, 56)),
      ('calves', const Rect.fromLTWH(152, 310, 29, 56))
    ];

class _BodyPainter extends CustomPainter {
  final bool back;
  final String? selected;
  final String Function(String) group;
  final Color accent, surface;
  _BodyPainter(
      {required this.back,
      required this.selected,
      required this.group,
      required this.accent,
      required this.surface});
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = surface;
    canvas.drawOval(const Rect.fromLTWH(119, 8, 42, 50), base);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(130, 52, 20, 24), const Radius.circular(7)),
        base);
    for (final r in muscleRegions(back)) {
      canvas.drawRRect(RRect.fromRectAndRadius(r.$2, const Radius.circular(12)),
          Paint()..color = group(r.$1) == selected ? accent : surface);
    }
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.back != back ||
      old.selected != selected ||
      old.accent != accent ||
      old.surface != surface;
}
