class ConversationModel {
  final int id;
  final int coachID;
  final int clientID;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  // Joined fields
  final String? otherName;
  final String? otherAvatar;
  // Local enrichment
  final int unreadCount;
  final String? lastMessageBody;

  const ConversationModel({
    required this.id,
    required this.coachID,
    required this.clientID,
    this.lastMessageAt,
    required this.createdAt,
    this.otherName,
    this.otherAvatar,
    this.unreadCount = 0,
    this.lastMessageBody,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
        id: json['id'],
        coachID: json['coachID'],
        clientID: json['clientID'],
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.parse(json['lastMessageAt'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        otherName: json['otherName'],
        otherAvatar: json['otherAvatar'],
        unreadCount: json['unreadCount'] ?? 0,
        lastMessageBody: json['lastMessageBody'],
      );
}