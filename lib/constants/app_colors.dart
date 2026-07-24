import 'package:flutter/material.dart';

/// Brand and semantic colors for Fitlek.
/// Theme-dependent surfaces live in [FitlekColors] (ThemeExtension).
class AppColors {
  AppColors._();

  // Brand palette
  static const Color cyprus = Color(0xFF004643);
  static const Color sand = Color(0xFFF0EDE5);

  // Light-mode surfaces
  static const Color lightBackground = sand;
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF8F6F0);
  static const Color lightBorder = Color(0xFFD4D0C8);
  static const Color lightTextPrimary = Color(0xFF0A1F1E);
  static const Color lightTextSecondary = Color(0xFF5C6B69);
  static const Color lightTextMuted = Color(0xFF7A8785);

  // Dark-mode surfaces
  static const Color darkBackground = Color(0xFF0A1817);
  static const Color darkSurface = Color(0xFF142E2C);
  static const Color darkSurfaceVariant = Color(0xFF1A3835);
  static const Color darkBorder = Color(0xFF2A4F4C);
  static const Color darkTextPrimary = sand;
  static const Color darkTextSecondary = Color(0xFFC8C4BC);
  static const Color darkTextMuted = Color(0xFF9A9690);

  // Semantic status colors (shared across themes)
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF6A623);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF4E9BFF);
  static const Color violet = Color(0xFFA277FF);
  static const Color instagram = Color(0xFFE1306C);
  static const Color premium = Color(0xFFFFD700);

  static const Color primaryDim = Color(0xFF003835);
}
