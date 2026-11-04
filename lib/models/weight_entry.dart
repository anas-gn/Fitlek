class WeightEntry {
  final int id;
  final double weight;
  final DateTime at;
  final String note;
  const WeightEntry(
      {required this.id,
      required this.weight,
      required this.at,
      this.note = ''});

  static WeightEntry? fromJson(Map<String, dynamic> json) {
    final weight = double.tryParse('${json['weight']}');
    final raw =
        DateTime.tryParse('${json['createdAt'] ?? json['recordedAt'] ?? ''}');
    if (weight == null ||
        !weight.isFinite ||
        weight <= 0 ||
        weight > 500 ||
        raw == null) {
      return null;
    }
    final at = raw.isUtc
        ? raw
        : DateTime.utc(
            raw.year, raw.month, raw.day, raw.hour, raw.minute, raw.second);
    return WeightEntry(
        id: int.tryParse('${json['id']}') ?? 0,
        weight: weight,
        at: at,
        note: '${json['note'] ?? ''}'.trim());
  }

  String get label => '${at.day} ${_months[at.month - 1]}';
  String get fullLabel => '$label ${at.year}';
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
}

List<WeightEntry> weightPeriod(
    List<WeightEntry> entries, int? days, DateTime now) {
  final utc = now.toUtc();
  final end = DateTime.utc(utc.year, utc.month, utc.day + 1);
  final start = days == null ? null : end.subtract(Duration(days: days));
  return entries
      .where(
          (e) => start == null || (!e.at.isBefore(start) && e.at.isBefore(end)))
      .toList()
    ..sort((a, b) {
      final order = a.at.compareTo(b.at);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
}

String weightChange(double difference) =>
    '${difference > .049 ? '+' : difference < -.049 ? '−' : ''}${difference.abs().toStringAsFixed(1)} kg';
