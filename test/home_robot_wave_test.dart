import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/home_robot_wave.dart';

// Let native GIF decoding complete between fake-clock frame advances.
Future<void> advanceGif(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Widget greeting(
        {required bool active,
        bool reduceMotion = false,
        bool visible = true,
        Random? random}) =>
    MaterialApp(
      home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: TickerMode(
              enabled: visible,
              child: Scaffold(
                body: Center(
                    child: HomeRobotWave(active: active, random: random)),
              ))),
    );

class _WaveRandom implements Random {
  int calls = 0;
  @override
  int nextInt(int max) {
    expect(max, 26);
    return calls++ % 2 == 0 ? 0 : max - 1;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  testWidgets(
      'robot greets on opening, then waits a fresh random delay between waves',
      (tester) async {
    final random = _WaveRandom();
    await tester
        .runAsync(() => rootBundle.load('assets/branding/meal_robot_wave.gif'));
    await tester.pumpWidget(greeting(active: true, random: random));
    await advanceGif(tester, 10);
    expect(find.byKey(const ValueKey('meal-robot-wave')), findsOneWidget);
    final startupPainting = find.descendant(
        of: find.byKey(const ValueKey('meal-robot-wave')),
        matching: find.byType(CustomPaint));
    final startupPainter = tester.widget<CustomPaint>(startupPainting).painter!;
    await advanceGif(tester, 10);
    expect(
        tester
            .widget<CustomPaint>(startupPainting)
            .painter!
            .shouldRepaint(startupPainter),
        isTrue);
    await advanceGif(tester, 110);
    final robot = find.byKey(const ValueKey('meal-robot-wave'));
    expect(robot, findsOneWidget);
    final painting =
        find.descendant(of: robot, matching: find.byType(CustomPaint));
    final frozenPainter = tester.widget<CustomPaint>(painting).painter!;

    expect(random.calls, 1);
    await tester.pumpWidget(greeting(active: true, random: random));
    await advanceGif(tester, 10);
    expect(robot, findsOneWidget);
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(frozenPainter),
        isFalse);

    await tester.pump(const Duration(seconds: 10));
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(frozenPainter),
        isFalse);
    await tester.pump(const Duration(seconds: 20));
    await advanceGif(tester, 10);
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(frozenPainter),
        isTrue);
    await advanceGif(tester, 110);
    expect(random.calls, 2);
    final restingPainter = tester.widget<CustomPaint>(painting).painter!;
    await advanceGif(tester, 10);
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(restingPainter),
        isFalse);

    await tester.pump(const Duration(seconds: 25));
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(restingPainter),
        isFalse);
    await tester.pump(const Duration(seconds: 21));
    await advanceGif(tester, 10);
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(restingPainter),
        isTrue);

    await tester.pumpWidget(greeting(active: false));
    await tester.pumpWidget(greeting(active: true));
    await advanceGif(tester, 10);
    expect(find.byKey(const ValueKey('meal-robot-wave')), findsOneWidget);
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(frozenPainter),
        isTrue);
    await tester.pumpWidget(greeting(active: false));
    expect(find.byKey(const ValueKey('meal-robot-wave')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await advanceGif(tester, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('robot greets again when the app returns from the background',
      (tester) async {
    await tester.pumpWidget(greeting(active: true));
    await advanceGif(tester, 110);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // Flutter does not draw new widget frames while the app is paused.
    await tester.pump(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await advanceGif(tester, 10);
    final painting = find.descendant(
        of: find.byKey(const ValueKey('meal-robot-wave')),
        matching: find.byType(CustomPaint));
    final firstPainter = tester.widget<CustomPaint>(painting).painter!;
    await advanceGif(tester, 10);
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(firstPainter),
        isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await advanceGif(tester, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('robot stays still with reduced motion and pauses behind routes',
      (tester) async {
    await tester.pumpWidget(greeting(active: true, reduceMotion: true));
    await advanceGif(tester, 5);
    final robot = find.byKey(const ValueKey('meal-robot-wave'));
    expect(robot, findsOneWidget);
    final painting =
        find.descendant(of: robot, matching: find.byType(CustomPaint));
    final stillPainter = tester.widget<CustomPaint>(painting).painter!;
    await tester.pump(const Duration(minutes: 6));
    await advanceGif(tester, 10);
    expect(
        tester
            .widget<CustomPaint>(painting)
            .painter!
            .shouldRepaint(stillPainter),
        isFalse);
    await tester.pumpWidget(greeting(active: true));
    await advanceGif(tester, 10);
    expect(find.byKey(const ValueKey('meal-robot-wave')), findsOneWidget);
    await tester.pumpWidget(greeting(active: true, visible: false));
    expect(find.byKey(const ValueKey('meal-robot-wave')), findsNothing);
    await tester.pumpWidget(greeting(active: true, visible: true));
    await advanceGif(tester, 10);
    expect(find.byKey(const ValueKey('meal-robot-wave')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await advanceGif(tester, 2);
    expect(tester.takeException(), isNull);
  });
}
