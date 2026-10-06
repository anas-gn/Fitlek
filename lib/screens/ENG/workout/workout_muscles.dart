import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'exercise_library.dart';
import 'workout_ui.dart';
import 'workout_anatomy.dart';

const workoutMuscleNames = [
  'traps',
  'shoulders',
  'chest',
  'upper back',
  'serratus',
  'biceps',
  'triceps',
  'forearms',
  'abs',
  'obliques',
  'lower back',
  'glutes',
  'quads',
  'hamstrings',
  'adductors',
  'hip flexors',
  'calves',
  'shins'
];
const _muscleAliases = {
  'trapezius': 'traps',
  'levator scapulae': 'traps',
  'deltoids': 'shoulders',
  'delts': 'shoulders',
  'rear deltoids': 'shoulders',
  'rotator cuff': 'shoulders',
  'pectorals': 'chest',
  'upper chest': 'chest',
  'back': 'upper back',
  'lats': 'upper back',
  'rhomboids': 'upper back',
  'latissimus dorsi': 'upper back',
  'serratus anterior': 'serratus',
  'brachialis': 'biceps',
  'forearm': 'forearms',
  'wrists': 'forearms',
  'wrist flexors': 'forearms',
  'wrist extensors': 'forearms',
  'grip muscles': 'forearms',
  'core': 'abs',
  'abdominals': 'abs',
  'lower abs': 'abs',
  'spine': 'lower back',
  'gluteal': 'glutes',
  'abductors': 'glutes',
  'quadriceps': 'quads',
  'legs': 'quads',
  'hamstring': 'hamstrings',
  'groin': 'adductors',
  'inner thighs': 'adductors',
  'soleus': 'calves',
  'tibialis': 'shins'
};
const _bodyPartMuscles = <String, Map<String, double>>{
  'chest': {'chest': 1},
  'back': {'upper back': .75, 'lower back': .25},
  'shoulders': {'shoulders': 1},
  'upper arms': {'biceps': .5, 'triceps': .5},
  'lower arms': {'forearms': 1},
  'waist': {'abs': .7, 'obliques': .3},
  'upper legs': {'quads': .4, 'hamstrings': .35, 'glutes': .25},
  'lower legs': {'calves': .8, 'shins': .2},
  'neck': {'traps': 1},
};
Map<String, double> workoutMuscleWeights(Exercise exercise) {
  final weights = <String, double>{};
  void add(String raw, double value) {
    final name = raw.trim().toLowerCase(),
        muscle = _muscleAliases[name] ?? name;
    if (workoutMuscleNames.contains(muscle) && value > (weights[muscle] ?? 0)) {
      weights[muscle] = value;
    }
  }

  if (exercise.externalSource != 'sirvya-custom') {
    add(exercise.muscleGroup, 1);
  }
  for (final muscle in exercise.secondaryMuscles) {
    add(muscle, .4);
  }
  if (weights.isEmpty) {
    weights.addAll(_bodyPartMuscles[exercise.bodyPart.isEmpty
            ? exercise.muscleGroup
            : exercise.bodyPart] ??
        {});
  }
  return weights;
}

Map<String, double> workoutMuscleCoverage(List<WorkoutExercise> exercises,
    {List<WorkoutSet>? performed}) {
  final totals = <String, double>{};
  for (final exercise in exercises) {
    final count = performed == null
        ? exercise.sets
        : performed
            .where((s) => s.workoutExerciseID == exercise.id && !s.isWarmup)
            .length;
    for (final weight in workoutMuscleWeights(exercise.exercise).entries) {
      totals[weight.key] = (totals[weight.key] ?? 0) + count * weight.value;
    }
  }
  return totals;
}

class WorkoutMuscleCoverage extends StatefulWidget {
  final Map<String, double> load;
  final bool showList;
  final bool showLegend;
  const WorkoutMuscleCoverage(
      {super.key,
      required this.load,
      this.showList = true,
      this.showLegend = true});
  @override
  State<WorkoutMuscleCoverage> createState() => _WorkoutMuscleCoverageState();
}

class _WorkoutMuscleCoverageState extends State<WorkoutMuscleCoverage> {
  String? _selected;
  @override
  Widget build(BuildContext context) {
    final regions = <String, double>{};
    for (final entry in widget.load.entries) {
      final key = _muscleAliases[entry.key] ?? entry.key;
      regions[key] = (regions[key] ?? 0) + entry.value;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.showList) ...[
        const SizedBox(height: 16),
        const WorkoutLabel('Muscle coverage',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const WorkoutLabel('Effective sets · primary 1, secondary 0.4'),
      ],
      LayoutBuilder(
          builder: (context, bounds) => SizedBox(
              height: math.min(340, (bounds.maxWidth - 6) / 2 * 380 / 216),
              child: Row(children: [
                for (final back in [false, true])
                  Expanded(
                      child: Column(children: [
                    Expanded(
                        child: FittedBox(
                            child: SizedBox(
                                width: 216,
                                height: 380,
                                child: WorkoutAnatomyView(
                                    back: back,
                                    body: WorkoutService
                                                .preferences['bodyFigure'] ==
                                            'female'
                                        ? 'female'
                                        : 'male',
                                    selected: _selected,
                                    load: regions,
                                    onMuscle: (muscle) => setState(() =>
                                        _selected = _selected == muscle
                                            ? null
                                            : muscle))))),
                  ])),
              ]))),
      if (widget.showLegend)
        Align(
            alignment: Alignment.centerRight,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              WorkoutLabel('Less',
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 5),
              for (final level in [0.0, .32, .56, .78, 1.0])
                Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Color.lerp(
                            Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .11),
                            Theme.of(context).colorScheme.primary,
                            level))),
              WorkoutLabel('More',
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
      if (_selected != null)
        ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: WorkoutLabel(_selected!),
            trailing: WorkoutLabel((regions[_selected] ?? 0) == 0
                ? 'Not trained'
                : '${workoutValue(regions[_selected])} sets'),
            onTap: () => setState(() => _selected = null)),
      if (widget.showList)
        Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.load.entries
                .map((e) => ActionChip(
                    label: WorkoutLabel('${e.key}: ${workoutValue(e.value)}'),
                    onPressed: () => setState(
                        () => _selected = _muscleAliases[e.key] ?? e.key)))
                .toList()),
    ]);
  }
}

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
      'upper back': ['upper back', 'back', 'lats'],
      'lower back': ['spine', 'lower back', 'back'],
      'traps': ['traps', 'back'],
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
                                final regions = _muscleShapes(_back);
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

// Independently drawn native contours. Painting and hit testing share the same
// paths so selecting a muscle follows its visible shape, including both sides.
Path _contour(List<(double, double)> vertices, {bool mirror = false}) {
  final points =
      vertices.map((p) => Offset(mirror ? 280 - p.$1 : p.$1, p.$2)).toList();
  final start = (points.last + points.first) / 2;
  final path = Path()..moveTo(start.dx, start.dy);
  for (var i = 0; i < points.length; i++) {
    final end = (points[i] + points[(i + 1) % points.length]) / 2;
    path.quadraticBezierTo(points[i].dx, points[i].dy, end.dx, end.dy);
  }
  return path..close();
}

List<(String, Path)> _drawMuscles(bool back) {
  final shapes = <(String, Path)>[];
  void pair(String name, List<(double, double)> points) {
    shapes.add((name, _contour(points)));
    shapes.add((name, _contour(points, mirror: true)));
  }

  pair(
      'traps',
      back
          ? [(137, 57), (124, 65), (104, 74), (126, 91), (137, 117)]
          : [(129, 62), (111, 71), (110, 76), (132, 75)]);
  pair('shoulders',
      [(103, 73), (84, 74), (73, 89), (74, 108), (87, 104), (101, 89)]);
  if (back) {
    pair('upper back',
        [(135, 93), (109, 81), (99, 110), (109, 138), (127, 154), (135, 124)]);
    pair('lower back', [(137, 127), (123, 153), (118, 186), (135, 203)]);
    pair('glutes', [
      (136, 202),
      (115, 196),
      (103, 211),
      (104, 237),
      (124, 245),
      (137, 232)
    ]);
    pair('hamstrings', [
      (109, 245),
      (130, 247),
      (130, 270),
      (123, 299),
      (104, 297),
      (101, 273)
    ]);
    pair('calves', [
      (108, 307),
      (123, 305),
      (129, 327),
      (119, 351),
      (107, 345),
      (102, 326)
    ]);
  } else {
    pair('chest',
        [(137, 83), (116, 79), (103, 89), (103, 116), (123, 125), (137, 114)]);
    pair('serratus', [(101, 122), (113, 127), (112, 153), (101, 146)]);
    pair('obliques', [
      (102, 150),
      (113, 153),
      (116, 177),
      (127, 195),
      (110, 185),
      (104, 172)
    ]);
    for (var row = 0; row < 4; row++) {
      final y = 125.0 + row * 16;
      pair('abs', [(137, y), (117, y + 1), (118, y + 14), (137, y + 14)]);
    }
    pair('hip flexors',
        [(107, 190), (120, 194), (135, 208), (128, 217), (110, 204)]);
    pair('quads', [
      (106, 209),
      (122, 219),
      (122, 250),
      (133, 277),
      (123, 299),
      (103, 286),
      (98, 249)
    ]);
    pair('adductors',
        [(126, 224), (139, 219), (137, 250), (130, 271), (126, 250)]);
    pair('shins', [
      (115, 308),
      (123, 312),
      (124, 339),
      (120, 361),
      (113, 359),
      (110, 331)
    ]);
    pair(
        'calves', [(106, 307), (112, 315), (108, 343), (101, 334), (102, 318)]);
  }
  pair(back ? 'triceps' : 'biceps',
      [(75, 108), (89, 106), (85, 132), (75, 156), (66, 152), (69, 125)]);
  pair('forearms',
      [(65, 160), (75, 159), (72, 181), (63, 214), (53, 215), (53, 196)]);
  return shapes;
}

final _frontMuscles = _drawMuscles(false), _backMuscles = _drawMuscles(true);
List<(String, Path)> _muscleShapes(bool back) =>
    back ? _backMuscles : _frontMuscles;
List<(String, Rect)> muscleRegions(bool back) => _muscleShapes(back)
    .map((shape) => (shape.$1, shape.$2.getBounds()))
    .toList();

final _bodyOutline = _contour([
  (130, 51),
  (129, 62),
  (110, 69),
  (84, 69),
  (69, 84),
  (66, 118),
  (61, 148),
  (49, 187),
  (49, 216),
  (43, 235),
  (48, 250),
  (59, 249),
  (69, 228),
  (71, 205),
  (83, 171),
  (89, 147),
  (98, 121),
  (103, 146),
  (106, 177),
  (99, 206),
  (95, 244),
  (99, 281),
  (99, 305),
  (97, 333),
  (102, 356),
  (96, 368),
  (113, 374),
  (128, 370),
  (126, 350),
  (132, 325),
  (127, 302),
  (136, 274),
  (140, 239),
  (144, 274),
  (153, 302),
  (148, 325),
  (154, 350),
  (152, 370),
  (167, 374),
  (184, 368),
  (178, 356),
  (183, 333),
  (181, 305),
  (181, 281),
  (185, 244),
  (181, 206),
  (174, 177),
  (177, 146),
  (182, 121),
  (191, 147),
  (197, 171),
  (209, 205),
  (211, 228),
  (221, 249),
  (232, 250),
  (237, 235),
  (231, 216),
  (231, 187),
  (219, 148),
  (214, 118),
  (211, 84),
  (196, 69),
  (170, 69),
  (151, 62),
  (150, 51)
]);

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
    canvas.drawPath(
        _bodyOutline, Paint()..color = surface.withValues(alpha: .55));
    for (final r in _muscleShapes(back)) {
      canvas.drawPath(
          r.$2, Paint()..color = group(r.$1) == selected ? accent : surface);
    }
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.back != back ||
      old.selected != selected ||
      old.accent != accent ||
      old.surface != surface;
}
