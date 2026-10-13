import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const seenKey = 'sirvya_intro_seen';

  static Future<bool> showOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(seenKey) == true) return false;
    await prefs.setBool(seenKey, true);
    return true;
  }
}
