enum BanType { temporary, permanent }
enum BannedUserType { client, coach }

class ManagerBan {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final BannedUserType userType;
  final BanType banType;
  final String reason;
  final DateTime bannedAt;
  final DateTime? expiresAt;
  bool isActive;

  ManagerBan({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.userType,
    required this.banType,
    required this.reason,
    required this.bannedAt,
    this.expiresAt,
    this.isActive = true,
  });

  String get banTypeLabel =>
      banType == BanType.temporary ? 'Temporary' : 'Permanent';

  String get userTypeLabel =>
      userType == BannedUserType.client ? 'Client' : 'Coach';
}
