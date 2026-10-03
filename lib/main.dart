import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/locale_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'components/theme_selector.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'sessionRouter.dart';
import 'components/app_version_checker.dart';
import 'components/video_splash_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: "assets/config.env");
    } catch (e) {
      debugPrint("Failed to load env: $e");
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      // A missing browser service worker/token must never prevent the app opening.
      await NotificationService.instance
          .init()
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint("Failed to initialize notifications: $e");
    }

    final themeController = ThemeController();
    await themeController.load();
    await LocaleService.instance.load();
    runApp(Fitlek(themeController: themeController));
  } catch (e, stackTrace) {
    debugPrint("FATAL ERROR IN MAIN: $e");
    debugPrint("$stackTrace");
  }
}

class Fitlek extends StatelessWidget {
  final ThemeController themeController;

  const Fitlek({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: Listenable.merge([themeController, LocaleService.instance]),
        builder: (context, _) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            locale: LocaleService.instance.locale,
            supportedLocales: LocaleService.supported,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.flutterMode,
            home: const VideoSplashScreen(
              nextScreen: AppVersionChecker(child: SessionRouter()),
            ),
          );
        },
      ),
    );
  }
}
