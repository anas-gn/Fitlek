import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/client_profile_overview.dart';
import 'package:fitlek1/components/profile_completed_badge.dart';
import 'package:fitlek1/models/client_profile_completion.dart';
import 'package:fitlek1/theme/app_theme.dart';

void main() {
  final saved = <String, dynamic>{
    'avatarUrl': 'https://example.test/photo.jpg',
    'firstName': 'Amal',
    'lastName': 'Client',
    'email': 'amal@example.test',
    'phoneNumber': '+212612345678',
    'ville': 'El Jadida',
    'height': 172,
    'interests': ['Yoga'],
  };
  for (final dark in [true, false]) {
    testWidgets('completed profile shows a label without progress, dark=$dark',
        (tester) async {
      Widget page(Map<String, dynamic> data) => MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
              body: ClientProfileCompletionCard(
                  completion: ClientProfileCompletion(data),
                  onComplete: (_) {})));
      await tester.pumpWidget(page(saved));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileCompletedBadge), findsOneWidget);
      expect(find.text('Profile completed'), findsOneWidget);
      expect(find.text('100%'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pumpWidget(page({...saved, 'phoneNumber': ''}));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileCompletedBadge), findsNothing);
      expect(find.text('Add your phone number'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
