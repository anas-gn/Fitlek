import 'package:fitlek1/models/anas/user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'],
        refreshToken: json['refreshToken'],
        user: UserModel.fromJson(json['user']),
      );
}

class LoginRequest {
  final String email;
  final String password;
  final String? deviceInfo;

  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
      };
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String gender;
  final String role;

  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.gender,
    this.role = 'client',
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'gender': gender,
        'role': role,
      };
}