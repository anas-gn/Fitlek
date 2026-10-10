import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitlek1/screens/ENG/clientForgot.dart';

void main() {
  testWidgets(
      'reset screen requires verified proof and carries it to the password update',
      (tester) async {
    tester.view.physicalSize = const Size(396, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var verifies = 0;
    Map<String, dynamic>? submitted;
    final token = 'a' * 64;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/verify-forgot-otp')) {
        verifies++;
        return http.Response(
            jsonEncode(
                {'verified': true, if (verifies > 1) 'resetToken': token}),
            200);
      }
      if (request.url.path.endsWith('/reset-password-otp')) {
        submitted = jsonDecode(request.body) as Map<String, dynamic>;
      }
      return http.Response('{"message":"Fixture success"}', 200);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: ClientForgotScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField).first, 'fixture@example.invalid');
      await tester.tap(find.text('SEND CODE'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(find.text('VERIFY CODE'));
      await tester.pumpAndSettle();
      expect(find.text('RESET PASSWORD'), findsNothing);
      expect(find.text('VERIFY CODE'), findsOneWidget);
      await tester.tap(find.text('VERIFY CODE'));
      await tester.pumpAndSettle();
      expect(find.text('RESET PASSWORD'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'ValidPassword123');
      await tester.enterText(find.byType(TextField).last, 'ValidPassword123');
      await tester.ensureVisible(find.text('RESET PASSWORD'));
      await tester.tap(find.text('RESET PASSWORD'));
      await tester.pumpAndSettle();
      expect(submitted?['resetToken'], token);
      expect(submitted?['email'], 'fixture@example.invalid');
      expect(submitted?['newPassword'], 'ValidPassword123');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }, () => client);
  });
}
