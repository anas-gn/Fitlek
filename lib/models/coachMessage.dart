class CoachMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final String? mediaUrl;
  final String mediaType;
  final bool mediaExpired;
  final DateTime timestamp;
  final bool isFromCoach;

  const CoachMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.text,
    this.mediaUrl,
    this.mediaType = 'text',
    this.mediaExpired = false,
    required this.timestamp,
    required this.isFromCoach,
  });
}
