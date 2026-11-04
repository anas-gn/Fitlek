import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/models/coachReservation.dart';
import 'package:fitlek1/services/session_location.dart';

void main() {
  test('legacy company address is not presented as the selected session venue',
      () {
    final reservation = CoachReservation(
        id: '87',
        clientName: 'Client',
        clientPhotoUrl: '',
        date: DateTime(2026, 10, 16),
        time: '13:00',
        location: 'HAY EL AMAL 2 RUE 68',
        companyName: 'Old partner',
        status: ReservationStatus.confirmed);
    expect(reservation.locationLabel, contains('arranged with coach'));
    expect(sessionLocationLabel(location: 'Atlas Gym · Main street'),
        'Atlas Gym · Main street');
    expect(sessionLocationLabel(location: 'home'), contains('Home visit'));
  });
}
