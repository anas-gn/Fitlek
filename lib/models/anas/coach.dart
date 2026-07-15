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
  });

  String get fullName => '$firstName $lastName';

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
        // ✅ FIX: Gère String ET num pour price
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
        'tel': tel,           // ✅ AJOUTÉ
        'price': price,       // ✅ AJOUTÉ
        'rating': rating,
        'ville':ville,
        'totalSessions': totalSessions,
        'speciality': speciality,
      };
}