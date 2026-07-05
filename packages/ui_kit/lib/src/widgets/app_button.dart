import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

enum AppButtonVariant { primary, outlined }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  const AppButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  }) : variant = AppButtonVariant.outlined;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    final enabled = onPressed != null;

    final foregroundColor = isPrimary
        ? AppColors.textOnPrimary
        : AppColors.textPrimary;

    return Material(
      color: isPrimary
          ? (enabled ? AppColors.primary : AppColors.surfaceVariant)
          : Colors.transparent,
      borderRadius: AppRadius.mediumRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.mediumRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: isPrimary
              ? null
              : BoxDecoration(
                  borderRadius: AppRadius.mediumRadius,
                  border: Border.all(
                    color: enabled ? AppColors.border : AppColors.borderSubtle,
                  ),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: enabled ? foregroundColor : AppColors.textTertiary,
                    size: 20,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: enabled ? foregroundColor : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
