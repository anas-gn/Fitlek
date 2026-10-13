import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitlek1/screens/ENG/clientCoachFavorites.dart';
import 'package:fitlek1/theme/fitlek_theme_extension.dart';

void main() {
  testWidgets(
      'favorites render, hover, filter and remove without layout errors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = MockClient((request) async {
      if (request.method == 'POST')
        return http.Response('{"favorited":false}', 200);
      if (request.url.path.contains('/reviews/'))
        return http.Response('{"avg":4.3,"total":4}', 200);
      return http.Response(
          jsonEncode([
            {
              'id': 1,
              'firstName': 'A coach with a very long first name',
              'lastName': 'Long surname',
              'ville': 'Casablanca',
              'specialties': ['Yoga', 'Strength'],
              'isApproved': 1
            },
            {
              'id': 2,
              'firstName': 'Yasmin',
              'lastName': 'Bennani',
              'ville': 'Marrakech',
              'isApproved': 0
            },
          ]),
          200);
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [FitlekColors.dark]),
      home:
          ClientCoachFavoriteScreen(clientID: 1, token: 'test', client: client),
    ));
    await tester.pumpAndSettle();
    expect(find.text('VIEW PROFILE'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(180, 220));
    await tester.pump();
    await mouse.moveTo(const Offset(240, 310));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Yasmin');
    await tester.pumpAndSettle();
    expect(find.text('VIEW PROFILE'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('No coach matches your search'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
    await tester.pumpAndSettle();
  });
}
