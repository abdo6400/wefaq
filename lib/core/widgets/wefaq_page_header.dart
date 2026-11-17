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
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final String? tagline;
  final String? badgeText;
  final Widget? leading;
  final double bottomOverlap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPad = compact ? AppSpacing.md : AppSpacing.lg;
    final bottomPad = (compact ? AppSpacing.lg : AppSpacing.xl) + bottomOverlap;
    final cornerRadius = const Radius.circular(AppSpacing.radiusHero + 8);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.dark, AppColors.green, AppColors.greenLight],
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: cornerRadius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowDeep,
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: cornerRadius),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -46,
              end: -34,
              child: IgnorePointer(
                child: Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.22),
                        AppColors.gold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: -16,
              end: -8,
              child: IgnorePointer(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.09),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              bottom: -32,
              start: -24,
              child: IgnorePointer(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceWhite.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                topPad,
                AppSpacing.xl,
                bottomPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leading != null || badgeText != null) ...[
                    Row(
                      children: [
                        if (leading != null)
                          leading is IconButton
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.dark.withValues(
                                      alpha: 0.36,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surfaceWhite.withValues(
                                        alpha: 0.24,
                                      ),
                                    ),
                                  ),
                                  child: leading,
                                )
                              : leading!,
                        if (badgeText != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dark.withValues(alpha: 0.44),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill,
                                  ),
                                  border: Border.all(
                                    color: AppColors.surfaceWhite.withValues(
                                      alpha: 0.24,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  badgeText!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.surfaceWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
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
                    SizedBox(
                      height: compact ? AppSpacing.sm : AppSpacing.md - 2,
                    ),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style:
                          (compact
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.bold,
                                height: 1.32,
                              ),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs + 1),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.92),
                        height: 1.55,
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
