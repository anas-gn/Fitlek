import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/app_version_checker.dart';
import 'package:fitlek1/components/app_update_prompt.dart';
import 'package:fitlek1/services/app_version_policy.dart';
import 'package:fitlek1/theme/app_theme.dart';

const requiredCheck = AppVersionCheck(
    installedVersion: '1.0.0',
    policy: AppVersionPolicy(
        latestVersion: '2.0.0',
        minimumVersion: '2.0.0',
        storeUrl:
            'https://play.google.com/store/apps/details?id=com.sirvya.app'));

Widget harness(
        {required GlobalKey<NavigatorState> navigator,
        required Future<AppVersionCheck?> Function() load,
        Future<bool> Function(Uri)? openStore,
        bool showPrompts = true,
        VoidCallback? useApp}) =>
    MaterialApp(
      theme: AppTheme.light,
      navigatorKey: navigator,
      builder: (_, child) => AppVersionChecker(
          navigatorKey: navigator,
          showPrompts: showPrompts,
          load: load,
          openStore: openStore ?? (_) async => true,
          child: child!),
      home: Scaffold(
          body: Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                  onPressed: useApp ?? () {}, child: const Text('Use app')))),
    );

void main() {
  testWidgets('slow version checks leave the app visible and usable',
      (tester) async {
    final pending = Completer<AppVersionCheck?>();
    var actions = 0;
    await tester.pumpWidget(harness(
        navigator: GlobalKey<NavigatorState>(),
        load: () => pending.future,
        useApp: () => actions++));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Checking app version…'), findsNothing);
    await tester.tap(find.text('Use app'));
    expect(actions, 1);
    pending.complete(null);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });

  for (final mandatory in [true, false]) {
    testWidgets('update prompt waits for intro completion, required=$mandatory',
        (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      Future<AppVersionCheck?> load() async => mandatory
          ? requiredCheck
          : const AppVersionCheck(
              installedVersion: '1.0.0',
              policy: AppVersionPolicy(
                  latestVersion: '2.0.0',
                  minimumVersion: '1.0.0',
                  storeUrl: 'https://example.test/store'));
      await tester.pumpWidget(
          harness(navigator: navigator, load: load, showPrompts: false));
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdatePrompt), findsNothing);
      await tester.pumpWidget(
          harness(navigator: navigator, load: load, showPrompts: true));
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdatePrompt), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('compatible version stays unobstructed after intro completion',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    Future<AppVersionCheck?> load() async => AppVersionCheck(
        installedVersion: '2.0.0', policy: requiredCheck.policy);
    await tester.pumpWidget(
        harness(navigator: navigator, load: load, showPrompts: false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
        harness(navigator: navigator, load: load, showPrompts: true));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdatePrompt), findsNothing);
    expect(find.text('Use app').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'required update survives route replacement, outside taps and back',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    var actions = 0;
    await tester.pumpWidget(harness(
        navigator: navigator,
        load: () async => requiredCheck,
        useApp: () => actions++));
    await tester.pumpAndSettle();
    expect(find.text('Update Sirvya to continue'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    await tester.tap(find.text('Use app'), warnIfMissed: false);
    expect(actions, 0);
    navigator.currentState!.pushReplacement(MaterialPageRoute(
        builder: (_) => Scaffold(
            body: Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                    onPressed: () => actions++,
                    child: const Text('Private action'))))));
    await tester.pumpAndSettle();
    expect(find.text('Update Sirvya to continue'), findsOneWidget);
    await tester.tap(find.text('Private action'), warnIfMissed: false);
    await tester.tapAt(const Offset(5, 5));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Update Sirvya to continue'), findsOneWidget);
    expect(actions, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'store failure, resume and failed rechecks never unlock a required update',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    var checks = 0;
    await tester.pumpWidget(harness(
        navigator: navigator,
        load: () async {
          checks++;
          if (checks > 1) throw StateError('Offline');
          return requiredCheck;
        },
        openStore: (_) async => false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not open the store'), findsOneWidget);
    await tester.ensureVisible(find.text('Check again'));
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(checks, greaterThanOrEqualTo(3));
    expect(find.text('Update Sirvya to continue'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('a compatible installed version unlocks the gate',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    var updated = false;
    await tester.pumpWidget(harness(
        navigator: navigator,
        load: () async => updated
            ? AppVersionCheck(
                installedVersion: '2.0.0', policy: requiredCheck.policy)
            : requiredCheck));
    await tester.pumpAndSettle();
    updated = true;
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdatePrompt), findsNothing);
    expect(find.text('Use app').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'placeholder iOS store link shows a configuration error and stays blocked',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    var opens = 0;
    await tester.pumpWidget(harness(
        navigator: navigator,
        load: () async => const AppVersionCheck(
            installedVersion: '1.0.0',
            policy: AppVersionPolicy(
                latestVersion: '2.0.0',
                minimumVersion: '2.0.0',
                storeUrl: 'https://apps.apple.com/app/idYOUR_APP_ID')),
        openStore: (_) async {
          opens++;
          return true;
        }));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(opens, 0);
    expect(
        find.textContaining('update link is not configured'), findsOneWidget);
    expect(find.text('Update Sirvya to continue'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('optional updates can be dismissed and app remains usable',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    var actions = 0;
    await tester.pumpWidget(harness(
        navigator: navigator,
        load: () async => const AppVersionCheck(
            installedVersion: '1.0.0',
            policy: AppVersionPolicy(
                latestVersion: '2.0.0',
                minimumVersion: '1.0.0',
                storeUrl: 'https://example.test/store')),
        useApp: () => actions++));
    await tester.pumpAndSettle();
    expect(find.text('A fresh version of Sirvya'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use app'));
    expect(actions, 1);
    await tester.pumpWidget(const SizedBox());
  });
  for (final dark in [false, true]) {
    testWidgets('required prompt fits small screens and large text, dark=$dark',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (_, child) => MediaQuery(
              data: const MediaQueryData(
                  size: Size(320, 568),
                  textScaler: TextScaler.linear(1.5)),
              child: AppVersionChecker(
                  child: child!,
                  load: () async => requiredCheck,
                  openStore: (_) async => false)),
          home: const Scaffold()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Update now'));
      await tester.tap(find.text('Update now'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not open the store'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
