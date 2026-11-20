import 'package:flutter/material.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../theme/fitlek_theme_extension.dart';

/// Reusable language picker for profile and settings screens.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  static String _label(BuildContext context, Locale? locale) {
    final l10n = AppLocalizations.of(context);
    switch (locale?.languageCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'fr':
        return l10n.languageFrench;
      default:
        return l10n.languageSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fitlek = context.fitlek;
    final l10n = AppLocalizations.of(context);

    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleService.locale,
      builder: (context, currentLocale, _) {
        return GestureDetector(
          onTap: () => _showLanguageSheet(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fitlek.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fitlek.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.language_rounded, color: cs.primary, size: 15),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.language,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _label(context, currentLocale),
                        style: TextStyle(color: fitlek.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: fitlek.textMuted, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fitlek = context.fitlek;

    const options = <Locale?>[null, Locale('en'), Locale('fr')];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleService.locale,
        builder: (ctx, currentLocale, _) {
          final l10n = AppLocalizations.of(ctx);
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: fitlek.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: fitlek.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.language,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map(
                  (locale) => _LanguageOption(
                    label: _label(ctx, locale),
                    icon: locale == null
                        ? Icons.settings_suggest_rounded
                        : Icons.translate_rounded,
                    selected: currentLocale?.languageCode == locale?.languageCode,
                    onTap: () {
                      LocaleService.set(locale);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Alias matching [ThemeSelectorTile] naming convention.
typedef LanguageSelectorTile = LanguageSelector;

class _LanguageOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fitlek = context.fitlek;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.1) : fitlek.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary.withValues(alpha: 0.4) : fitlek.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? cs.primary : fitlek.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
