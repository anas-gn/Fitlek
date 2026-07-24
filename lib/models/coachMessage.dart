class CoachMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isFromCoach;

  const CoachMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isFromCoach,
  });
}
