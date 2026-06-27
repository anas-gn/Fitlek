import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/names.dart';
import 'services/apiService.dart';
import 'screens/ENG/welcome.dart';
import 'mainLayoutCoach.dart';
import 'mainLayoutManager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FitlekApp());
}

class FitlekApp extends StatelessWidget {
  const FitlekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppNames.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFA3FF12),
          secondary: Color(0xFFA3FF12),
          surface: Color(0xFF0E0E0E),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      ),
      home: const _SplashRouter(),
    );
  }
}

/// Checks the saved session and routes accordingly.
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Small delay so the splash doesn't flicker on fast devices
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final role = await ApiService.checkSession();

    if (!mounted) return;

    Widget destination;
    if (role == 'coach') {
      destination = const MainLayoutCoach();
    } else if (role == 'manager') {
      destination = const MainLayoutManager();
    } else {
      destination = const Welcome();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen shown while checking session
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFA3FF12),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 10))]),
            child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 46)),
          const SizedBox(height: 20),
          Text(AppNames.appName,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 40),
          const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              color: Color(0xFFA3FF12),
              strokeWidth: 2.5,
            ),
          ),
        ]),
      ),
    );
  }
}
