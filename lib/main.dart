import 'package:fitlek1/screens/ENG/mainLayout.dart';
import 'package:flutter/material.dart';
import 'screens/ENG/splachScreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await UserSession.instance.load();
  runApp(const Fitlek());
}
class Fitlek extends StatelessWidget {
  const Fitlek({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC6F135),
          secondary: Color(0xFFC6F135),
          surface: Color(0xFF141414),
          background: Color(0xFF0A0A0A),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF232323)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF232323)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC6F135), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const SplashScreen(),
        '/main': (context) => const MainLayoutPlaceholder(),
      },
    );
  }
}
class MainLayoutPlaceholder extends StatelessWidget {
  const MainLayoutPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return MainLayout(
      clientID: args?['clientID'] ?? 0,
      token: args?['token'] ?? '',
      firstName: args?['firstName'],
      avatarUrl: args?['avatarUrl'],
      onLogout: args?['onLogout'],
    );
  }
}