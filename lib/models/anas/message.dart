class MessageModel {
  final int id;
  final int conversationID;
  final int senderID;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  // Joined fields
  final String? senderName;
  final String? senderAvatar;

  const MessageModel({
    required this.id,
    required this.conversationID,
    required this.senderID,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'],
        conversationID: json['conversationID'],
        senderID: json['senderID'],
        body: json['body'],
        isRead: json['isRead'] == 1 || json['isRead'] == true,
        createdAt: DateTime.parse(json['createdAt']),
        senderName: json['senderName'],
        senderAvatar: json['senderAvatar'],
      );
}

class MessageRequest {
  final String body;
  const MessageRequest({required this.body});
  Map<String, dynamic> toJson() => {'body': body};
}