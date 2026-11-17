import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isGoldAccent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isGoldAccent;

  @override
  Widget build(BuildContext context) {
    final iconBg = isGoldAccent
        ? AppColors.iconContainerGold
        : AppColors.iconContainerGreen;
    final iconColor = isGoldAccent ? AppColors.goldText : AppColors.green;

    return Semantics(
      button: true,
      label: '$title، $subtitle',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            onTap: onTap,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg + 2),
                child: Row(
                  children: [
                    Container(
                      width: AppSpacing.iconContainerSize,
                      height: AppSpacing.iconContainerSize,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusChip,
                        ),
                      ),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: AppSpacing.md + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTinted,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.green,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile mode selector tile used in 2-column home dashboard grids.
class ModeGridTile extends StatelessWidget {
  const ModeGridTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isGoldAccent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isGoldAccent;

  @override
  Widget build(BuildContext context) {
    final iconBg = isGoldAccent
        ? AppColors.iconContainerGold
        : AppColors.iconContainerGreen;
    final iconColor = isGoldAccent ? AppColors.goldText : AppColors.green;

    return Semantics(
      button: true,
      label: '$title، $subtitle',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            onTap: onTap,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusChip,
                            ),
                          ),
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceTinted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.green,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Bento topic card used on the home dashboard topic grid.
class TopicBentoTile extends StatelessWidget {
  const TopicBentoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.countBadge,
    required this.onTap,
    this.isGoldAccent = false,
    this.accentColor,
    this.accentBackground,
  });

  final IconData icon;
  final String title;
  final String countBadge;
  final VoidCallback onTap;
  final bool isGoldAccent;
  final Color? accentColor;
  final Color? accentBackground;

  @override
  Widget build(BuildContext context) {
    final bgAccent =
        accentBackground ??
        (isGoldAccent
            ? AppColors.iconContainerGold
            : AppColors.iconContainerGreen);
    final fgAccent =
        accentColor ?? (isGoldAccent ? AppColors.goldText : AppColors.green);

    return Semantics(
      button: true,
      label: '$title، $countBadge',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            onTap: onTap,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: bgAccent,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: Icon(icon, color: fgAccent, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + 1,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: bgAccent,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                              child: Text(
                                countBadge,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: fgAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                  height: 1.3,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: fgAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
