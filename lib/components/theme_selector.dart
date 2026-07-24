import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/fitlek_theme_extension.dart';

/// Reusable appearance / theme picker for profile screens.
class ThemeSelectorTile extends StatelessWidget {
  final ThemeController controller;

  const ThemeSelectorTile({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fitlek = context.fitlek;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => _showThemeSheet(context),
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
                  child: Icon(Icons.palette_outlined, color: cs.primary, size: 15),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ThemeService.label(controller.mode),
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

  void _showThemeSheet(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fitlek = context.fitlek;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: controller,
        builder: (ctx, _) {
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
                  'Appearance',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose the app theme',
                  style: TextStyle(color: fitlek.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...AppThemeMode.values.map(
                  (mode) => _ThemeOption(
                    mode: mode,
                    selected: controller.mode == mode,
                    onTap: () {
                      controller.setMode(mode);
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

class _ThemeOption extends StatelessWidget {
  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
      case AppThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

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
            Icon(_icon, color: selected ? cs.primary : fitlek.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ThemeService.label(mode),
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

/// Provides [ThemeController] to descendant widgets (e.g. profile screens).
class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope not found in widget tree');
    return scope!.notifier!;
  }
}
