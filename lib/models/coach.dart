class Coach {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String bio;
  final String instagramPage;
  final String? certificateImagePath;
  final int totalInvitations;
  final int earnedPoints;
  final String avatarUrl;

  const Coach({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.bio,
    required this.instagramPage,
    this.certificateImagePath,
    required this.totalInvitations,
    required this.earnedPoints,
    required this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';

  Coach copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? gender,
    String? bio,
    String? instagramPage,
    String? certificateImagePath,
    int? totalInvitations,
    int? earnedPoints,
    String? avatarUrl,
  }) {
    return Coach(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      instagramPage: instagramPage ?? this.instagramPage,
      certificateImagePath: certificateImagePath ?? this.certificateImagePath,
      totalInvitations: totalInvitations ?? this.totalInvitations,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
