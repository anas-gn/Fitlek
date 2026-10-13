import 'dart:convert';
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

  final double? minPrice;
  final double? distanceKm;
  final bool isApproved;
  final bool isAvailableToday;
  final List<String>? certifications;
  final List<String>? specialties;
  final String? gymName;
  final String? gymAddress;
  final String? gymImage;

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
    this.minPrice,
    this.distanceKm,
    this.isApproved = false,
    this.isAvailableToday = false,
    this.certifications,
    this.specialties,
    this.gymName,
    this.gymAddress,
    this.gymImage,

  });

  String get fullName => '$firstName $lastName';

  bool get hasGym => gymName?.trim().isNotEmpty == true;
  String get displaySpecialties {
    if (specialties?.isNotEmpty == true) return specialties!.join(' • ');
    if (speciality?.trim().isNotEmpty == true) return speciality!.trim();
    if (categoryName?.trim().isNotEmpty == true) return categoryName!.trim();
    return 'Coach';
  }
  String get locationLabel {
    final city = ville?.split(',').first.trim();
    final label = city?.isNotEmpty == true ? city! : 'Location not set';
    final km = distanceKm;
    if (km == null || !km.isFinite || km < 0) return label;
    final approximate = km < 0.1 ? '<0.1' : km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return '$label · ≈ $approximate km';
  }
  static double? _decimal(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
  static int? _integer(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
  static bool _flag(dynamic v) => v == true || v?.toString() == '1';
  static List<String>? _list(dynamic value, {bool certificates = false}) {
    if (value == null) return null;
    try {
      if (value is String && value.trim().startsWith('[')) value = jsonDecode(value);
      final values = value is List ? value : value.toString().split(RegExp(r'[,/]'));
      return values.map((e) {
        if (certificates && e is Map) {
          final name = e['name']?.toString() ?? 'Certificate';
          final provider = e['provider']?.toString();
          return provider?.isNotEmpty == true ? '$name ($provider)' : name;
        }
        return e.toString().trim();
      }).where((e) => e.isNotEmpty).toList();
    } catch (_) { return null; }
  }

  factory CoachModel.fromJson(Map<String, dynamic> json) => CoachModel(
        id: _integer(json['id'])!,
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        avatarUrl: json['avatarUrl'],
        isPremium: json['isPremium'] == 1 || json['isPremium'] == true,
        bio: json['bio'] ?? '',
        instagramPage: json['instagramPage'] ?? '',
        invitationCode: json['invitationCode'] ?? '',
        ville: json['ville'] ?? '',
        totalInvitations: _integer(json['totalInvitations']) ?? 0,
        earnedPoints: _integer(json['earnedPoints']) ?? 0,
        tel: json['tel'],
        price: json['price'] != null
            ? (json['price'] is num 
                ? (json['price'] as num).toDouble() 
                : double.tryParse(json['price'].toString()))
            : null,
        rating: _decimal(json['rating']),
        totalSessions: _integer(json['totalSessions']),
        speciality: json['speciality'],
        categoryID: _integer(json['categoryID']),
        categoryName: json['categoryName'],
        reviewCount: _integer(json['reviewCount']),
        minPrice: _decimal(json['minPrice']),
        distanceKm: _decimal(json['distanceKm']),
        isApproved: _flag(json['isApproved']) || _flag(json['isVerified']),
        isAvailableToday: _flag(json['isAvailableToday']),
        certifications: _list(json['certifications'], certificates: true),
        specialties: _list(json['specialties']),
        gymName: json['gymName']?.toString().trim(),
        gymAddress: json['gymAddress']?.toString().trim(),
        gymImage: json['gymImage']?.toString().trim(),
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
        'minPrice': minPrice,
        'distanceKm': distanceKm,
        'isApproved': isApproved,
        'isAvailableToday': isAvailableToday,
        'certifications': certifications,
        'specialties': specialties,
        'gymName': gymName,
        'gymAddress': gymAddress,
        'gymImage': gymImage,

      };
}