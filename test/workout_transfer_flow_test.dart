import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/screens/ENG/workout/workout_transfer.dart';
import 'package:fitlek1/services/workout_service.dart';

class _Picker extends FilePicker {
  final Object data;
  final String name;
  final bool save;
  final List<String> saved = [];
  bool streamed = false;
  _Picker(this.data, {this.name = 'backup.json', this.save = false});
  @override
  Future<FilePickerResult?> pickFiles(
      {String? dialogTitle,
      String? initialDirectory,
      FileType type = FileType.any,
      List<String>? allowedExtensions,
      Function(FilePickerStatus)? onFileLoading,
      bool allowCompression = true,
      int compressionQuality = 30,
      bool allowMultiple = false,
      bool withData = false,
      bool withReadStream = false,
      bool lockParentWindow = false,
      bool readSequential = false}) async {
    streamed = withReadStream && !withData;
    final bytes =
        utf8.encode(data is String ? data as String : jsonEncode(data));
    return FilePickerResult([
      PlatformFile(
          name: name, size: bytes.length, readStream: Stream.value(bytes))
    ]);
  }

  @override
  Future<String?> saveFile(
      {String? dialogTitle,
      String? fileName,
      String? initialDirectory,
      FileType type = FileType.any,
      List<String>? allowedExtensions,
      Uint8List? bytes,
      bool lockParentWindow = false}) async {
    if (fileName != null) saved.add(fileName);
    return save ? '/fixture/$fileName' : null;
  }
}

void main() {
  testWidgets('Coach transfer offers only scoped history export',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture', 'userId': 17, 'role': 'coach'});
    FilePicker? previous;
    try {
      previous = FilePicker.platform;
    } catch (_) {/* No plugin is registered in widget tests. */}
    FilePicker.platform = _Picker({}, save: true);
    addTearDown(() {
      if (previous != null) FilePicker.platform = previous;
    });
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/history/export'));
      expect(request.url.queryParameters['clientID'], '42');
      return http.Response(
          jsonEncode({
            'sessions': [
              {'name': 'Client workout'}
            ],
            'bodyweight': [],
            'hasMore': false
          }),
          200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(
          const MaterialApp(home: WorkoutTransferScreen(clientID: 42)));
      expect(find.text('Choose history file'), findsNothing);
      expect(find.text('Export workout backup'), findsNothing);
      expect(find.text('Restore backup'), findsNothing);
      await tester.tap(find.text('Export history JSON'));
      await tester.pumpAndSettle();
      expect(find.text('History file 1 exported'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => client);
  });
  testWidgets(
      'backup file preview requires explicit restore and defaults to keeping existing settings',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture', 'userId': 42, 'role': 'client'});
    WorkoutService.preferences = {};
    final picker = _Picker({'format': 'sirvya-workout-backup', 'version': 1});
    FilePicker? previous;
    try {
      previous = FilePicker.platform;
    } catch (_) {/* No plugin is registered in widget tests. */}
    FilePicker.platform = picker;
    addTearDown(() {
      if (previous != null) FilePicker.platform = previous;
    });
    final requests = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/backup/preview')) {
        return http.Response(
            '{"routines":2,"workouts":4,"measurements":3}', 200);
      }
      if (request.url.path.endsWith('/backup/restore')) {
        requests.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('{"alreadyRestored":false}', 201);
      }
      return http.Response('{}', 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: WorkoutTransferScreen()));
      await tester.tap(find.text('Choose history file'));
      await tester.pumpAndSettle();
      expect(picker.streamed, isTrue);
      expect(find.text('Workout backup preview'), findsOneWidget);
      expect(requests, isEmpty);
      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches.every((v) => !v.value), isTrue);
      await tester.scrollUntilVisible(find.text('Restore backup'), 250,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Restore backup'));
      await tester.pumpAndSettle();
      expect(find.text('Restore workout backup?'), findsOneWidget);
      expect(requests, isEmpty);
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      await tester.tap(find.text('Restore backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore backup').last);
      await tester.pumpAndSettle();
      expect(requests.single['restoreSchedule'], false);
      expect(requests.single['restorePreferences'], false);
      await tester.scrollUntilVisible(
          find.text('Workout backup restored'), -200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Workout backup restored'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => client);
  });

  testWidgets(
      'Health measurements preview, import and duplicate results are visible',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture', 'userId': 42, 'role': 'client'});
    WorkoutService.preferences = {};
    final previous = FilePicker.platform;
    final picker = _Picker(
        '<HealthData><Record type="HKQuantityTypeIdentifierStepCount" value="1"/><Record type="HKQuantityTypeIdentifierBodyMass" unit="kg" value="82.5" startDate="2026-10-01 10:00:00 +0000"/></HealthData>',
        name: 'export.xml');
    FilePicker.platform = picker;
    addTearDown(() => FilePicker.platform = previous);
    var imports = 0;
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (request.url.path.endsWith('/import-preview')) {
        expect(body['xml'], contains('BodyMass'));
        expect(body['xml'], isNot(contains('StepCount')));
        return http.Response(
            jsonEncode({
              'format': 'sirvya-workout-history',
              'version': 1,
              'sessions': [],
              'bodyweight': [
                {'recordedAt': '2026-10-01', 'weight': 82.5}
              ],
              'exercises': []
            }),
            200);
      }
      imports++;
      expect(body['sessions'], isEmpty);
      expect((body['bodyweight'] as List).single['weight'], 82.5);
      return http.Response(
          jsonEncode({
            'imported': 0,
            'skipped': 0,
            'bodyweightImported': imports == 1 ? 1 : 0,
            'bodyweightSkipped': imports == 1 ? 0 : 1
          }),
          201);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: WorkoutTransferScreen()));
      for (var repeat = 0; repeat < 2; repeat++) {
        await tester.scrollUntilVisible(find.text('Choose history file'), -200,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('Choose history file'));
        await tester.pumpAndSettle();
        expect(imports, repeat);
        await tester.scrollUntilVisible(
            find.text('1 measurements ready to import'), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(find.text('1 measurements ready to import'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Import measurements'), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Import measurements'));
        await tester.pumpAndSettle();
        expect(
            find.text(repeat == 0
                ? '0 workouts imported · 0 duplicate workouts skipped · 1 measurements imported · 0 duplicate measurements skipped'
                : '0 workouts imported · 0 duplicate workouts skipped · 0 measurements imported · 1 duplicate measurements skipped'),
            findsOneWidget);
      }
      expect(picker.streamed, isTrue);
      expect(tester.takeException(), isNull);
    }, () => client);
  });

  testWidgets(
      'export next file advances workout and weight cursors independently',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture', 'userId': 42, 'role': 'client'});
    final previous = FilePicker.platform;
    final picker = _Picker({}, save: true);
    FilePicker.platform = picker;
    addTearDown(() {
      FilePicker.platform = previous;
    });
    var pages = 0;
    final client = MockClient((request) async {
      expect(request.url.queryParameters['offset'], pages == 0 ? '0' : '1');
      expect(
          request.url.queryParameters['weightOffset'], pages == 0 ? '0' : '1');
      pages++;
      return http.Response(
          jsonEncode({
            'sessions': pages == 1
                ? [
                    {'name': 'one'}
                  ]
                : [],
            'bodyweight': [
              {'weight': 82.5}
            ],
            'hasMore': pages == 1
          }),
          200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: WorkoutTransferScreen()));
      await tester.tap(find.text('Export history JSON'));
      await tester.pumpAndSettle();
      expect(find.text('Export next history file'), findsOneWidget);
      await tester.tap(find.text('Export next history file'));
      await tester.pumpAndSettle();
      expect(find.text('Export history JSON'), findsOneWidget);
      expect(pages, 2);
      expect(picker.saved,
          ['sirvya-workout-history-1.json', 'sirvya-workout-history-2.json']);
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
