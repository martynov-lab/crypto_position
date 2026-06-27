import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              labelText!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onSubmitted: onSubmitted,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          textInputAction: textInputAction,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.info,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 15,
              color: AppColors.textTertiary,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: IconTheme(
                      data: IconThemeData(
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      child: prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints: prefixIcon != null
                ? const BoxConstraints(minWidth: 44, minHeight: 44)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: AppColors.info, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: AppColors.negative),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: AppColors.negative, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            errorText: null,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs2),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.negative,
                ),
                const SizedBox(width: AppSpacing.xs2),
                Expanded(
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.negative,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
