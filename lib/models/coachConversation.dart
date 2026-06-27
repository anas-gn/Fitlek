class CoachConversation {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhotoUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const CoachConversation({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhotoUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });
}
