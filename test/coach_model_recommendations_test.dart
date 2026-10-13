import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/models/anas/coach.dart';

void main() {
  test('location labels format approximate distance and handle missing GPS', () {
    expect(CoachModel.fromJson({'id': 1, 'ville': 'El Jadida', 'distanceKm': '1.24'}).locationLabel,
        'El Jadida · ≈ 1.2 km');
    expect(CoachModel.fromJson({'id': 1, 'ville': 'El Jadida', 'distanceKm': 0}).locationLabel,
        'El Jadida · ≈ <0.1 km');
    expect(CoachModel.fromJson({'id': 1, 'ville': 'El Jadida'}).locationLabel, 'El Jadida');
  });
  test('recommendations accept database decimal ratings and numeric counts', () {
    final coach = CoachModel.fromJson({
      'id': 12,
      'rating': '4.8000',
      'reviewCount': '20',
      'minPrice': '250.00',
      'earnedPoints': '10',
      'isApproved': 1,
    });
    expect(coach.rating, 4.8);
    expect(coach.reviewCount, 20);
    expect(coach.minPrice, 250);
    expect(coach.earnedPoints, 10);
    expect(coach.isApproved, isTrue);
  });

  test('numeric ratings and unrated coaches remain supported', () {
    expect(CoachModel.fromJson({'id': 1, 'rating': 4.5}).rating, 4.5);
    expect(CoachModel.fromJson({'id': 2}).rating, isNull);
    expect(CoachModel.fromJson({'id': 3, 'rating': 'invalid'}).rating, isNull);
  });
}
