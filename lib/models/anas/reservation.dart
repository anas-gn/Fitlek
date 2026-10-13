// ─────────────────────────────────────────────
//  reservation.dart
//  Modèle pur — aucune dépendance Flutter/UI
// ─────────────────────────────────────────────

import '../../services/booking_policy.dart';

class ReservationModel {
  final int id;
  final int clientID;
  final int coachID;
  final String coachName;
  final String coachSpeciality;
  final String coachImageUrl;
  final double coachRating;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final String location;
  final String pricingStatus;
  final double? proposedPrice;
  final int quoteVersion;
  bool get priceExpired =>
      (pricingStatus == 'expired' && !approvalExpired) ||
      (isPending &&
          ['awaiting', 'proposed'].contains(pricingStatus) &&
          !DateTime.now()
              .isBefore(sessionStart.subtract(const Duration(hours: 2))));
  DateTime get priceDeadline => sessionStart.subtract(const Duration(hours: 2));
  bool get approvalExpired =>
      (pricingStatus == 'expired' &&
          cancellationReason ==
              'Coach did not approve at least one hour before the session') ||
      (isPending &&
          pricingStatus == 'fixed' &&
          !hasBookingLeadTime(sessionStart));
  bool get isExpired =>
      pricingStatus == 'expired' || priceExpired || approvalExpired;
  final String status; // 'pending' | 'confirmed' | 'cancelled'
  final double price;
  final String companyName;
  final int? reviewRating;
  final String? reviewComment;
  final String? rejectionReason;
  final String? cancellationReason;
  final int? packageID;
  final String? packageName;

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
    this.pricingStatus = 'fixed',
    this.proposedPrice,
    this.quoteVersion = 0,
    required this.status,
    required this.price,
    required this.companyName,
    this.reviewRating,
    this.reviewComment,
    this.rejectionReason,
    this.cancellationReason,
    this.packageID,
    this.packageName,
  });

  // ── Computed helpers ──────────────────────────────────────────────

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming =>
      (status == 'pending' || status == 'confirmed') && !isExpired;
  bool get isPast =>
      isExpired ||
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
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  // ── Deserialize from backend JSON ─────────────────────────────────
  factory ReservationModel.fromJson(Map<String, dynamic> j) {
    // Parse reservedDate (DATE) + reservedTime (TIME) → DateTime
    final dateStr = j['reservedDate'] as String; // "2026-06-04"
    final timeStr = j['reservedTime'] as String; // "10:00:00"
    final timeParts = timeStr.split(':');
    final date = DateTime.parse(dateStr);
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    final end = start.add(const Duration(hours: 1));

    final status = j['status'] as String? ?? 'pending';

    return ReservationModel(
      id: _toInt(j['id']),
      clientID: _toInt(j['clientID']),
      coachID: _toInt(j['coachID']),
      coachName: j['coachName'] as String? ?? '',
      coachSpeciality:
          j['coachSpeciality'] as String? ?? j['speciality'] as String? ?? '',
      coachImageUrl: j['coachAvatar'] as String? ?? '',
      coachRating: _toDouble(j['coachRating']), // ← fix "4.5" String
      sessionStart: start,
      sessionEnd: end,
      pricingStatus: j['pricingStatus']?.toString() ?? 'fixed',
      proposedPrice:
          j['proposedPrice'] == null ? null : _toDouble(j['proposedPrice']),
      quoteVersion: _toInt(j['quoteVersion']),
      location: (j['companyName']?.toString().trim().isNotEmpty ?? false)
          ? 'Location to be arranged with coach in messages'
          : j['location'] as String? ??
              'Location to be arranged with coach in messages',
      status: status,
      price: _toDouble(j['price']), // ← fix "50.00" String
      companyName: j['companyName'] as String? ?? '',
      reviewRating:
          j['reviewRating'] != null ? _toInt(j['reviewRating']) : null,
      reviewComment: j['reviewComment'] as String?,
      rejectionReason: j['rejectionReason'] as String?,
      cancellationReason: j['cancellationReason'] as String?,
      packageID: j['packageID'] != null ? _toInt(j['packageID']) : null,
      packageName: j['packageName'] as String?,
    );
  }

  // ── Serialize (pour POST /reservations) ───────────────────────────
  Map<String, dynamic> toRequestJson() => {
        'coachID': coachID,
        'reservedDate': '${sessionStart.year}-'
            '${sessionStart.month.toString().padLeft(2, '0')}-'
            '${sessionStart.day.toString().padLeft(2, '0')}',
        'reservedTime': '${sessionStart.hour.toString().padLeft(2, '0')}:'
            '${sessionStart.minute.toString().padLeft(2, '0')}:00',
      };

  // ── CopyWith ──────────────────────────────────────────────────────
  ReservationModel copyWith({
    String? status,
    int? reviewRating,
    String? reviewComment,
    String? cancellationReason,
    int? packageID,
    String? packageName,
  }) =>
      ReservationModel(
        id: id,
        clientID: clientID,
        coachID: coachID,
        coachName: coachName,
        coachSpeciality: coachSpeciality,
        coachImageUrl: coachImageUrl,
        coachRating: coachRating,
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
        location: location,
        pricingStatus: pricingStatus,
        proposedPrice: proposedPrice,
        quoteVersion: quoteVersion,
        status: status ?? this.status,
        price: price,
        companyName: companyName,
        reviewRating: reviewRating ?? this.reviewRating,
        reviewComment: reviewComment ?? this.reviewComment,
        rejectionReason: rejectionReason,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        packageID: packageID ?? this.packageID,
        packageName: packageName ?? this.packageName,
      );
}
