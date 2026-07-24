enum InvitationStatus { pending, accepted, refused }

class InvitationModel {
  final int id;
  final int coachID;
  final int invitedUserID;
  final int pointsEarned;
  final InvitationStatus status;
  final DateTime clickedAt;
  final DateTime? respondedAt;
  final String? invitedUserName;
  final String? invitedUserAvatar;

  const InvitationModel({
    required this.id,
    required this.coachID,
    required this.invitedUserID,
    required this.pointsEarned,
    required this.status,
    required this.clickedAt,
    this.respondedAt,
    this.invitedUserName,
    this.invitedUserAvatar,
  });

  bool get isPending => status == InvitationStatus.pending;

  static InvitationStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted': return InvitationStatus.accepted;
      case 'refused': return InvitationStatus.refused;
      default: return InvitationStatus.pending;
    }
  }

  factory InvitationModel.fromJson(Map<String, dynamic> json) => InvitationModel(
        id: json['id'],
        coachID: json['coachID'],
        invitedUserID: json['invitedUserID'],
        pointsEarned: json['pointsEarned'] ?? 20,
        status: _parseStatus(json['status']),
        clickedAt: DateTime.parse(json['clickedAt']),
        respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
        invitedUserName: json['invitedUserName'],
        invitedUserAvatar: json['invitedUserAvatar'],
      );
}