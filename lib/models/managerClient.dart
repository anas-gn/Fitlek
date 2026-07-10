class ManagerClient {
  final String id;
  String firstName;
  String lastName;
  String email;
  String gender;
  bool isPremium;
  bool isRemoteAdmin;
  bool isBanned;
  String avatarUrl;

  ManagerClient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    this.isPremium = false,
    this.isRemoteAdmin = false,
    this.isBanned = false,
    required this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';
}
