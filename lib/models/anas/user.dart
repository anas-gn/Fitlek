class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // 'client' | 'coach' | 'admin' | 'manager' | 'advisor'
  final String gender; // 'Male' | 'Female' | 'Other'
  final String? avatarUrl;
  final bool isPremium;
  final bool isApproved;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.gender,
    this.avatarUrl,
    required this.isPremium,
    required this.isApproved,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        role: json['role'],
        gender: json['gender'],
        avatarUrl: json['avatarUrl'],
        isPremium: json['isPremium'] == 1 || json['isPremium'] == true,
        isApproved: json['isApproved'] == 1 || json['isApproved'] == true,
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'gender': gender,
        'avatarUrl': avatarUrl,
        'isPremium': isPremium,
        'isApproved': isApproved,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    bool? isPremium,
    bool? isApproved,
  }) =>
      UserModel(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        role: role,
        gender: gender,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isPremium: isPremium ?? this.isPremium,
        isApproved: isApproved ?? this.isApproved,
        createdAt: createdAt,
      );
}