class CoachInvitation {
  final String id;
  final String clientName;
  final DateTime clickedAt;
  final int earnedPoints;
  final String invitationCode;

  const CoachInvitation({
    required this.id,
    required this.clientName,
    required this.clickedAt,
    required this.earnedPoints,
    required this.invitationCode,
  });
}
