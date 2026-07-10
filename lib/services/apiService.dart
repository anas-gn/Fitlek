import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/urls.dart';

class ApiService {
  static const String baseUrl = '$kBaseUrl/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (kDebugMode) debugPrint('TOKEN SAVED');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('firstName');
    if (kDebugMode) debugPrint('TOKEN CLEARED');
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<void> saveUserData(int id, String firstName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', id);
    await prefs.setString('firstName', firstName);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId');
    final firstName = prefs.getString('firstName');
    if (id == null) return null;
    return {'id': id, 'firstName': firstName ?? ''};
  }

  static Future<String?> checkSession() async {
    final token = await getToken();
    final role = await getRole();

    if (kDebugMode) {
      debugPrint('CHECK SESSION - Token: ${token != null ? 'EXISTS' : 'NULL'}');
      debugPrint('CHECK SESSION - Role: $role');
    }

    if (token == null || role == null) return null;

    try {
      final path = role == 'coach'
          ? '/coach/profile'
          : role == 'manager'
              ? '/manager/profile'
              : '/client/profile';

      final result = await get(path);
      if (kDebugMode) debugPrint('SESSION RESULT: $result');

      if (result['ok'] == true) return role;

      await clearToken();
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('SESSION CHECK ERROR: $e');
      return null;
    }
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          debugPrint('AUTH HEADER: Bearer ${token.substring(0, 30)}...');
        }
      } else {
        if (kDebugMode) debugPrint('NO TOKEN - Request will be unauthorized');
      }
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final headers = await _headers();
      final uri = Uri.parse('$baseUrl$path');

      if (kDebugMode) debugPrint('GET $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        debugPrint('GET $path -> ${response.statusCode}');
        debugPrint('BODY: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }

      return _handle(response);
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint('NETWORK ERROR GET $path: $e');
      return {
        'ok': false,
        'message': 'Erreur reseau. Verifiez votre connexion.',
        'status': 0,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR GET $path: $e');
      return {'ok': false, 'message': 'Erreur: $e', 'status': 0};
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final headers = await _headers(auth: auth);
      final uri = Uri.parse('$baseUrl$path');

      if (kDebugMode) debugPrint('POST $uri');

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        debugPrint('POST $path -> ${response.statusCode}');
        debugPrint('BODY: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }

      return _handle(response);
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint('NETWORK ERROR POST $path: $e');
      return {
        'ok': false,
        'message': 'Erreur reseau. Verifiez votre connexion.',
        'status': 0,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR POST $path: $e');
      return {'ok': false, 'message': 'Erreur: $e', 'status': 0};
    }
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await _headers();
      final response = await http
          .put(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _handle(response);
    } catch (e) {
      return {'ok': false, 'message': 'Erreur: $e', 'status': 0};
    }
  }

  static Future<Map<String, dynamic>> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final headers = await _headers();
      final response = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handle(response);
    } catch (e) {
      return {'ok': false, 'message': 'Erreur: $e', 'status': 0};
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handle(response);
    } catch (e) {
      return {'ok': false, 'message': 'Erreur: $e', 'status': 0};
    }
  }

  static Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required Map<String, String> fields,
    required Uint8List fileBytes,
    required String fileField,
    required String fileName,
    required String mimeType,
    bool auth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri);

      if (auth) {
        final token = await getToken();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
      }

      fields.forEach((k, v) => request.fields[k] = v);

      final parts = mimeType.split('/');
      request.files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
        contentType: MediaType(parts[0], parts.length > 1 ? parts[1] : '*'),
      ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      return _handle(response);
    } catch (e) {
      return {'ok': false, 'message': 'Erreur upload: $e', 'status': 0};
    }
  }

  static Map<String, dynamic> _handle(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is List) return {'data': decoded, 'ok': true};
        return {...(decoded as Map<String, dynamic>), 'ok': true};
      }

      String message = 'Erreur inconnue';
      if (decoded is Map<String, dynamic>) {
        message = decoded['message'] ??
            decoded['error'] ??
            'Erreur ${response.statusCode}';
      }

      if (kDebugMode) debugPrint('API ERROR ${response.statusCode}: $message');

      return {
        'ok': false,
        'message': message,
        'status': response.statusCode,
      };
    } catch (e) {
      return {
        'ok': false,
        'message': 'Reponse invalide du serveur',
        'status': response.statusCode,
      };
    }
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}