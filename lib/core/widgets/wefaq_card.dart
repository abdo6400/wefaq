import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Standardized card with brand-consistent border, shape, optional shadow, and tap feedback.
class WefaqCard extends StatelessWidget {
  const WefaqCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.hasShadow = false,
    this.backgroundColor = AppColors.surfaceWhite,
    this.borderColor = AppColors.cardBorder,
    this.borderRadius = AppSpacing.radiusCard,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool hasShadow;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final box = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: hasShadow
            ? const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x0512382E),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
    return box;
  }
}
