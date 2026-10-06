import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';

// Coordinate data is MuscleMap by Melih Colpan (MIT); see the bundled notice.
// Parsing, native painting, shading and hit testing are implemented here.
const _muscles = {
  'trapezius': 'traps',
  'deltoids': 'shoulders',
  'chest': 'chest',
  'upper-back': 'upper back',
  'serratus': 'serratus',
  'biceps': 'biceps',
  'triceps': 'triceps',
  'forearm': 'forearms',
  'abs': 'abs',
  'obliques': 'obliques',
  'lower-back': 'lower back',
  'gluteal': 'glutes',
  'quadriceps': 'quads',
  'hamstring': 'hamstrings',
  'adductors': 'adductors',
  'hip-flexors': 'hip flexors',
  'calves': 'calves',
  'tibialis': 'shins'
};
const _inert = {'head', 'hair', 'neck', 'hands', 'feet', 'knees', 'ankles'};
const workoutAnatomySize = Size(216, 380);

class _PathReceiver extends PathProxy {
  final path = Path();
  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  @override
  void cubicTo(
          double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);
  @override
  void close() => path.close();
}

class WorkoutAnatomy {
  final List<Path> silhouette;
  final List<(String, Path)> muscles;
  const WorkoutAnatomy(this.silhouette, this.muscles);
  String? muscleAt(Offset point) {
    for (final shape in muscles.reversed) {
      if (shape.$2.contains(point)) return shape.$1;
    }
    return null;
  }

  factory WorkoutAnatomy.fromJson(Map<String, dynamic> view) {
    final bounds = (view['vb'] as String).split(' ').map(double.parse).toList();
    final scale = math.min(workoutAnatomySize.width / bounds[2],
        workoutAnatomySize.height / bounds[3]);
    const width = 216.0, height = 380.0;
    final x = (width - bounds[2] * scale) / 2 - bounds[0] * scale;
    final y = (height - bounds[3] * scale) / 2 - bounds[1] * scale;
    final matrix = Float64List.fromList(
        [scale, 0, 0, 0, 0, scale, 0, 0, 0, 0, 1, 0, x, y, 0, 1]);
    final silhouette = <Path>[];
    final muscles = <(String, Path)>[];
    final paths = view['p'] as Map<String, dynamic>;
    for (final name in [..._inert, ..._muscles.keys]) {
      for (final data in (paths[name] as List? ?? const [])) {
        final receiver = _PathReceiver();
        writeSvgPathDataToPath(data as String, receiver);
        final path = receiver.path.transform(matrix);
        if (_inert.contains(name)) {
          silhouette.add(path);
        } else {
          muscles.add((_muscles[name]!, path));
        }
      }
    }
    return WorkoutAnatomy(silhouette, muscles);
  }
}

Future<Map<String, WorkoutAnatomy>>? _pending;
Map<String, WorkoutAnatomy>? _cached;
Future<Map<String, WorkoutAnatomy>> loadWorkoutAnatomy() {
  if (_cached != null) return SynchronousFuture(_cached!);
  return _pending ??= () async {
    final json = jsonDecode(await rootBundle.loadString(
        'assets/workout/anatomy/musclemap.json')) as Map<String, dynamic>;
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(['MuscleMap anatomy'],
          await rootBundle.loadString('assets/workout/anatomy/LICENSE.txt'));
    });
    return _cached = {
      for (final body in ['male', 'female'])
        for (final side in ['front', 'back'])
          '$body-$side': WorkoutAnatomy.fromJson(
              Map<String, dynamic>.from(json[body][side]))
    };
  }();
}

int workoutAnatomyLevel(double value, double maximum) =>
    value <= 0 || maximum <= 0 ? 0 : (value / maximum * 4).ceil().clamp(1, 4);

class WorkoutAnatomyView extends StatelessWidget {
  final bool back;
  const WorkoutAnatomyView(
      {super.key,
      this.back = false,
      this.body = 'male',
      this.load = const {},
      this.selected,
      this.onMuscle,
      this.group});
  final String body;
  final Map<String, double> load;
  final String? selected;
  final ValueChanged<String>? onMuscle;
  final String Function(String)? group;
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<Map<String, WorkoutAnatomy>>(
          future: loadWorkoutAnatomy(),
          builder: (context, snapshot) {
            final view = snapshot.data?['$body-${back ? 'back' : 'front'}'];
            if (view == null) return const SizedBox(width: 216, height: 380);
            final colors = Theme.of(context).colorScheme;
            return GestureDetector(
                onTapUp: onMuscle == null
                    ? null
                    : (tap) {
                        final muscle = view.muscleAt(tap.localPosition);
                        if (muscle != null) {
                          onMuscle!(group?.call(muscle) ?? muscle);
                        }
                      },
                child: CustomPaint(
                    size: workoutAnatomySize,
                    painter:
                        _AnatomyPainter(view, load, selected, group, colors)));
          });
}

class _AnatomyPainter extends CustomPainter {
  final WorkoutAnatomy view;
  final Map<String, double> load;
  final String? selected;
  final String Function(String)? group;
  final ColorScheme colors;
  const _AnatomyPainter(
      this.view, this.load, this.selected, this.group, this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    final base = Color.lerp(colors.surface, colors.onSurface, .11)!;
    final silhouette = Color.lerp(colors.surface, colors.onSurface, .18)!;
    final maximum = load.values.fold<double>(0, math.max);
    final separator = Paint()
      ..style = PaintingStyle.stroke
      ..color = colors.surface
      ..strokeWidth = .7
      ..strokeJoin = StrokeJoin.round;
    for (final path in view.silhouette) {
      canvas.drawPath(path, Paint()..color = silhouette);
      canvas.drawPath(path, separator);
    }
    for (final shape in view.muscles) {
      final muscle = group?.call(shape.$1) ?? shape.$1;
      final level = workoutAnatomyLevel(load[muscle] ?? 0, maximum);
      final shade = [0.0, .32, .56, .78, 1.0][level];
      canvas.drawPath(
          shape.$2, Paint()..color = Color.lerp(base, colors.primary, shade)!);
      canvas.drawPath(shape.$2, separator);
      if (muscle == selected) {
        canvas.drawPath(
            shape.$2,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = colors.onSurface
              ..strokeWidth = 1.8);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnatomyPainter old) =>
      old.view != view ||
      old.load != load ||
      old.selected != selected ||
      old.colors != colors ||
      old.group != group;
}
