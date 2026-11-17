import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ChoiceChipsSelector<T> extends StatelessWidget {
  const ChoiceChipsSelector({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.iconBuilder,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final IconData Function(T)? iconBuilder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in values)
          ChoiceChip(
            avatar: iconBuilder != null
                ? Icon(
                    iconBuilder!(value),
                    size: 17,
                    color: value == selected
                        ? AppColors.surfaceWhite
                        : AppColors.green,
                  )
                : null,
            label: Text(label(value)),
            selected: value == selected,
            onSelected: (_) => onChanged(value),
            showCheckmark: false,
            selectedColor: AppColors.green,
            backgroundColor: AppColors.background,
            elevation: 0,
            pressElevation: 0,
            labelStyle: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13.5,
              color: value == selected
                  ? AppColors.surfaceWhite
                  : AppColors.dark,
              fontWeight: value == selected ? FontWeight.bold : FontWeight.w600,
            ),
            side: BorderSide(
              color: value == selected
                  ? AppColors.green
                  : AppColors.inputBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
      ],
    );
  }
}
