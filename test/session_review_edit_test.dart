import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitlek1/screens/ENG/clientSessions.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  testWidgets(
      'existing coach review is editable and updates every session card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var rating = 4;
    var comment = 'Helpful coach';
    var writes = 0;
    Map<String, dynamic> session(int id) => {
          'id': id,
          'clientID': 8,
          'coachID': 7,
          'coachName': 'Test Coach',
          'reservedDate': '2020-10-15',
          'reservedTime': id == 1 ? '10:00:00' : '14:00:00',
          'status': 'confirmed',
          'price': '250.00',
          'location': '',
          'reviewRating': rating,
          'reviewComment': comment,
        };
    final client = MockClient((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/reviews')) {
        final body = jsonDecode(request.body);
        rating = body['rating'];
        comment = body['comment'] ?? '';
        writes++;
        return http.Response('{}', 201);
      }
      if (request.url.path.endsWith('/details')) {
        return http.Response(jsonEncode(session(1)), 200);
      }
      if (request.url.path.contains('/reviews/coach/')) {
        return http.Response('{"avg":4,"total":1}', 200);
      }
      return http.Response(jsonEncode([session(1), session(2)]), 200);
    });
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: SessionsScreen(clientID: 8, token: 'test', httpClient: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Past (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Edit review: 4/5 '), findsNWidgets(2));
    await tester.tap(find.text('Edit review: 4/5 ').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit my review'));
    await tester.tap(find.text('Edit my review'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Helpful coach');
    await tester.ensureVisible(find.byIcon(Icons.star_outline_rounded).last);
    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await tester.enterText(find.byType(TextField), 'Even better this time');
    await tester.ensureVisible(find.text('UPDATE MY REVIEW'));
    await tester.tap(find.text('UPDATE MY REVIEW'));
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(rating, 5);
    expect(comment, 'Even better this time');
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Edit review: 5/5 '), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
