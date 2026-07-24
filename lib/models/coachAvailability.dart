class CoachAvailability {
  final String id;
  final DateTime date;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String? note;

  const CoachAvailability({
    required this.id,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.note,
  });

  String get startLabel =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endLabel =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  bool blocksSlot(DateTime slotDate, int hour) {
    final sameDay = slotDate.year == date.year &&
        slotDate.month == date.month &&
        slotDate.day == date.day;
    if (!sameDay) return false;
    final slotMinutes = hour * 60;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    return slotMinutes >= startMinutes && slotMinutes < endMinutes;
  }

  bool conflictsWithDay(DateTime d) {
    return d.year == date.year &&
        d.month == date.month &&
        d.day == date.day;
  }
}
