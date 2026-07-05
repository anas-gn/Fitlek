class InvitationModel {
  final int id;
  final int coachID;
  final int invitedUserID;
  final int pointsEarned;
  final DateTime clickedAt;
  // Joined
  final String? invitedUserName;

  const InvitationModel({
    required this.id,
    required this.coachID,
    required this.invitedUserID,
    required this.pointsEarned,
    required this.clickedAt,
    this.invitedUserName,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) => InvitationModel(
        id: json['id'],
        coachID: json['coachID'],
        invitedUserID: json['invitedUserID'],
        pointsEarned: json['pointsEarned'] ?? 20,
        clickedAt: DateTime.parse(json['clickedAt']),
        invitedUserName: json['invitedUserName'],
      );
}