class ManagerAdvisor {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String specialty;
  final String avatarUrl;
  final int totalClients;
  final DateTime joinedAt;

  const ManagerAdvisor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.specialty,
    required this.avatarUrl,
    required this.totalClients,
    required this.joinedAt,
  });

  String get fullName => '$firstName $lastName';
}
