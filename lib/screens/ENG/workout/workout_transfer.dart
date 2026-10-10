import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../services/workout_file.dart';
import '../../../services/workout_import_reader.dart';
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
  Map<String, dynamic>? _backup;
  Map<String, dynamic>? _backupSummary;
  bool _restoreSchedule = false, _restorePreferences = false;
  final Map<String, int> _mappings = {};
  bool _busy = false, _create = false;
  String? _result;
  int _exportPart = 1, _exportSessionOffset = 0, _exportWeightOffset = 0;
  bool _exportHasMore = false;
  Future<void> _read() async {
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'json', 'xml'],
          withData: false,
          withReadStream: true);
      if (picked == null) return;
      final file = picked.files.single;
      final health = file.extension?.toLowerCase() == 'xml';
      if (file.size >
          (health ? workoutHealthByteLimit : workoutImportByteLimit)) {
        throw const WorkoutApiException('import_too_large', 413);
      }
      final stream = file.readStream ??
          (file.bytes == null ? null : Stream.value(file.bytes!));
      if (stream == null) {
        throw const WorkoutApiException('invalid_import', 400);
      }
      final content = await readWorkoutImport(stream, healthXML: health);
      final decoded =
          file.extension?.toLowerCase() == 'json' ? jsonDecode(content) : null;
      if (decoded is Map<String, dynamic> &&
          decoded['format'] == 'sirvya-workout-backup') {
        final summary =
            await WorkoutService.post('/backup/preview', {'backup': decoded});
        if (mounted) {
          setState(() {
            _backup = decoded;
            _backupSummary = summary;
            _preview = null;
            _result = null;
            _restoreSchedule = false;
            _restorePreferences = false;
          });
        }
        return;
      }
      final result = await WorkoutService.post(
          '/history/import-preview',
          file.extension == 'json'
              ? {'history': decoded}
              : {
                  file.extension == 'xml' ? 'xml' : 'csv': content,
                  'unit': WorkoutService.unit,
                  'timeZone': WorkoutService.preferences['timeZone'] ?? 'UTC'
                });
      if (!mounted) return;
      setState(() {
        _preview = result;
        _backup = null;
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

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final data = await WorkoutService.get('/backup/export');
      final saved = await saveWorkoutJson('sirvya-workout-backup.json', data);
      if (saved && mounted) setState(() => _result = 'Workout backup exported');
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const WorkoutLabel('Restore workout backup?'),
              content: const WorkoutLabel(
                  'Adds routines and completed workouts. Coach routines become personal copies. Selected schedule and preference options replace your current settings. Existing history is kept.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const WorkoutLabel('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const WorkoutLabel('Restore backup')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await WorkoutService.post('/backup/restore', {
        'backup': _backup,
        'restoreSchedule': _restoreSchedule,
        'restorePreferences': _restorePreferences,
      });
      if (_restorePreferences) {
        WorkoutService.preferences = await WorkoutService.get('/preferences');
      }
      if (mounted) {
        setState(() {
          _backup = null;
          _backupSummary = null;
          _result = result['alreadyRestored'] == true
              ? 'This backup was already restored'
              : 'Workout backup restored';
        });
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final result = await WorkoutService.post('/history/import', {
        'format': 'sirvya-workout-history',
        'version': 1,
        'unit': 'kg',
        'source': _preview!['source'],
        'sessions': workoutRows(_preview!['sessions']),
        'mappings': _mappings,
        'createUnmatched': _create,
        'bodyweight': _preview!['bodyweight'] ?? [],
      });
      if (mounted) {
        setState(() {
          _result =
              '${workoutInt(result['imported'])} workouts imported · ${workoutInt(result['skipped'])} duplicate workouts skipped · ${workoutInt(result['bodyweightImported'])} measurements imported · ${workoutInt(result['bodyweightSkipped'])} duplicate measurements skipped';
          _preview = null;
          _exportPart = 1;
          _exportSessionOffset = 0;
          _exportWeightOffset = 0;
          _exportHasMore = false;
        });
      }
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      var limit = 100;
      Map<String, dynamic> data;
      while (true) {
        data = await WorkoutService.get(
            '/history/export?offset=$_exportSessionOffset&weightOffset=$_exportWeightOffset&limit=$limit${widget.clientID == null ? '' : '&clientID=${widget.clientID}'}');
        if (workoutRows(data['sessions']).isEmpty &&
            workoutRows(data['bodyweight']).isEmpty) {
          throw const WorkoutApiException('empty_export', 400);
        }
        if (utf8
                .encode(const JsonEncoder.withIndent('  ').convert(data))
                .length <=
            workoutImportByteLimit) {
          break;
        }
        if (limit == 1) {
          throw const WorkoutApiException('import_too_large', 413);
        }
        limit = (limit ~/ 2).clamp(1, 100);
      }
      final saved = await saveWorkoutJson(
          'sirvya-workout-history-$_exportPart.json', data);
      if (saved && mounted) {
        setState(() {
          _exportSessionOffset += workoutRows(data['sessions']).length;
          _exportWeightOffset += workoutRows(data['bodyweight']).length;
          _exportHasMore = data['hasMore'] == true;
          _result = 'History file $_exportPart exported';
          _exportPart++;
          if (!_exportHasMore) {
            _exportPart = 1;
            _exportSessionOffset = 0;
            _exportWeightOffset = 0;
          }
        });
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
            const SizedBox(height: 8),
            const WorkoutLabel(
                'History and backup files: up to 8 MiB. Apple Health XML: up to 256 MiB, read in chunks; up to 1,000 measurement days.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: _busy ? null : _read,
                icon: const Icon(Icons.upload_file),
                label: const WorkoutLabel('Choose history file')),
            OutlinedButton.icon(
                onPressed: _busy ? null : _exportBackup,
                icon: const Icon(Icons.backup_outlined),
                label: const WorkoutLabel('Export workout backup')),
            const WorkoutLabel(
                'Includes routines, schedules, preferences, completed workouts and measurements. Active workouts, device drafts and uploaded media are excluded. Backup limits: 100 plans and 1,000 workouts and measurements.'),
          ],
          OutlinedButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.download_outlined),
              label: WorkoutLabel(_exportHasMore
                  ? 'Export next history file'
                  : 'Export history JSON')),
          const WorkoutLabel(
              'History exports are split into files of up to 100 workouts and 100 measurements. Continue exporting until the next-file button disappears.'),
          if (_busy) const LinearProgressIndicator(),
          if (_result != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: WorkoutLabel(_result!)),
          if (_backup != null) ...[
            const SizedBox(height: 20),
            const WorkoutLabel('Workout backup preview',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            WorkoutLabel(
                '${_backupSummary?['routines']} routines · ${_backupSummary?['workouts']} workouts · ${_backupSummary?['measurements']} measurements'),
            SwitchListTile(
                title: const WorkoutLabel(
                    'Replace weekly schedule and date overrides'),
                value: _restoreSchedule,
                onChanged:
                    _busy ? null : (v) => setState(() => _restoreSchedule = v)),
            SwitchListTile(
                title: const WorkoutLabel('Replace workout preferences'),
                value: _restorePreferences,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _restorePreferences = v)),
            ElevatedButton(
                onPressed: _busy ? null : _restoreBackup,
                child: const WorkoutLabel('Restore backup')),
            TextButton(
                onPressed: _busy ? null : () => setState(() => _backup = null),
                child: const WorkoutLabel('Cancel')),
          ],
          if (_preview != null) ...[
            const SizedBox(height: 20),
            WorkoutLabel(
                '${workoutRows(_preview!['sessions']).length} workouts ready to import',
                style: Theme.of(context).textTheme.titleLarge),
            if (workoutRows(_preview!['bodyweight']).isNotEmpty)
              WorkoutLabel(
                  '${workoutRows(_preview!['bodyweight']).length} measurements ready to import'),
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
                child: WorkoutLabel(workoutRows(_preview!['sessions']).isEmpty
                    ? 'Import measurements'
                    : 'Import workouts'))
          ]
        ]));
  }
}
