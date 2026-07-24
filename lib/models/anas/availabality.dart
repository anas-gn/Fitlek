class AvailabilityBlock {
  final int id;
  final int coachID;
  final DateTime blockedDate;
  final String startTime; // "HH:MM:SS"
  final String endTime;
  final String? note;
  final DateTime createdAt;

  const AvailabilityBlock({
    required this.id,
    required this.coachID,
    required this.blockedDate,
    required this.startTime,
    required this.endTime,
    this.note,
    required this.createdAt,
  });

  factory AvailabilityBlock.fromJson(Map<String, dynamic> json) => AvailabilityBlock(
        id: json['id'],
        coachID: json['coachID'],
        blockedDate: DateTime.parse(json['blockedDate']),
        startTime: json['startTime'],
        endTime: json['endTime'],
        note: json['note'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'blockedDate': blockedDate.toIso8601String().split('T').first,
        'startTime': startTime,
        'endTime': endTime,
        if (note != null) 'note': note,
      };
}

class AvailabilityRequest {
  final String blockedDate;
  final String startTime;
  final String endTime;
  final String? note;

  const AvailabilityRequest({
    required this.blockedDate,
    required this.startTime,
    required this.endTime,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'blockedDate': blockedDate,
        'startTime': startTime,
        'endTime': endTime,
        if (note != null) 'note': note,
      };
}