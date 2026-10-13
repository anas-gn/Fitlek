import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/components/ENG/announcementCarousel.dart';
import 'package:fitlek1/theme/fitlek_theme_extension.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> mount(WidgetTester tester, List<Map<String, dynamic>> items,
      {GlobalKey<AnnouncementCarouselState>? key,
      bool Function(String)? onDestination}) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [FitlekColors.dark]),
      home: Scaffold(
          body: AnnouncementCarousel(
              key: key,
              clientID: 1,
              token: 'test',
              onExplore: () {},
              onDestination: onDestination,
              client: MockClient(
                  (_) async => http.Response(jsonEncode(items), 200)))),
    ));
    await tester.pumpAndSettle();
  }

  final items = List.generate(
      4,
      (i) => <String, dynamic>{
            'id': i + 1,
            'title':
                'Announcement ${i + 1} with a long title that wraps safely',
            'content': 'Short description of the latest news at Sirvya',
            'link': '/explore'
          });
  testWidgets('button dispatches configured app destination', (tester) async {
    String? opened;
    await mount(tester, [
      {...items.first, 'link': '/sessions', 'buttonLabel': 'My bookings'}
    ], onDestination: (link) {
      opened = link;
      return true;
    });
    await tester.tap(find.text('My bookings'));
    expect(opened, '/sessions');
    expect(find.text('Close'), findsNothing);
  });
  testWidgets('custom button text is displayed', (tester) async {
    await mount(tester, [
      {...items.first, 'buttonLabel': 'Choose my coach'}
    ]);
    expect(find.text('Choose my coach'), findsOneWidget);
    expect(find.text('Explore coaches'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty feed leaves no announcement section', (tester) async {
    await mount(tester, []);
    expect(find.text('What’s new at Sirvya'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('maximum three banners fit phone width and only move manually',
      (tester) async {
    await mount(tester, items);
    final pager = tester.widget<PageView>(find.byType(PageView));
    expect(pager.childrenDelegate.estimatedChildCount, 3);
    expect(pager.controller!.page, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(pager.controller!.page, 0);
    await tester.drag(find.byType(PageView), const Offset(-280, 0));
    await tester.pumpAndSettle();
    expect(pager.controller!.page, closeTo(1, 0.01));
    expect(tester.takeException(), isNull);
  });
  testWidgets('dismissal survives refresh and a new announcement can appear',
      (tester) async {
    final key = GlobalKey<AnnouncementCarouselState>();
    final feed = items.take(3).toList();
    await mount(tester, feed, key: key);
    await tester.tap(find.byTooltip('Dismiss announcements'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => key.currentState!.refresh());
    await tester.pumpAndSettle();
    expect(find.text('What’s new at Sirvya'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('dismissed_announcements_1'),
        containsAll(['1', '2', '3']));
    feed.add(items.last);
    await tester.runAsync(() => key.currentState!.refresh());
    await tester.pumpAndSettle();
    expect(find.text('What’s new at Sirvya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
