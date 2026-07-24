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
  final String? speciality;
  final double? price;
  final String? tel;
  final double? rating;
  final int totalReviews;
  final bool isPremium;
  final bool isApproved;
  final String role;

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
    this.speciality,
    this.price,
    this.tel,
    this.rating,
    required this.totalReviews,
    required this.isPremium,
    required this.isApproved,
    required this.role,
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
    String? speciality,
    double? price,
    String? tel,
    double? rating,
    int? totalReviews,
    bool? isPremium,
    bool? isApproved,
    String? role,
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
      speciality: speciality ?? this.speciality,
      price: price ?? this.price,
      tel: tel ?? this.tel,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isPremium: isPremium ?? this.isPremium,
      isApproved: isApproved ?? this.isApproved,
      role: role ?? this.role,
    );
  }
}
