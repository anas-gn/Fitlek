import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

DateTime workoutTrainingTime(DateTime instant, {String? timeZone}) {
  if (timeZone == null || timeZone.isEmpty) return instant.toLocal();
  if (tz.timeZoneDatabase.locations.isEmpty) {
    tzdata.initializeTimeZones();
  }
  try {
    return tz.TZDateTime.from(instant, tz.getLocation(timeZone));
  } on tz.LocationNotFoundException {
    return instant.toLocal();
  }
}

DateTime? workoutTrainingDate(dynamic value, {String? timeZone}) {
  final date = value is DateTime ? value : DateTime.tryParse('$value');
  if (date == null) return null;
  // DATE columns and chart keys are already calendar dates, not UTC instants.
  if (value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return DateTime(date.year, date.month, date.day);
  }
  return workoutTrainingTime(date, timeZone: timeZone);
}
