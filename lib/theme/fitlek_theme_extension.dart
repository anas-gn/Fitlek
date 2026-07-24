import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Theme-aware semantic colors used across Fitlek screens.
@immutable
class FitlekColors extends ThemeExtension<FitlekColors> {
  final Color card;
  final Color card2;
  final Color border;
  final Color textSecondary;
  final Color textMuted;
  final Color inputFill;
  final Color shadow;
  final Color navUnselected;
  final Color primaryDim;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color violet;
  final Color instagram;
  final Color premium;
  final Color onAccent;

  const FitlekColors({
    required this.card,
    required this.card2,
    required this.border,
    required this.textSecondary,
    required this.textMuted,
    required this.inputFill,
    required this.shadow,
    required this.navUnselected,
    required this.primaryDim,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.violet,
    required this.instagram,
    required this.premium,
    required this.onAccent,
  });

  static const light = FitlekColors(
    card: AppColors.lightSurface,
    card2: AppColors.lightSurfaceVariant,
    border: AppColors.lightBorder,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    inputFill: AppColors.lightSurface,
    shadow: Color(0x1A004643),
    navUnselected: Color(0xFF9CA3AF),
    primaryDim: AppColors.primaryDim,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    violet: AppColors.violet,
    instagram: AppColors.instagram,
    premium: AppColors.premium,
    onAccent: AppColors.sand,
  );

  static const dark = FitlekColors(
    card: AppColors.darkSurface,
    card2: AppColors.darkSurfaceVariant,
    border: AppColors.darkBorder,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    inputFill: AppColors.darkSurfaceVariant,
    shadow: Color(0x40000000),
    navUnselected: Color(0xFF7A8785),
    primaryDim: AppColors.sand,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    violet: AppColors.violet,
    instagram: AppColors.instagram,
    premium: AppColors.premium,
    onAccent: AppColors.cyprus,
  );

  @override
  FitlekColors copyWith({
    Color? card,
    Color? card2,
    Color? border,
    Color? textSecondary,
    Color? textMuted,
    Color? inputFill,
    Color? shadow,
    Color? navUnselected,
    Color? primaryDim,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? violet,
    Color? instagram,
    Color? premium,
    Color? onAccent,
  }) {
    return FitlekColors(
      card: card ?? this.card,
      card2: card2 ?? this.card2,
      border: border ?? this.border,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      inputFill: inputFill ?? this.inputFill,
      shadow: shadow ?? this.shadow,
      navUnselected: navUnselected ?? this.navUnselected,
      primaryDim: primaryDim ?? this.primaryDim,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      violet: violet ?? this.violet,
      instagram: instagram ?? this.instagram,
      premium: premium ?? this.premium,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  FitlekColors lerp(ThemeExtension<FitlekColors>? other, double t) {
    if (other is! FitlekColors) return this;
    return FitlekColors(
      card: Color.lerp(card, other.card, t)!,
      card2: Color.lerp(card2, other.card2, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      navUnselected: Color.lerp(navUnselected, other.navUnselected, t)!,
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      instagram: Color.lerp(instagram, other.instagram, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

extension FitlekThemeContext on BuildContext {
  ThemeData get fitlekTheme => Theme.of(this);
  ColorScheme get fitlekScheme => fitlekTheme.colorScheme;
  FitlekColors get fitlek => fitlekTheme.extension<FitlekColors>()!;
}
