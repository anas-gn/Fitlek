// ─────────────────────────────────────────────
//  reservation.dart
//  Modèle pur — aucune dépendance Flutter/UI
// ─────────────────────────────────────────────

class ReservationModel {
  final int    id;
  final int    clientID;
  final int    coachID;
  final String coachName;
  final String coachSpeciality;
  final String coachImageUrl;
  final double coachRating;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final String location;
  final String status;           // 'pending' | 'confirmed' | 'cancelled'
  final double price;
  final String companyName;
  final int?    reviewRating;
  final String? reviewComment;
  final String? rejectionReason;
  final String? cancellationReason;

  const ReservationModel({
    required this.id,
    required this.clientID,
    required this.coachID,
    required this.coachName,
    required this.coachSpeciality,
    required this.coachImageUrl,
    required this.coachRating,
    required this.sessionStart,
    required this.sessionEnd,
    required this.location,
    required this.status,
    required this.price,
    required this.companyName,
    this.reviewRating,
    this.reviewComment,
    this.rejectionReason,
    this.cancellationReason,
  });

  // ── Computed helpers ──────────────────────────────────────────────

  bool get isPending   => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming  => status == 'pending' || status == 'confirmed';
  bool get isPast      =>
      status == 'cancelled' ||
      (isConfirmed && sessionStart.isBefore(DateTime.now()));
  bool get needsReview =>
      isConfirmed &&
      sessionStart.isBefore(DateTime.now()) &&
      reviewRating == null;

  int get durationMin => sessionEnd.difference(sessionStart).inMinutes;

  // ── Safe numeric parser ───────────────────────────────────────────
  //
  // MySQL renvoie parfois des champs DECIMAL/FLOAT sous forme de String
  // (ex: "50.00", "4.5").  Cette méthode gère les deux cas.
  static double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int)  return v;
    if (v is num)  return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  // ── Deserialize from backend JSON ─────────────────────────────────
  factory ReservationModel.fromJson(Map<String, dynamic> j) {
    // Parse reservedDate (DATE) + reservedTime (TIME) → DateTime
    final dateStr   = j['reservedDate'] as String;   // "2026-06-04"
    final timeStr   = j['reservedTime'] as String;   // "10:00:00"
    final timeParts = timeStr.split(':');
    final date      = DateTime.parse(dateStr);
    final start     = DateTime(
      date.year, date.month, date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    final end = start.add(const Duration(hours: 1));

    final status = j['status'] as String? ?? 'pending';

    return ReservationModel(
      id:                _toInt(j['id']),
      clientID:          _toInt(j['clientID']),
      coachID:           _toInt(j['coachID']),
      coachName:         j['coachName']      as String? ?? '',
      coachSpeciality:   j['coachSpeciality'] as String?
                         ?? j['speciality']  as String? ?? '',
      coachImageUrl:     j['coachAvatar']    as String? ?? '',
      coachRating:       _toDouble(j['coachRating']),   // ← fix "4.5" String
      sessionStart:      start,
      sessionEnd:        end,
      location:          j['location']       as String? ?? '',
      status:            status,
      price:             _toDouble(j['price']),          // ← fix "50.00" String
      companyName:       j['companyName']    as String? ?? '',
      reviewRating:      j['reviewRating']   != null
                             ? _toInt(j['reviewRating'])
                             : null,
      reviewComment:     j['reviewComment']  as String?,
      rejectionReason:   j['rejectionReason'] as String?,
      cancellationReason: j['cancellationReason'] as String?,
    );
  }

  // ── Serialize (pour POST /reservations) ───────────────────────────
  Map<String, dynamic> toRequestJson() => {
    'coachID':      coachID,
    'reservedDate': '${sessionStart.year}-'
                    '${sessionStart.month.toString().padLeft(2, '0')}-'
                    '${sessionStart.day.toString().padLeft(2, '0')}',
    'reservedTime': '${sessionStart.hour.toString().padLeft(2, '0')}:'
                    '${sessionStart.minute.toString().padLeft(2, '0')}:00',
  };

  // ── CopyWith ──────────────────────────────────────────────────────
  ReservationModel copyWith({
    String? status,
    int?    reviewRating,
    String? reviewComment,
    String? cancellationReason,
  }) => ReservationModel(
    id:                id,
    clientID:          clientID,
    coachID:           coachID,
    coachName:         coachName,
    coachSpeciality:   coachSpeciality,
    coachImageUrl:     coachImageUrl,
    coachRating:       coachRating,
    sessionStart:      sessionStart,
    sessionEnd:        sessionEnd,
    location:          location,
    status:            status ?? this.status,
    price:             price,
    companyName:       companyName,
    reviewRating:      reviewRating      ?? this.reviewRating,
    reviewComment:     reviewComment     ?? this.reviewComment,
    rejectionReason:   rejectionReason,
    cancellationReason: cancellationReason ?? this.cancellationReason,
  );
}