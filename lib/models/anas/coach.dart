class CoachModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final bool isPremium;
  final String bio;
  final String instagramPage;
  final String invitationCode;
  final int totalInvitations;
  final int earnedPoints;
  final String? tel;
  final String? ville;
  final double? price;
  final double? rating;
  final int? totalSessions;
  final String? speciality;
  final int? categoryID;
  final String? categoryName;
  final int? reviewCount;

  const CoachModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.ville,
    required this.isPremium,
    required this.bio,
    required this.instagramPage,
    required this.invitationCode,
    required this.totalInvitations,
    required this.earnedPoints,
    this.tel,
    this.price,
    this.rating,
    this.totalSessions,
    this.speciality,
    this.categoryID,
    this.categoryName,
    this.reviewCount,
  });

  String get fullName => '$firstName $lastName';

  /// Returns a display string like "Musculation • Transformation"
  /// Uses categoryName first, falls back to speciality
  String get displaySpecialties {
    final parts = <String>[];
    if (categoryName != null && categoryName!.isNotEmpty) {
      parts.add(categoryName!);
    }
    if (speciality != null && speciality!.isNotEmpty && speciality != categoryName) {
      parts.add(speciality!);
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'Coach';
  }

  factory CoachModel.fromJson(Map<String, dynamic> json) => CoachModel(
        id: json['id'],
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        avatarUrl: json['avatarUrl'],
        isPremium: json['isPremium'] == 1 || json['isPremium'] == true,
        bio: json['bio'] ?? '',
        instagramPage: json['instagramPage'] ?? '',
        invitationCode: json['invitationCode'] ?? '',
        ville: json['ville'] ?? '',
        totalInvitations: json['totalInvitations'] ?? 0,
        earnedPoints: json['earnedPoints'] ?? 0,
        tel: json['tel'],
        price: json['price'] != null
            ? (json['price'] is num 
                ? (json['price'] as num).toDouble() 
                : double.tryParse(json['price'].toString()))
            : null,
        rating: json['rating'] != null 
            ? (json['rating'] as num).toDouble() 
            : null,
        totalSessions: json['totalSessions'],
        speciality: json['speciality'],
        categoryID: json['categoryID'],
        categoryName: json['categoryName'],
        reviewCount: json['reviewCount'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
        'isPremium': isPremium,
        'bio': bio,
        'instagramPage': instagramPage,
        'invitationCode': invitationCode,
        'totalInvitations': totalInvitations,
        'earnedPoints': earnedPoints,
        'tel': tel,
        'price': price,
        'rating': rating,
        'ville': ville,
        'totalSessions': totalSessions,
        'speciality': speciality,
        'categoryID': categoryID,
        'categoryName': categoryName,
        'reviewCount': reviewCount,
      };
}