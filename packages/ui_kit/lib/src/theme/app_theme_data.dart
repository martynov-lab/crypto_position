import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';

abstract final class AppThemeData {
  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderSubtle,
      error: AppColors.negative,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadius.mediumRadius),
        filled: true,
        fillColor: AppColors.surfaceVariant,
      ),
      textTheme: _buildTextTheme(colorScheme),
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryMuted,
      onPrimary: AppColors.lightSurface,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightBorder,
      error: AppColors.negative,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
          side: BorderSide(color: AppColors.lightBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadius.mediumRadius),
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
      ),
      textTheme: _buildTextTheme(colorScheme),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    return TextTheme(
      headlineLarge: AppTypography.h1.copyWith(color: scheme.onSurface),
      headlineMedium: AppTypography.h2.copyWith(color: scheme.onSurface),
      headlineSmall: AppTypography.h3.copyWith(color: scheme.onSurface),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: scheme.onSurface),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
      bodySmall: AppTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: AppTypography.label.copyWith(color: scheme.onSurface),
      labelSmall: AppTypography.caption.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
