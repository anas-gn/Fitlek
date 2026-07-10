class ManagerCoach {
  final String id;
  String firstName;
  String lastName;
  String email;
  String gender;
  String bio;
  String instagramPage;
  bool isApproved;
  bool isBanned;
  String avatarUrl;
  int totalClients;
  int totalReservations;

  ManagerCoach({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.bio,
    required this.instagramPage,
    this.isApproved = true,
    this.isBanned = false,
    required this.avatarUrl,
    this.totalClients = 0,
    this.totalReservations = 0,
  });

  String get fullName => '$firstName $lastName';
}
