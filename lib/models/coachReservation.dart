enum ReservationStatus { pending, confirmed }

class CoachReservation {
  final String id;
  final String clientName;
  final String clientPhotoUrl;
  final DateTime date;
  final String time;
  ReservationStatus status;
  String? rejectionReason;
  String? cancellationReason;

  CoachReservation({
    required this.id,
    required this.clientName,
    required this.clientPhotoUrl,
    required this.date,
    required this.time,
    required this.status,
    this.rejectionReason,
    this.cancellationReason,
  });

  bool get canCancel =>
      status == ReservationStatus.confirmed &&
      date.difference(DateTime.now()).inDays > 3;
}
