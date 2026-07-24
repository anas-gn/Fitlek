import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'fitlek_theme_extension.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final fitlek = isLight ? FitlekColors.light : FitlekColors.dark;

    final colorScheme = isLight
        ? const ColorScheme.light(
            primary: AppColors.cyprus,
            onPrimary: AppColors.sand,
            secondary: AppColors.cyprus,
            onSecondary: AppColors.sand,
            surface: AppColors.lightSurface,
            onSurface: AppColors.lightTextPrimary,
            surfaceContainerHighest: AppColors.lightSurfaceVariant,
            onSurfaceVariant: AppColors.lightTextSecondary,
            outline: AppColors.lightBorder,
            error: AppColors.error,
            onError: AppColors.sand,
          )
        : const ColorScheme.dark(
            primary: AppColors.sand,
            onPrimary: AppColors.cyprus,
            secondary: AppColors.sand,
            onSecondary: AppColors.cyprus,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkTextPrimary,
            surfaceContainerHighest: AppColors.darkSurfaceVariant,
            onSurfaceVariant: AppColors.darkTextSecondary,
            outline: AppColors.darkBorder,
            error: AppColors.error,
            onError: AppColors.sand,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.lightBackground : AppColors.darkBackground,
      extensions: [fitlek],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: fitlek.card,
        elevation: isLight ? 1 : 0,
        shadowColor: fitlek.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: fitlek.border.withValues(alpha: 0.6)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight
            ? AppColors.cyprus.withValues(alpha: 0.12)
            : AppColors.sand.withValues(alpha: 0.12),
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: fitlek.card,
        modalBackgroundColor: fitlek.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: fitlek.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.cyprus : AppColors.darkSurfaceVariant,
        contentTextStyle: TextStyle(
          color: isLight ? AppColors.sand : AppColors.sand,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fitlek.inputFill,
        hintStyle: TextStyle(color: fitlek.textMuted),
        labelStyle: TextStyle(color: fitlek.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fitlek.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fitlek.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: isLight ? 2 : 0,
          shadowColor: fitlek.shadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight ? AppColors.cyprus : AppColors.sand,
          side: BorderSide(color: isLight ? AppColors.cyprus : AppColors.sand),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: fitlek.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: isLight ? 8 : 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? colorScheme.primary : fitlek.navUnselected,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : fitlek.navUnselected,
            size: 22,
          );
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: fitlek.border.withValues(alpha: 0.4),
        circularTrackColor: fitlek.border.withValues(alpha: 0.4),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
        bodySmall: TextStyle(color: fitlek.textSecondary),
        titleLarge: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        labelLarge: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
