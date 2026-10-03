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
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/models/workout_demonstration.dart';
import 'package:fitlek1/services/workout_service.dart';
import 'package:fitlek1/screens/ENG/workout/workout_balance.dart';
import 'package:fitlek1/screens/ENG/workout/workout_demonstration.dart';
import 'package:fitlek1/screens/ENG/workout/workout_ui.dart';
import 'package:fitlek1/theme/app_theme.dart';

const exercise = Exercise(
    id: 1,
    name: 'Bench Press',
    muscleGroup: 'chest',
    equipment: 'barbell',
    type: 'reps',
    isBodyweight: false,
    externalSource: 'sirvya',
    externalId: 'bench-press');
const records = [
  {'exerciseID': 10, 'name': 'Bench Press', 'estimated1RM': 100},
  {'exerciseID': 20, 'name': 'Shoulder Press', 'estimated1RM': 60}
];
const captureKey = ValueKey('continuation_capture');
Widget screen(Widget child, {bool reduceMotion = false}) => MaterialApp(
    theme: AppTheme.dark,
    home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: RepaintBoundary(
            key: captureKey,
            child: WorkoutScaffold(
                appBar: AppBar(title: const WorkoutLabel('SIRVYA Workout')),
                body: ListView(
                    padding: const EdgeInsets.all(20), children: [child])))));

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['WORKOUT_CAPTURE_SCREENSHOTS'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('docs/verification/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42, 'role': 'coach'});
    WorkoutService.preferences = {'balanceAnchorID': 999, 'unit': 'lb'};
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(396, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (Platform.environment['WORKOUT_CAPTURE_SCREENSHOTS'] == '1') {
      await tester.runAsync(() async {
        await (FontLoader('Roboto')
              ..addFont(
                  rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'))
              ..addFont(
                  rootBundle.load('assets/workout/fonts/Roboto-Bold.ttf')))
            .load();
        final fonts = FontLoader('SirvyaWorkout')
          ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/workout/fonts/Roboto-Bold.ttf'));
        await fonts.load();
        await (FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
            .load();
      });
    }
  }

  testWidgets(
      'demonstrations use source IDs rather than names and include native controls and attribution',
      (tester) async {
    await phone(tester);
    final demo = await tester
        .runAsync(() => WorkoutDemonstrationCatalog.forExercise(exercise));
    expect(demo!.frames.length, 2);
    expect(
        await tester.runAsync(() => WorkoutDemonstrationCatalog.forExercise(
            const Exercise(
                id: 9,
                name: 'Bench Press',
                muscleGroup: 'chest',
                equipment: 'barbell',
                type: 'reps',
                isBodyweight: false,
                externalSource: 'custom',
                externalId: 'bench-press'))),
        isNull);
    await tester.pumpWidget(
        screen(const WorkoutDemonstrationPanel(exercise: exercise)));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final frame in demo.frames) {
        await precacheImage(AssetImage('${frame['asset']}'),
            tester.element(find.byType(WorkoutDemonstrationPanel)));
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Everkinetic · CC BY-SA 3.0'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Next demonstration frame'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Play demonstration'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause demonstration'));
    await tester.pumpAndSettle();
    await capture(tester, 'native-demonstration');
    await tester.tap(find.text('Everkinetic · CC BY-SA 3.0'));
    await tester.pumpAndSettle();
    expect(find.text('Illustration credits'), findsOneWidget);
    expect(find.text('Illustration source'), findsOneWidget);
    expect(find.text('Illustration license'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reduced motion disables automatic demonstrations and disposal cancels playback',
      (tester) async {
    await tester
        .runAsync(() => WorkoutDemonstrationCatalog.forExercise(exercise));
    await tester.pumpWidget(screen(
        const WorkoutDemonstrationPanel(exercise: exercise),
        reduceMotion: true));
    await tester.pumpAndSettle();
    final play = tester.widget<IconButton>(find.byWidgetPredicate((widget) =>
        widget is IconButton && widget.tooltip == 'Play demonstration'));
    expect(play.onPressed, isNull);
    await tester.tap(find.byTooltip('Next demonstration frame'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(
        screen(const WorkoutDemonstrationPanel(exercise: exercise)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play demonstration'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Coach saves edits and deletes a linked client protocol without changing own preferences',
      (tester) async {
    await phone(tester);
    var balance = <String, dynamic>{
      'balanceAnchorID': 10,
      'balanceTargets': [
        {'exerciseID': 20, 'targetPercent': 75}
      ],
      'balanceProtocols': [],
      'activeBalanceProtocolID': null
    };
    final writes = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      expect(request.url.path, '/api/workout/balance');
      expect(request.url.queryParameters['clientID'], '7');
      if (request.method == 'PUT') {
        final changes = Map<String, dynamic>.from(jsonDecode(request.body));
        writes.add(changes);
        balance = {...balance, ...changes};
        final active = balance['activeBalanceProtocolID'];
        if (active != null) {
          final p = workoutRows(balance['balanceProtocols'])
              .firstWhere((p) => p['id'] == active);
          balance = {
            ...balance,
            'balanceAnchorID': p['anchorID'],
            'balanceTargets': p['targets']
          };
        }
      }
      return http.Response(jsonEncode(balance), 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(
          screen(const WorkoutBalanceCard(clientID: 7, records: records)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save balance protocol'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Upper targets');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(writes.single['balanceProtocols'][0]['anchorID'], 10);
      expect(WorkoutService.preferences['balanceAnchorID'], 999);
      expect(WorkoutService.preferences['unit'], 'lb');
      await capture(tester, 'native-balance-protocol');
      await tester.tap(find.byTooltip('Set target ratio'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a value from 1 to 500'), findsOneWidget);
      expect(writes.length, 1);
      await tester.enterText(find.byType(TextFormField), '80');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(writes.last['activeBalanceProtocolID'], isNull);
      expect(balance['balanceTargets'][0]['targetPercent'], 80);
      // Selecting the saved protocol restores its original targets.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upper targets').last);
      await tester.pumpAndSettle();
      expect(balance['balanceTargets'][0]['targetPercent'], 75);
      await tester.tap(find.text('Delete protocol'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(balance['balanceProtocols'], isEmpty);
      expect(balance['activeBalanceProtocolID'], isNull);
      expect(balance['balanceTargets'][0]['targetPercent'], 75);
      expect(tester.takeException(), isNull);
    }, () => client);
  });

  testWidgets(
      'a missing protocol anchor does not silently compare against another lift',
      (tester) async {
    final client = MockClient((_) async => http.Response(
        jsonEncode({
          'balanceAnchorID': 30,
          'balanceTargets': [],
          'balanceProtocols': [],
          'activeBalanceProtocolID': null
        }),
        200));
    await http.runWithClient(() async {
      await tester.pumpWidget(
          screen(const WorkoutBalanceCard(clientID: 7, records: records)));
      await tester.pumpAndSettle();
      expect(find.text('Record the anchor exercise to compare this protocol.'),
          findsOneWidget);
      expect(find.textContaining('Anchor ratio:'), findsNothing);
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
