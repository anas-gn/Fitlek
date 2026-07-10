import 'package:flutter/material.dart';
import 'services/apiService.dart';
import 'screens/ENG/splachScreen.dart';
import 'screens/ENG/welcome.dart';
import 'screens/ENG/login.dart';
import 'screens/ENG/clientHome.dart';
import 'mainLayoutCoach.dart';

class SessionRouter extends StatefulWidget {
  const SessionRouter({super.key});

  @override
  State<SessionRouter> createState() => _SessionRouterState();
}

class _SessionRouterState extends State<SessionRouter> {
  Widget? _target;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    try {
      final role = await ApiService.checkSession();

      if (!mounted) return;

      setState(() {
        _loading = false;
        switch (role) {
          case 'coach':
            _target = const MainLayoutCoach();
            break;
          case 'client':
            _target = const _ClientHomeLoader();
            break;
          default:
            _target = const SplashScreen();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _target = const SplashScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Affiche SplashScreen pendant le chargement
    if (_loading) {
      return const SplashScreen();
    }
    return _target ?? const SplashScreen();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Charge les données client et navigue vers HomeScreen
// ═══════════════════════════════════════════════════════════════════════════

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
      // Pas de données = retour au login
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
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFA3FF12)),
      ),
    );
  }
}