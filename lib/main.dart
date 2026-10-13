import 'services/referral_link_service.dart';
import 'services/background_location_service.dart';
import 'package:flutter/material.dart';
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
import 'globals.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await BackgroundLocationService.initialize();
    } catch (e) {
      debugPrint("Background location unavailable: $e");
    }
    try {
      await dotenv.load(fileName: "assets/config.env");
    } catch (e) {
      debugPrint("Failed to load env: $e");
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      await NotificationService.instance.init();
    } catch (e) {
      debugPrint("Failed to initialize notifications: $e");
    }

    try {
      await ReferralLinkService.instance.initialize();
    } catch (e) {
      debugPrint('Invitation links unavailable: $e');
    }
    final themeController = ThemeController();
    await themeController.load();
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
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.flutterMode,
            navigatorKey: globalNavigatorKey,
            home: const VideoSplashScreen(
              nextScreen: AppVersionChecker(child: SessionRouter()),
            ),
          );
        },
      ),
    );
  }
}
