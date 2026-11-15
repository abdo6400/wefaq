import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Standardized card with brand-consistent border, shape, and optional shadow.
class WefaqCard extends StatelessWidget {
  const WefaqCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.hasShadow = false,
    this.backgroundColor = AppColors.surfaceWhite,
    this.borderColor = AppColors.cardBorder,
    this.borderRadius = AppSpacing.radiusCard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool hasShadow;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: hasShadow
            ? const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      padding: padding,
      child: child,
    );
  }
}
