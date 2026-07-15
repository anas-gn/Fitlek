enum ReservationStatus { pending, confirmed }

class CoachReservation {
  final String id;
  final String clientName;
  final String clientPhotoUrl;
  final DateTime date;
  final String time;
  final String? location;
  ReservationStatus status;
  String? rejectionReason;
  String? cancellationReason;

  CoachReservation({
    required this.id,
    required this.clientName,
    required this.clientPhotoUrl,
    required this.date,
    required this.time,
    this.location,
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
    switch (location) {
      case 'home':
        return "Client's home";
      case 'gym':
        return 'Coach\'s gym';
      case null:
      case '':
        return 'To be defined';
      default:
        return location!;
    }
  }
}
