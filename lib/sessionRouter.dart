import 'dart:async';
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
  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    // Restauration "local-first" : si un token + rôle sont déjà présents sur
    // l'appareil, on considère l'utilisateur connecté et on entre directement.
    // La session n'est effacée QUE lors d'une déconnexion explicite ou d'un
    // 401/403 réel rencontré pendant l'utilisation de l'app. On ne bloque donc
    // JAMAIS le démarrage sur un appel réseau : ainsi on ne login qu'une seule
    // fois par appareil (un nouvel appareil n'ayant pas de token devra login).
    final minDelay = Future.delayed(const Duration(milliseconds: 600));

    String? role;
    try {
      final localRole = await ApiService.getRole();
      final localToken = await ApiService.getToken();

      if (localToken != null && localToken.isNotEmpty && localRole != null) {
        // Session locale présente -> on entre. Validation en arrière-plan
        // (ne redirige jamais vers le login ; nettoie seulement si 401/403).
        role = localRole;
        unawaited(ApiService.checkSession());
      } else {
        // Pas de session locale -> on tente une vérification complète au cas où.
        role = await ApiService.checkSession();
      }

      await minDelay;
    } catch (_) {
      role = await ApiService.getRole();
    }

    if (!mounted) return;

    switch (role) {
      case 'coach':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutCoach()),
        );
        break;
      case 'client':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const _ClientHomeLoader()),
        );
        break;
      default:
        // Pas de session valide -> écran de bienvenue
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Affiche le splash pendant que la session est vérifiée.
    // Ce SplashScreen ne navigue plus tout seul (voir splachScreen.dart).
    return const SplashScreen();
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