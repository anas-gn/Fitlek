import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/urls.dart';

class ApiService {
  static const String baseUrl = '$kBaseUrl/api';

  // ─── Token ───────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }

  // ─── Role ─────────────────────────────────────────────────────────────────
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // ─── Session check ────────────────────────────────────────────────────────
  /// Returns 'coach' | 'manager' | null
  static Future<String?> checkSession() async {
    final token = await getToken();
    final role  = await getRole();
    if (token == null || role == null) return null;
    // Validate token is still accepted by the server
    try {
      final path = role == 'coach' ? '/coach/profile' : '/manager/profile';
      final result = await get(path);
      if (result['ok'] == true) return role;
      await clearToken();
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Headers ──────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── JSON verbs ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String path) async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _handle(response);
  }

  static Future<Map<String, dynamic>> post(String path,
      Map<String, dynamic> body, {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    final response = await http.post(Uri.parse('$baseUrl$path'),
        headers: headers, body: jsonEncode(body));
    return _handle(response);
  }

  static Future<Map<String, dynamic>> put(String path,
      Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http.put(Uri.parse('$baseUrl$path'),
        headers: headers, body: jsonEncode(body));
    return _handle(response);
  }

  static Future<Map<String, dynamic>> patch(String path,
      [Map<String, dynamic>? body]) async {
    final headers = await _headers();
    final response = await http.patch(Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null);
    return _handle(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _headers();
    final response =
        await http.delete(Uri.parse('$baseUrl$path'), headers: headers);
    return _handle(response);
  }

  // ─── Multipart upload ─────────────────────────────────────────────────────
  /// Sends a multipart/form-data POST.
  /// [fields]   – text fields
  /// [fileBytes] – raw bytes of the file
  /// [fileField] – field name expected by the server (e.g. 'certificate')
  /// [fileName]  – original file name
  /// [mimeType]  – e.g. 'image/jpeg', 'application/pdf'
  static Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required Map<String, String> fields,
    required Uint8List fileBytes,
    required String fileField,
    required String fileName,
    required String mimeType,
    bool auth = true,
  }) async {
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

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  // ─── Response handler ─────────────────────────────────────────────────────
  static Map<String, dynamic> _handle(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is List) return {'data': decoded, 'ok': true};
      return {...(decoded as Map<String, dynamic>), 'ok': true};
    }
    return {
      'ok': false,
      'message':
          (decoded as Map<String, dynamic>)['message'] ?? 'Unknown error',
      'status': response.statusCode,
    };
  }

  // ─── UI helper ────────────────────────────────────────────────────────────
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
