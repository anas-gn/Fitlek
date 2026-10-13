import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/services/booking_policy.dart';
import 'package:fitlek1/models/anas/reservation.dart';

void main() {
  test('at 19:00, 20:00 is unavailable but 20:01 is bookable', () {
    final now = DateTime(2026, 10, 12, 19);
    expect(hasBookingLeadTime(DateTime(2026, 10, 12, 20), now: now), isFalse);
    expect(hasBookingLeadTime(DateTime(2026, 10, 12, 20, 1), now: now), isTrue);
    expect(hasBookingLeadTime(DateTime(2026, 10, 12, 18), now: now), isFalse);
  });
  ReservationModel booking(Duration lead,
      {String status = 'pending', String pricing = 'fixed', String? reason}) {
    final start = DateTime.now().add(lead);
    return ReservationModel(
        id: 1,
        clientID: 2,
        coachID: 3,
        coachName: 'Coach',
        coachSpeciality: '',
        coachImageUrl: '',
        coachRating: 0,
        sessionStart: start,
        sessionEnd: start.add(const Duration(hours: 1)),
        location: 'Home visit',
        status: status,
        price: 250,
        companyName: '',
        pricingStatus: pricing,
        cancellationReason: reason);
  }

  test(
      'unapproved bookings expire an hour ahead; confirmed sessions stay valid',
      () {
    final pending = booking(const Duration(minutes: 59));
    expect(pending.approvalExpired, isTrue);
    expect(pending.isUpcoming, isFalse);
    expect(pending.isPast, isTrue);
    expect(booking(const Duration(minutes: 61)).isExpired, isFalse);
    expect(booking(const Duration(minutes: 30), status: 'confirmed').isExpired,
        isFalse);
  });
  test('coach expiry is distinct from the two-hour pricing deadline', () {
    final priceRequest =
        booking(const Duration(minutes: 90), pricing: 'proposed');
    expect(priceRequest.priceExpired, isTrue);
    expect(priceRequest.approvalExpired, isFalse);
    final expired = booking(const Duration(minutes: 30),
        status: 'cancelled',
        pricing: 'expired',
        reason: 'Coach did not approve at least one hour before the session');
    expect(expired.approvalExpired, isTrue);
    expect(expired.priceExpired, isFalse);
    expect(expired.isExpired, isTrue);
  });
}
