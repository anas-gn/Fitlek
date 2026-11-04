import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/account_password_sheet.dart';
import 'package:fitlek1/components/app_version_checker.dart';
import 'package:fitlek1/services/app_version_policy.dart';
import 'package:fitlek1/services/campaign_service.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  for (final variant in [
    'announcement-light',
    'announcement-dark',
    'password-light',
    'required-update-light',
    'required-update-dark'
  ]) {
    testWidgets('popup visual preview $variant', (tester) async {
      final fontFolder = Platform.environment['POPUP_PREVIEW_FONT_DIR'];
      if (fontFolder != null) {
        await tester.runAsync(() async {
          for (final font in {
            'Roboto': 'Roboto/Roboto-Regular.ttf',
            'Ahem': 'Roboto/Roboto-Regular.ttf',
            'MaterialIcons': 'MaterialIcons-Regular.otf'
          }.entries) {
            final bytes = await File('$fontFolder/${font.value}').readAsBytes();
            await (FontLoader(font.key)
                  ..addFont(Future.value(ByteData.sublistView(bytes))))
                .load();
          }
        });
      }
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final boundary = GlobalKey();
      final theme = variant.endsWith('dark') ? AppTheme.dark : AppTheme.light;
      final previewTheme = theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
            style: theme.filledButtonTheme.style!.copyWith(
                textStyle: const WidgetStatePropertyAll(TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.w800)))),
        textButtonTheme: TextButtonThemeData(
            style: theme.textButtonTheme.style!.copyWith(
                textStyle: const WidgetStatePropertyAll(TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w700)))),
      );
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: previewTheme,
              builder: variant.startsWith('required-update')
                  ? (_, child) => AppVersionChecker(
                      child: child!,
                      load: () async => const AppVersionCheck(
                          installedVersion: '1.0.0',
                          policy: AppVersionPolicy(
                              latestVersion: '2.0.0',
                              minimumVersion: '2.0.0',
                              storeUrl: 'https://example.test/store')),
                      openStore: (_) async => true)
                  : null,
              home: Builder(
                  builder: (context) => Scaffold(
                      body: Center(
                          child: TextButton(
                              child: const Text('Open'),
                              onPressed: () {
                                if (variant.startsWith('password')) {
                                  showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) =>
                                          const AccountPasswordSheet(
                                              token: 'preview'));
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (_) =>
                                          const CampaignDialog(item: {
                                            'title':
                                                'Your next chapter starts here',
                                            'body':
                                                'Meet coaches who understand your goals. Find your fit, book your first session, and build a routine you’ll love.',
                                            'buttonLabel': 'Explore coaches',
                                            'destination': '/explore',
                                          }));
                                }
                              })))))));
      if (!variant.startsWith('required-update'))
        await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final folder = Platform.environment['POPUP_PREVIEW_DIR'];
      if (folder != null) {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(folder).create(recursive: true);
          await File('$folder/$variant.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
