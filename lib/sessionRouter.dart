import 'dart:async';
import 'package:flutter/material.dart';
import 'services/apiService.dart';
import 'screens/ENG/welcome.dart';
import 'screens/ENG/login.dart';
import 'screens/ENG/clientHome.dart';
import 'screens/workout_webview.dart';
import 'mainLayoutCoach.dart';

class SessionRouter extends StatefulWidget {
  const SessionRouter({super.key});

  @override
  State<SessionRouter> createState() => _SessionRouterState();
}

class _SessionRouterState extends State<SessionRouter> {
  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<String?> _resolveRole() async {
    try {
      final localRole = await ApiService.getRole();
      final localToken = await ApiService.getToken();

      if (localToken != null && localToken.isNotEmpty && localRole != null) {
        // A Sirvya workout session takes precedence: drop straight into the workout
        // WebView (it re-validates its token against the workout server on load).
        final sirvyaAuth = await ApiService.getSirvyaAuth();
        if (sirvyaAuth != null && sirvyaAuth.isNotEmpty) {
          return 'sirvya_workout';
        }
        unawaited(ApiService.checkSession());
        return localRole;
      } else {
        return await ApiService.checkSession();
      }
    } catch (_) {
      return await ApiService.getRole();
    }
  }

  Future<void> _resolveSession() async {
    final results = await Future.wait([
      _resolveRole(),
      Future.delayed(const Duration(milliseconds: 500)),
    ]);
    final role = results[0] as String?;

    if (!mounted) return;

    switch (role) {
      case 'coach':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutCoach()),
        );
        break;
      case 'sirvya_workout':
        // Sirvya users whose workout session is still live drop straight into the
        // embedded openGym frontend on return to the app. The screen re-verifies the
        // stored token via the workout server; role falls back to 'client' otherwise.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutWebviewScreen()),
        );
        break;
      case 'client':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const _ClientHomeLoader()),
        );
        break;
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _ClientHomeLoader extends StatefulWidget {
  const _ClientHomeLoader();

  @override
  State<_ClientHomeLoader> createState() => _ClientHomeLoaderState();
}

class _ClientHomeLoaderState extends State<_ClientHomeLoader> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final userData = await ApiService.getUserData();
    final token = await ApiService.getToken();

    if (!mounted) return;

    if (userData == null || token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          clientID: userData['id'],
          token: token,
          firstName: userData['firstName'],
          onLogout: () async {
            await ApiService.clearToken();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (_) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}