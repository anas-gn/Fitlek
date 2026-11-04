import '../services/session_location.dart';

enum ReservationStatus { pending, confirmed, cancelled }

class CoachReservation {
  final String id;
  final String pricingStatus;
  final double? proposedPrice;
  final double? price;
  final int duration;
  final String? packageName;
  final String clientName;
  final String clientPhotoUrl;
  final DateTime date;
  final String time;
  final String? location;
  final String? companyName;
  ReservationStatus status;
  String? rejectionReason;
  String? cancellationReason;

  CoachReservation({
    required this.id,
    this.pricingStatus = 'fixed',
    this.proposedPrice,
    this.price,
    this.duration = 60,
    this.packageName,
    required this.clientName,
    required this.clientPhotoUrl,
    required this.date,
    required this.time,
    this.location,
    this.companyName,
    required this.status,
    this.rejectionReason,
    this.cancellationReason,
  });

  bool get canCancel =>
      status == ReservationStatus.confirmed &&
      date.difference(DateTime.now()).inDays > 3;

  /// Human-friendly label for the location value stored at booking time.
  /// The client sends 'home', 'gym', or 'To be defined'.
  String get locationLabel {
    return sessionLocationLabel(location: location, companyName: companyName);
  }
}
