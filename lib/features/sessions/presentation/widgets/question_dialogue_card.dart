import 'package:flutter/material.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class QuestionDialogueCard extends StatelessWidget {
  const QuestionDialogueCard({
    super.key,
    required this.questionText,
    this.clarificationText,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onReportQuestion,
  });

  final String questionText;
  final String? clarificationText;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onReportQuestion;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: 10,
          bottom: -8,
          left: 10,
          right: 10,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.tagBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
                border: Border.all(color: AppColors.cardBorder),
              ),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.heroCardMinHeight,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxxl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: AppSpacing.iconContainerSize,
                      height: AppSpacing.iconContainerSize,
                      decoration: BoxDecoration(
                        color: AppColors.iconContainerGold,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  if (onReportQuestion != null)
                    Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: IconButton(
                          onPressed: onReportQuestion,
                          tooltip: 'إبداء ملاحظة على هذا السؤال',
                          icon: const Icon(
                            Icons.outlined_flag_rounded,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  if (onFavoriteToggle != null)
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? AppColors.iconContainerGold
                              : AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFavorite
                                ? AppColors.gold
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: IconButton(
                          onPressed: onFavoriteToggle,
                          tooltip: isFavorite
                              ? AppStrings.removeFromFavoritesTooltip
                              : AppStrings.addToFavoritesTooltip,
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border_rounded,
                            color: isFavorite
                                ? AppColors.gold
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tagBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  AppStrings.sessionCardTitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                questionText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                ),
              ),
              if (clarificationText != null &&
                  clarificationText!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tipBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    clarificationText!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted, height: 1.5),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg + 2),
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
