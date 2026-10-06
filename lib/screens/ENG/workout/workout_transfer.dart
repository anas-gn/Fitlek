import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../services/workout_file.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import 'exercise_library.dart';
import 'workout_ui.dart';

class WorkoutTransferScreen extends StatefulWidget {
  final int? clientID;
  const WorkoutTransferScreen({super.key, this.clientID});
  @override
  State<WorkoutTransferScreen> createState() => _WorkoutTransferScreenState();
}

class _WorkoutTransferScreenState extends State<WorkoutTransferScreen> {
  Map<String, dynamic>? _preview;
  final Map<String, int> _mappings = {};
  bool _busy = false, _create = false;
  String? _result;
  Future<void> _read() async {
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'json', 'xml'],
          withData: true);
      if (picked == null) return;
      final file = picked.files.single;
      if (file.size > 8 * 1024 * 1024 || file.bytes == null) {
        throw const WorkoutApiException('invalid_import', 400);
      }
      final content = utf8.decode(file.bytes!);
      final result = await WorkoutService.post(
          '/history/import-preview',
          file.extension == 'json'
              ? {'history': jsonDecode(content)}
              : {
                  file.extension == 'xml' ? 'xml' : 'csv': content,
                  'unit': WorkoutService.unit,
                  'timeZone': WorkoutService.preferences['timeZone'] ?? 'UTC'
                });
      if (!mounted) return;
      setState(() {
        _preview = result;
        _result = null;
        _mappings.clear();
        for (final e in workoutRows(result['exercises'])) {
          final matches = workoutRows(e['matches']);
          if (matches.length == 1) {
            _mappings['${e['sourceKey']}'] = workoutInt(matches.single['id']);
          }
        }
      });
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final rows = workoutRows(_preview!['sessions']);
      var imported = 0, skipped = 0;
      for (var offset = 0;
          offset < (rows.isEmpty ? 1 : rows.length);
          offset += 100) {
        final result = await WorkoutService.post('/history/import', {
          'format': 'sirvya-workout-history',
          'version': 1,
          'source': _preview!['source'],
          'sessions': rows.skip(offset).take(100).toList(),
          'mappings': _mappings,
          'createUnmatched': _create,
          if (offset == 0) 'bodyweight': _preview!['bodyweight'] ?? []
        });
        imported += workoutInt(result['imported']);
        skipped += workoutInt(result['skipped']);
        if (mounted) {
          setState(() =>
              _result = '$imported imported · $skipped duplicates skipped');
        }
      }
      if (mounted) setState(() => _preview = null);
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final sessions = <Map<String, dynamic>>[];
      final weights = <Map<String, dynamic>>[];
      var page = 1;
      while (true) {
        final data = await WorkoutService.get(
            '/history/export?page=$page${widget.clientID == null ? '' : '&clientID=${widget.clientID}'}');
        sessions.addAll(workoutRows(data['sessions']));
        weights.addAll(workoutRows(data['bodyweight']));
        if (data['hasMore'] != true) break;
        page++;
      }
      final saved = await saveWorkoutJson('sirvya-workout-history.json', {
        'format': 'sirvya-workout-history',
        'version': 1,
        'source': 'SIRVYA',
        'unit': 'kg',
        'sessions': sessions,
        'bodyweight': weights
      });
      if (saved && mounted) {
        setState(() => _result = 'Workout history exported');
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = workoutRows(_preview?['exercises']);
    return WorkoutScaffold(
        appBar: AppBar(title: const WorkoutLabel('Transfer workout history')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          if (widget.clientID == null) ...[
            const WorkoutLabel(
                'Import Strong, Hevy or FitNotes CSV, Apple Health bodyweight XML, or SIRVYA history JSON.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: _busy ? null : _read,
                icon: const Icon(Icons.upload_file),
                label: const WorkoutLabel('Choose history file')),
          ],
          OutlinedButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.copy),
              label: const WorkoutLabel('Copy history JSON')),
          if (_busy) const LinearProgressIndicator(),
          if (_result != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: WorkoutLabel(_result!)),
          if (_preview != null) ...[
            const SizedBox(height: 20),
            WorkoutLabel(
                '${workoutRows(_preview!['sessions']).length} workouts ready to import',
                style: Theme.of(context).textTheme.titleLarge),
            const WorkoutLabel(
                'Match each exercise to the library. Unmatched exercises can become private custom exercises.'),
            ...entries.map((e) => Card(
                child: ListTile(
                    title: WorkoutLabel('${e['name']}'),
                    subtitle: WorkoutLabel(
                        _mappings.containsKey('${e['sourceKey']}')
                            ? 'Exercise matched'
                            : 'Choose exercise'),
                    trailing: const Icon(Icons.search),
                    onTap: _busy
                        ? null
                        : () async {
                            final picked = await Navigator.push<Exercise>(
                                context,
                                WorkoutRoute(
                                    builder: (_) =>
                                        const WorkoutExerciseLibrary(
                                            selecting: true)));
                            if (picked != null && context.mounted) {
                              if (picked.type != e['exerciseType']) {
                                workoutError(
                                    context,
                                    const WorkoutApiException(
                                        'invalid_target', 400));
                                return;
                              }
                              setState(() =>
                                  _mappings['${e['sourceKey']}'] = picked.id);
                            }
                          }))),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const WorkoutLabel(
                    'Create private exercises for unmatched entries'),
                value: _create,
                onChanged: _busy ? null : (v) => setState(() => _create = v)),
            ElevatedButton(
                onPressed: _busy ||
                        (!_create &&
                            entries.any((e) =>
                                !_mappings.containsKey('${e['sourceKey']}')))
                    ? null
                    : _import,
                child: const WorkoutLabel('Import workouts'))
          ]
        ]));
  }
}
