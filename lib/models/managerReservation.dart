enum ManagerReservationStatus { pending, confirmed, cancelled }

class ManagerReservation {
  final String id;
  final String clientId;
  final String clientName;
  final String clientAvatarUrl;
  final String coachId;
  final String coachName;
  final String coachAvatarUrl;
  final DateTime date;
  final String time;
  ManagerReservationStatus status;

  ManagerReservation({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientAvatarUrl,
    required this.coachId,
    required this.coachName,
    required this.coachAvatarUrl,
    required this.date,
    required this.time,
    required this.status,
  });

  String get statusLabel {
    switch (status) {
      case ManagerReservationStatus.pending:
        return 'Pending';
      case ManagerReservationStatus.confirmed:
        return 'Confirmed';
      case ManagerReservationStatus.cancelled:
        return 'Cancelled';
    }
  }
}
