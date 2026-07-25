import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// One option of an [AppDropdownField]. [enabled] renders the row greyed out
/// and unselectable — e.g. a venue already picked in the paired dropdown.
class AppDropdownItem<T> {
  final T value;
  final String label;
  final bool enabled;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });
}

/// Dropdown styled like [AppTextField]: same fill, radius and borders, with the
/// label above the field instead of floating inside it.
///
/// A [value] that is not among [items] falls back to the [hintText] rather than
/// asserting, so callers can render before their options have loaded.
class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final bool enabled;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final fillColor = isLight
        ? AppColors.lightSurfaceVariant
        : AppColors.surfaceVariant;
    final subtleBorderColor = isLight
        ? AppColors.lightBorder
        : AppColors.borderSubtle;
    final isEnabled = enabled && onChanged != null;
    final selected =
        items.any((item) => item.value == value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              labelText!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        InputDecorator(
          isEmpty: selected == null,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: BorderSide(color: subtleBorderColor),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selected,
              isExpanded: true,
              isDense: true,
              borderRadius: AppRadius.mediumRadius,
              dropdownColor: fillColor,
              iconEnabledColor: colorScheme.onSurfaceVariant,
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
              hint: hintText == null
                  ? null
                  : Text(
                      hintText!,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
              items: [
                for (final item in items)
                  DropdownMenuItem<T>(
                    value: item.value,
                    enabled: item.enabled,
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: item.enabled
                          ? null
                          : TextStyle(color: theme.disabledColor),
                    ),
                  ),
              ],
              onChanged: isEnabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
