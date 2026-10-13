class ReviewItem {
  final int id;
  final int coachID;
  final int clientID;
  final int rating;
  final String? comment;
  final String clientName;
  final String? clientAvatar;
  final DateTime createdAt;

  const ReviewItem({
    required this.id,
    required this.coachID,
    required this.clientID,
    required this.rating,
    this.comment,
    required this.clientName,
    this.clientAvatar,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem(
        id: j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? '') ?? 0,
        coachID: j['coachID'] is int ? j['coachID'] : int.tryParse(j['coachID']?.toString() ?? '') ?? 0,
        clientID: j['clientID'] is int ? j['clientID'] : int.tryParse(j['clientID']?.toString() ?? '') ?? 0,
        rating: j['rating'] is int ? j['rating'] : int.tryParse(j['rating']?.toString() ?? '') ?? 5,
        comment: j['comment'] as String?,
        clientName: j['clientName'] as String? ?? 'Anonymous',
        clientAvatar: j['clientAvatar'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}
