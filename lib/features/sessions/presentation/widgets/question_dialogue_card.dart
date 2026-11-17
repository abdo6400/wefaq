import 'package:flutter/material.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class QuestionDialogueCard extends StatelessWidget {
  const QuestionDialogueCard({
    super.key,
    required this.questionText,
    this.clarificationText,
    this.topicLabel,
    this.depthLabel,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onReportQuestion,
    this.onCopyQuestion,
  });

  final String questionText;
  final String? clarificationText;
  final String? topicLabel;
  final String? depthLabel;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onReportQuestion;
  final VoidCallback? onCopyQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Subtle second trailing card in the deck
        Positioned.fill(
          top: 16,
          bottom: -14,
          left: 20,
          right: 20,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppSpacing.radiusHero + 2),
                border: Border.all(
                  color: AppColors.cardBorder.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
        // Subtle first trailing card in the deck
        Positioned.fill(
          top: 10,
          bottom: -7,
          left: 10,
          right: 10,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.tagBackground.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppSpacing.radiusHero + 2),
                border: Border.all(color: AppColors.cardBorder),
              ),
            ),
          ),
        ),
        // Primary active dialogue card
        Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.heroCardMinHeight,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusHero + 4),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadowDeep,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card top utility bar (tab order after main question)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.iconContainerGold,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.goldText,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                    if (onReportQuestion != null || onCopyQuestion != null)
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onReportQuestion != null)
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(4),
                                child: _CardActionButton(
                                  onPressed: onReportQuestion!,
                                  tooltip: 'إبداء ملاحظة على هذا السؤال',
                                  icon: Icons.outlined_flag_rounded,
                                  iconSize: 19,
                                ),
                              ),
                            if (onReportQuestion != null &&
                                onCopyQuestion != null)
                              const SizedBox(width: AppSpacing.xs),
                            if (onCopyQuestion != null)
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(5),
                                child: _CardActionButton(
                                  onPressed: onCopyQuestion!,
                                  tooltip: AppStrings.copyQuestionTooltip,
                                  icon: Icons.copy_rounded,
                                  iconSize: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (onFavoriteToggle != null)
                      Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(3),
                          child: Semantics(
                            toggled: isFavorite,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: isFavorite
                                    ? AppColors.iconContainerGold
                                    : AppColors.background,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isFavorite
                                      ? AppColors.goldText
                                      : AppColors.inputBorder,
                                ),
                              ),
                              child: IconButton(
                                onPressed: onFavoriteToggle,
                                tooltip: isFavorite
                                    ? AppStrings.removeFromFavoritesTooltip
                                    : AppStrings.addToFavoritesTooltip,
                                constraints: const BoxConstraints(
                                  minWidth: AppSpacing.minTouchTarget,
                                  minHeight: AppSpacing.minTouchTarget,
                                ),
                                icon: Icon(
                                  isFavorite
                                      ? Icons.star
                                      : Icons.star_border_rounded,
                                  color: isFavorite
                                      ? AppColors.goldText
                                      : AppColors.muted,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Semantic metadata badges
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: Wrap(
                    spacing: AppSpacing.xs + 2,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.center,
                    children: [
                      const _MetadataPill(
                        label: AppStrings.sessionCardTitle,
                        bgColor: AppColors.tagBackground,
                        textColor: AppColors.green,
                      ),
                      if (topicLabel != null && topicLabel!.isNotEmpty)
                        _MetadataPill(
                          label: topicLabel!,
                          bgColor: AppColors.iconContainerGold,
                          textColor: AppColors.dark,
                        ),
                      if (depthLabel != null && depthLabel!.isNotEmpty)
                        _MetadataPill(
                          label: depthLabel!,
                          bgColor: AppColors.background,
                          textColor: AppColors.muted,
                          borderColor: AppColors.cardBorder,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Main question prompt (reading order 1)
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: Column(
                    children: [
                      Text(
                        questionText,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.dark,
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                          height: 1.65,
                        ),
                      ),
                      if (clarificationText != null &&
                          clarificationText!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tipBackground,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ExcludeSemantics(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 18,
                                    color: AppColors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  clarificationText!,
                                  textAlign: TextAlign.start,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.muted,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Calm bottom gold flourish
                ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 32,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    required this.iconSize,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        icon: Icon(icon, color: AppColors.muted, size: iconSize),
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
