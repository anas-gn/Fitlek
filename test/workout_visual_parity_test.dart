import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/screens/ENG/workout/workout_home.dart';
import 'package:fitlek1/screens/ENG/workout/workout_anatomy.dart';
import 'package:fitlek1/services/workout_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadWorkoutAnatomy();
  });
  final fixture = jsonDecode(
          File('test/fixtures/workout-product-parity.json').readAsStringSync())
      as Map<String, dynamic>;
  final bodyParts = Map<String, dynamic>.from(jsonDecode(
      File('backend/data/exerciseBodyParts.json').readAsStringSync()));
  final catalog = (jsonDecode(
              File('backend/data/exerciseMetadata.json').readAsStringSync())
          as List)
      .asMap()
      .entries
      .map((entry) {
    final exercise = Map<String, dynamic>.from(entry.value);
    final external = exercise['externalId'];
    return <String, dynamic>{
      ...exercise,
      'id': external == '0025'
          ? 1
          : external == '0027'
              ? 2
              : entry.key + 1000,
      'externalSource': 'exercises-dataset',
      'bodyPart': bodyParts[external],
      'bestWeight': external == '0025'
          ? 60
          : external == '0027'
              ? 40
              : 0,
      'usageCount': ['0025', '0027'].contains(external) ? 2 : 0
    };
  }).toList()
    ..sort((a, b) =>
        '${a['name']}'.toLowerCase().compareTo('${b['name']}'.toLowerCase()));
  final equipmentCounts = <String, int>{};
  for (final exercise in catalog) {
    final equipment = '${exercise['equipment']}';
    equipmentCounts[equipment] = (equipmentCounts[equipment] ?? 0) + 1;
  }
  final equipmentOptions = equipmentCounts.keys.toList()
    ..sort((a, b) => equipmentCounts[b]!.compareTo(equipmentCounts[a]!) == 0
        ? a.compareTo(b)
        : equipmentCounts[b]!.compareTo(equipmentCounts[a]!));
  for (final width in [320.0, 396.0, 1100.0]) {
    testWidgets('Workout navigation, charts and timers at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues(
          {'token': 'parity-fixture-only', 'userId': 42, 'role': 'client'});
      final font = FontLoader('SirvyaWorkout')
        ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'));
      await font.load();
      final fallback = FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'));
      await fallback.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      var active = false, sessionReads = 0;
      Map<String, dynamic>? weekWrite, dateWrite;
      final activeData =
          jsonDecode(jsonEncode(fixture['active'])) as Map<String, dynamic>;
      final key = GlobalKey();
      final client = MockClient((req) async {
        final path = req.url.path;
        Object data = {'data': []};
        if (path.endsWith('/plans')) {
          data = {
            'data': [fixture['plan']]
          };
        }
        if (path.endsWith('/stats')) data = fixture['stats'];
        if (path.endsWith('/history')) data = {'data': fixture['history']};
        if (path.endsWith('/schedule')) data = fixture['schedule'];
        if (req.method == 'PUT' && path.endsWith('/week')) {
          weekWrite = Map<String, dynamic>.from(jsonDecode(req.body));
        }
        if (req.method == 'PUT' && path.endsWith('/schedule')) {
          dateWrite = Map<String, dynamic>.from(jsonDecode(req.body));
        }
        if (path.endsWith('/exercises')) {
          data = {
            'data': catalog
                .take(req.url.queryParameters['picker'] == 'true' ? 50 : 40)
                .toList(),
            'total': catalog.length,
            'chosenCount': 2,
            'hasMore': true,
            'filters': {
              'bodyPart': bodyParts.values.toSet().toList()..sort(),
              'equipment': equipmentOptions,
            }
          };
        }
        if (path.endsWith('/preferences')) {
          data = {
            'unit': 'kg',
            'view': 'cards',
            'automaticRest': true,
            'bodyweightCheckIn': true,
            'effort': 'rir'
          };
        }
        if (path.endsWith('/sessions/active')) {
          data = {'session': active ? activeData : null};
        }
        if (path.endsWith('/sessions') && req.method == 'POST') {
          active = true;
          data = {'id': 7};
        }
        if (path.endsWith('/sessions/7')) {
          sessionReads++;
          data = activeData;
          if (req.method == 'PUT') {
            active = false;
            data = {
              'durationSeconds': 1800,
              'volume': 600,
              'setCount': 1,
              'newPRs': 0,
              'loadRecords': [],
              'estimatedRecords': []
            };
          }
        }
        if (req.method == 'PUT' && path.endsWith('/sets')) {
          (activeData['sets'] as List)
              .add({...jsonDecode(req.body) as Map<String, dynamic>, 'id': 1});
          data = {'saved': true};
        }
        return http.Response(jsonEncode(data), 200);
      });
      Future<void> capture(String page) async {
        expect(tester.takeException(), isNull, reason: '$page at $width');
        if (Platform.environment['WORKOUT_CAPTURE'] != '1' || width == 320) {
          return;
        }
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
              'docs/verification/parity/sirvya-$page-${width.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }

      await http.runWithClient(() async {
        WorkoutService.preferences = {};
        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData.light().copyWith(
                    textTheme: ThemeData.light()
                        .textTheme
                        .apply(fontFamily: 'SirvyaWorkout')),
                home: WorkoutHomeScreen(
                    clock: () =>
                        DateTime.parse(fixture['now'] as String).toLocal()))));
        await tester.pumpAndSettle();
        await capture('home');
        await tester.tap(find.text('1 week streak'));
        await tester.pumpAndSettle();
        expect(find.text('1 workout · 30 min · 2900 kg'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
        expect(find.text('Rescheduled'), findsOneWidget);
        await capture('calendar');
        await tester.tapAt(const Offset(2, 2));
        await tester.pumpAndSettle();
        await tester.tap(find.text('4'));
        await tester.pumpAndSettle();
        await capture('day-override');
        await tester.tap(find
            .descendant(
                of: find.byType(BottomSheet), matching: find.text('Full body'))
            .last);
        await tester.pumpAndSettle();
        expect(dateWrite?['date'], '2026-10-04');
        expect(dateWrite?['dayIDs'], [2]);
        expect(find.byType(BottomSheet), findsNothing);
        await tester.tap(find.byKey(const ValueKey('workout-tab-4')));
        await tester.pumpAndSettle();
        await capture('library');
        await tester.tap(find.text('Create your own exercise'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byType(TextFormField).first, 'Indoor cycling');
        await tester.pump();
        await capture('custom');
        await tester.tapAt(const Offset(2, 2));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('workout-tab-1')));
        await tester.pumpAndSettle();
        expect(find.text('Week schedule'), findsOneWidget);
        await capture('plan');
        await tester.tap(find.text('Monday'));
        await tester.pumpAndSettle();
        await capture('day-assignment');
        await tester.tap(find
            .descendant(
                of: find.byType(BottomSheet), matching: find.text('Full body'))
            .last);
        await tester.pumpAndSettle();
        expect(weekWrite?['weekday'], 1);
        expect(weekWrite?['dayIDs'], [2]);
        expect(find.byType(BottomSheet), findsNothing);
        await tester.tap(find.text('Full body').last);
        await tester.pumpAndSettle();
        await capture('editor');
        await tester.tap(find.text('Barbell Bench Press'));
        await tester.pumpAndSettle();
        await capture('configuration');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Add exercise'), 300,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('Add exercise'));
        await tester.pumpAndSettle();
        await capture('picker');
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byTooltip('Back'), -300,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('workout-tab-3')));
        await tester.pumpAndSettle();
        expect(find.text('Progress & history'), findsOneWidget);
        await capture('stats');
        await tester.tap(find.byTooltip('History'));
        await tester.pumpAndSettle();
        await capture('history');
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('workout-tab-0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('workout-tab-2')));
        await tester.pumpAndSettle();
        await capture('checkin');
        await tester.tap(find.text('Start without weighing in'));
        await tester.pumpAndSettle();
        expect(find.byType(WorkoutHomeScreen), findsOneWidget);
        expect(find.text('Resume'), findsWidgets);
        await capture('active');
        final firstDone = find.descendant(
            of: find.byKey(const ValueKey('11:1')),
            matching: find.byTooltip('Complete set'));
        await tester.ensureVisible(firstDone);
        await tester.tap(firstDone);
        await tester.pumpAndSettle();
        expect(find.text('Rest'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('workout-tab-3')));
        await tester.pumpAndSettle();
        expect(find.text('Rest'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('workout-tab-2')));
        await tester.pumpAndSettle();
        final readsBefore = sessionReads;
        await tester.tap(find.byKey(const ValueKey('workout-tab-0')));
        await tester.pumpAndSettle();
        // Today's Resume and the center tab must return to the same retained route.
        await tester.tap(find.byKey(const ValueKey('workout-tab-2')));
        await tester.pumpAndSettle();
        expect(sessionReads, readsBefore);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Finish workout'));
        await tester.pumpAndSettle();
        expect(find.text('Finish with incomplete sets?'), findsOneWidget);
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();
        expect(find.text('Workout complete!'), findsOneWidget);
        expect(find.text('600 kg'), findsOneWidget);
        expect(find.text('Rest'), findsNothing);
        await capture('summary');
        await tester.tapAt(const Offset(2, 2));
        await tester.pumpAndSettle();
        expect(find.text('Workout complete!'), findsOneWidget);
        await tester.tap(find.text('Nice!'));
        await tester.pumpAndSettle();
        expect(find.text('Workout complete!'), findsNothing);
        expect(find.text('Resume'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => client);
    });
  }
}
