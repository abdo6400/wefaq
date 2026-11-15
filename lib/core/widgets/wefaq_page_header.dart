import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Curved emerald-to-dark editorial header shared across Wefaq screens.
class WefaqPageHeader extends StatelessWidget {
  const WefaqPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.tagline,
    this.badgeText,
    this.leading,
    this.bottomOverlap = 0,
  });

  final String title;
  final String? subtitle;
  final String? tagline;
  final String? badgeText;
  final Widget? leading;
  final double bottomOverlap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.dark, AppColors.green],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusHero + 8),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusHero + 8),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -42,
              end: -36,
              child: IgnorePointer(
                child: Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.14),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              bottom: -28,
              start: -24,
              child: IgnorePointer(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceWhite.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl + bottomOverlap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leading != null || badgeText != null) ...[
                    Row(
                      children: [
                        ?leading,
                        if (badgeText != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs + 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill,
                                  ),
                                  border: Border.all(
                                    color: AppColors.surfaceWhite.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  badgeText!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.surfaceWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (tagline != null) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs + 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.iconContainerGold,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          tagline!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.dark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.background,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
