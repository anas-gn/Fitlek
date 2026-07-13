import 'package:fitlek1/screens/ENG/mainLayout.dart';
import 'package:flutter/material.dart';
import 'components/theme_selector.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'screens/ENG/splachScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  await themeController.load();
  runApp(Fitlek(themeController: themeController));
}

class Fitlek extends StatelessWidget {
  final ThemeController themeController;

  const Fitlek({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.flutterMode,
            home: const SplashScreen(),
            routes: {
              '/welcome': (context) => const SplashScreen(),
              '/main': (context) => const MainLayoutPlaceholder(),
            },
          );
        },
      ),
    );
  }
}

class MainLayoutPlaceholder extends StatelessWidget {
  const MainLayoutPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return MainLayout(
      clientID: args?['clientID'] ?? 0,
      token: args?['token'] ?? '',
      firstName: args?['firstName'],
      avatarUrl: args?['avatarUrl'],
      onLogout: args?['onLogout'],
    );
  }
}
