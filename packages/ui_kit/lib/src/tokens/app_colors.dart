import 'dart:ui';

abstract final class AppColors {
  // Backgrounds
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceVariant = Color(0xFF242424);
  static const surfaceElevated = Color(0xFF2A2A2A);

  // Accent — lime/chartreuse
  static const primary = Color(0xFFC8FF00);
  static const primaryMuted = Color(0xFF9ABF00);

  // Secondary — warm gold
  static const secondary = Color(0xFFD4A855);
  static const secondaryMuted = Color(0xFFB08C3E);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3B3B3);
  static const textTertiary = Color(0xFF737373);
  static const textOnPrimary = Color(0xFF0D0D0D);

  // Semantic
  static const positive = Color(0xFF00D68F);
  static const negative = Color(0xFFFF3D71);
  static const warning = Color(0xFFFFAA00);
  static const info = Color(0xFF0095FF);

  // Borders
  static const border = Color(0xFF2E2E2E);
  static const borderSubtle = Color(0xFF1F1F1F);

  // Light theme
  static const lightBackground = Color(0xFFF5F5F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF0F0F0);
  static const lightTextPrimary = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF6B6B6B);
  static const lightBorder = Color(0xFFE0E0E0);
}
