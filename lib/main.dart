import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'components/theme_selector.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'sessionRouter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notifications
  await NotificationService.instance.init();

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
            home: const SessionRouter(), 
          );
        },
      ),
    );
  }
}