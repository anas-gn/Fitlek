class ManagerAdmin {
  final String id;
  String firstName;
  String lastName;
  String email;
  String avatarUrl;
  DateTime createdAt;

  ManagerAdmin({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatarUrl,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
}
