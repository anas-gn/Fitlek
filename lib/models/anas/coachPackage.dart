/// Model for a coaching package offered by a coach.
/// [price] may be null, meaning the price will be discussed after booking.
class CoachPackage {
  final int id;
  final int coachID;
  final String name;
  final String? description;
  final int? sessions; // number of sessions included, null = custom/unspecified
  final double? price; // null = price to be discussed
  final bool isActive;
  final int sortOrder;

  const CoachPackage({
    required this.id,
    required this.coachID,
    required this.name,
    this.description,
    this.sessions,
    this.price,
    required this.isActive,
    required this.sortOrder,
  });

  bool get hasPriceSet => price != null && price! > 0;

  factory CoachPackage.fromJson(Map<String, dynamic> j) {
    return CoachPackage(
      id: _toInt(j['id']),
      coachID: _toInt(j['coachID']),
      name: j['name'] as String? ?? '',
      description: j['description'] as String?,
      sessions: j['sessions'] != null ? _toInt(j['sessions']) : null,
      price: j['price'] != null ? _toDouble(j['price']) : null,
      isActive: _toBool(j['isActive']),
      sortOrder: _toInt(j['sortOrder'], 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'coachID': coachID,
        'name': name,
        if (description != null) 'description': description,
        if (sessions != null) 'sessions': sessions,
        if (price != null) 'price': price,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return true;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }
}
