// lib/models/advisor_model.dart

class AdvisorModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final bool isApproved;
  final DateTime createdAt;
  // From advisorProfiles join
  final int profileId;
  final String specialty;

  const AdvisorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    required this.isApproved,
    required this.createdAt,
    required this.profileId,
    required this.specialty,
  });

  String get fullName => '$firstName $lastName';

  factory AdvisorModel.fromJson(Map<String, dynamic> json) => AdvisorModel(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        avatarUrl: json['avatarUrl'],
        isApproved: json['isApproved'] == 1 || json['isApproved'] == true,
        createdAt: DateTime.parse(json['createdAt']),
        profileId: json['profileId'],
        specialty: json['specialty'] ?? '',
      );
}