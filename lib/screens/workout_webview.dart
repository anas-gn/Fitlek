import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart' show NavigationDelegate, JavaScriptMode, WebViewController, WebViewWidget;
import '../../constants/urls.dart';
import '../../services/apiService.dart';
import '../../services/google_auth_service.dart';
import '../../services/open_external.dart';

class WorkoutWebviewScreen extends StatefulWidget {
  final String? serverBase;
  const WorkoutWebviewScreen({super.key, this.serverBase});
  @override
  State<WorkoutWebviewScreen> createState() => _WorkoutWebviewState();
}

class _WorkoutWebviewState extends State<WorkoutWebviewScreen> {
  static const Duration _timeout = Duration(seconds: 20);
  // Lazily built: WebViewController asserts at construction when no WebView platform
  // implementation exists (Flutter web), so it must not be a field initializer.
  WebViewController? _controller;
  String? _sessionToken;
  bool _loading = true;
  bool _needSignIn = false;
  String? _error;
  String get _base => widget.serverBase ?? workoutBaseUrl;

  @override
  void initState() {
    super.initState();
    unawaited(_signInAndRun());
  }

  /// Token precedence: the Firebase session (Google/Apple sign-in) first, then the
  /// Sirvya platform JWT saved by the email/password login. The workout server's
  /// /api/auth/sirvya-login bridge accepts both.
  Future<String?> _identityToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.getIdToken();
    return ApiService.getToken();
  }

  Future<void> _signInAndRun() async {
    try {
      // Check for existing valid session first (relaunch path)
      final existingToken = await ApiService.getSirvyaAuth();
      if (existingToken != null && !_isTokenExpired(existingToken)) {
        _sessionToken = existingToken;
        _loadWebViewWithToken(existingToken);
        return;
      }

      // No valid session, perform fresh exchange
      final token = await _identityToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) { setState(() { _needSignIn = true; _loading = false; }); return; }
      
      // Native mobile: exchange token via workout API, then pass exchanged session to WebView
      // Web: external browser with #sirvya_login= (raw credential, exchanged through Vite proxy)
      if (kIsWeb) {
        setState(() => _loading = false);
        openExternal('$_base/#sirvya_login=${Uri.encodeComponent(token)}');
      } else {
        // Exchange the Sirvya token for an openGym session token
        final response = await http.post(
          Uri.parse('$_base/api/auth/sirvya-login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': token}),
        ).timeout(_timeout);
        
        if (!mounted) return;
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final sessionToken = data['token'] as String?;
          
          if (sessionToken != null) {
            // Persist the exchanged session token for relaunch
            await ApiService.setSirvyaAuth(sessionToken);
            _sessionToken = sessionToken;
            
            _loadWebViewWithToken(sessionToken);
          } else {
            setState(() { _error = 'Invalid session response'; _loading = false; });
          }
        } else {
          setState(() { _error = 'Token exchange failed: ${response.statusCode}'; _loading = false; });
        }
      }
    } catch (e) { if (mounted) setState(() { _error = 'Login error: $e'; _loading = false; }); }
  }

  /// Check if HMAC-signed token has expired (format: <uid>:<expiry>.<mac>)
  bool _isTokenExpired(String token) {
    try {
      final lastDot = token.lastIndexOf('.');
      if (lastDot < 0) return true;
      final payload = token.substring(0, lastDot);
      final parts = payload.split(':');
      if (parts.length < 2) return true;
      final exp = int.tryParse(parts[1]);
      if (exp == null) return true;
      return exp < DateTime.now().millisecondsSinceEpoch;
    } catch {
      return true;
    }
  }

  void _loadWebViewWithToken(String token) {
    // Load embedded WebView with the session token
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          setState(() => _loading = false);
        },
        onNavigationRequest: (NavigationRequest request) {
          // Handle 401 errors from openGym APIs
          if (request.url.contains('/api/') && request.url.contains('401')) {
            _handleSessionInvalidation();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse('$_base/#sirvya_token=${Uri.encodeComponent(token)}'));
  }

  Future<void> _handleSessionInvalidation() async {
    // Clear invalid session
    await ApiService.clearSirvyaAuth();
    _sessionToken = null;
    
    // Attempt silent re-bridge once
    final sirvyaToken = await _identityToken();
    if (sirvyaToken != null && mounted) {
      setState(() { _loading = true; _error = null; });
      unawaited(_signInAndRun());
    } else {
      // No Sirvya token available, route to Sirvya login
      if (mounted) {
        setState(() { _needSignIn = true; _loading = false; });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try { await GoogleAuthService.signInWithGoogle(role: 'client'); if (mounted) setState(() { _needSignIn = false; _loading = true; _error = null; }); unawaited(_signInAndRun()); }
    catch (e) { if (mounted) setState(() => _error = 'Google sign-in failed: $e'); }
  }

  Widget _buildTopBar(BuildContext context) { return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()); }

  @override
  Widget build(BuildContext context) {
    final view = kIsWeb ? const SizedBox.shrink() : WebViewWidget(controller: _controller ??= WebViewController());
    return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, appBar: AppBar(leading: _buildTopBar(context)), body: Column(children: [Expanded(child: Stack(children: [view, if (_needSignIn) _buildSignIn(context) else if (_error != null && _sessionToken == null) _buildError(context) else if (_loading) Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))]))]));
  }

  Widget _buildSignIn(BuildContext context) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('Connect your SIRVYA account to train.', style: TextStyle(fontSize: 17)),
    const SizedBox(height: 16),
    Row(mainAxisSize: MainAxisSize.min, children: [
      OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Sign in')),
      const SizedBox(width: 12),
      OutlinedButton(onPressed: _signInWithGoogle, child: const Text('Continue with Google')),
    ]),
  ]));}

  Widget _buildError(BuildContext context) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text(_error ?? 'Error', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
    const SizedBox(height: 12),
    OutlinedButton(onPressed: () { setState(() { _error = null; _loading = true; }); unawaited(_signInAndRun()); }, child: const Text('Retry')),
  ]));}
}