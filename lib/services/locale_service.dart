import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The same languages as SIRVYA's existing ENG/FR/ESP screen families.
class LocaleService extends ChangeNotifier {
  LocaleService._();
  static final instance = LocaleService._();
  static const supported = [Locale('en'), Locale('fr'), Locale('es')];
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('sirvya_language');
    _locale = supported.firstWhere((v) => v.languageCode == code,
        orElse: () => const Locale('en'));
    notifyListeners();
  }

  Future<void> select(String code) async {
    _locale = supported.firstWhere((v) => v.languageCode == code);
    notifyListeners();
    await (await SharedPreferences.getInstance())
        .setString('sirvya_language', code);
  }

  Future<void> showPicker(BuildContext context) async {
    final code = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
                title: const Text('English · Français · Español'),
                children: [
                  for (final entry in {
                    'en': 'English',
                    'fr': 'Français',
                    'es': 'Español'
                  }.entries)
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, entry.key),
                        child: Text(entry.value))
                ]));
    if (code != null) await select(code);
  }
}
