import 'package:flutter/painting.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const _fontFamily = 'Inter';

  // Headings
  static const h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Body
  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Stat numbers
  static const statLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const statMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // Caption / label
  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );

  static const label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}
