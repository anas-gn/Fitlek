import 'package:fitlek1/theme/fitlek_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlek1/models/anas/review.dart';
import 'package:fitlek1/screens/ENG/clientCoachReviews.dart';

void main() {
  testWidgets('Coach feedback shows client comments', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(theme: ThemeData(extensions: const [FitlekColors.dark]), home: ClientCoachReviewsScreen(
      coachID: 7, coachName: 'Coach', clientID: 0, token: '', coachView: true,
      initialAvgRating: 4, initialTotalReviews: 1,
      initialReviews: [ReviewItem(id: 1, coachID: 7, clientID: 9, rating: 4,
        clientName: 'Client', comment: 'Helpful session', createdAt: DateTime(2026, 10, 11))],
    )));
    expect(find.text('My feedback'), findsOneWidget);
    await tester.ensureVisible(find.text('Helpful session'));
    expect(find.text('Helpful session'), findsOneWidget);
    expect(find.text('My review'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}


