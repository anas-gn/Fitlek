enum BanType { temporary, permanent }

class BanModel {
  final int id;
  final int userID;
  final int bannedBy;
  final BanType banType;
  final String reason;
  final DateTime bannedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime? liftedAt;
  final int? liftedBy;
  // Joined
  final String? userName;
  final String? bannedByName;

  const BanModel({
    required this.id,
    required this.userID,
    required this.bannedBy,
    required this.banType,
    required this.reason,
    required this.bannedAt,
    this.expiresAt,
    required this.isActive,
    this.liftedAt,
    this.liftedBy,
    this.userName,
    this.bannedByName,
  });

  bool get isExpired =>
      banType == BanType.temporary &&
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now());

  factory BanModel.fromJson(Map<String, dynamic> json) => BanModel(
        id: json['id'],
        userID: json['userID'],
        bannedBy: json['bannedBy'],
        banType: json['banType'] == 'permanent' ? BanType.permanent : BanType.temporary,
        reason: json['reason'],
        bannedAt: DateTime.parse(json['bannedAt']),
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
        isActive: json['isActive'] == 1 || json['isActive'] == true,
        liftedAt: json['liftedAt'] != null ? DateTime.parse(json['liftedAt']) : null,
        liftedBy: json['liftedBy'],
        userName: json['userName'],
        bannedByName: json['bannedByName'],
      );
}

class BanRequest {
  final int userID;
  final String banType; // 'temporary' | 'permanent'
  final String reason;
  final String? expiresAt; // "YYYY-MM-DD HH:MM:SS"

  const BanRequest({
    required this.userID,
    required this.banType,
    required this.reason,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
        'userID': userID,
        'banType': banType,
        'reason': reason,
        if (expiresAt != null) 'expiresAt': expiresAt,
      };
}