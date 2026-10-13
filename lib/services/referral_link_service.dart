import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralLinkService {
  static final instance = ReferralLinkService();
  final code = ValueNotifier<String>('');
  StreamSubscription<Uri>? _subscription;
  Future<void> Function()? onInvitation;
  static String? parseCode(Uri uri) {
    if (uri.scheme != 'sirvya' || uri.host != 'invite') return null;
    final value = uri.queryParameters['code']?.trim().toUpperCase() ?? '';
    return RegExp(r'^[A-Z0-9-]{4,64}$').hasMatch(value) ? value : null;
  }

  static String? codeFromQr(String raw) {
    final uri = Uri.tryParse(raw.trim());
    String value = raw.trim();
    if (uri != null && uri.hasScheme) {
      if (uri.scheme == 'sirvya') return parseCode(uri);
      final parts = uri.pathSegments;
      if (!['https', 'http'].contains(uri.scheme) ||
          parts.length < 2 ||
          parts[parts.length - 2] != 'invite') return null;
      value = parts.last;
    }
    value = value.toUpperCase();
    return RegExp(r'^[A-Z0-9-]{4,64}$').hasMatch(value) ? value : null;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    code.value = prefs.getString('pending_inviter_code') ?? '';
    if (kIsWeb) {
      final value = Uri.base.queryParameters['referral'] ??
          Uri.base.queryParameters['code'];
      if (value != null)
        await _receive(Uri(
            scheme: 'sirvya',
            host: 'invite',
            queryParameters: {'code': value}));
      return;
    }
    final links = AppLinks();
    _subscription ??= links.uriLinkStream.listen((uri) {
      unawaited(_receive(uri));
    });
    final initial = await links.getInitialLink();
    if (initial != null) await _receive(initial);
  }

  Future<void> _receive(Uri uri) async {
    final value = parseCode(uri);
    if (value == null || value == code.value) return;
    code.value = value;
    await (await SharedPreferences.getInstance())
        .setString('pending_inviter_code', value);
    await onInvitation?.call();
  }

  Future<void> clear() async {
    code.value = '';
    await (await SharedPreferences.getInstance())
        .remove('pending_inviter_code');
  }
}
