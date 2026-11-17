import 'package:flutter/material.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SessionProgressHeader extends StatelessWidget {
  const SessionProgressHeader({
    super.key,
    required this.modeLabel,
    required this.currentIndex,
    required this.totalQuestions,
  });

  final String modeLabel;
  final int currentIndex;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final progressValue = totalQuestions > 0
        ? ((currentIndex + 1) / totalQuestions).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progressValue * 100).round();

    return Semantics(
      container: true,
      label:
          '${AppStrings.questionProgress(currentIndex + 1, totalQuestions)}. $modeLabel ($percent%)',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tagBackground,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      modeLabel,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.questionProgress(
                          currentIndex + 1,
                          totalQuestions,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.5,
                          color: AppColors.dark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: Text(
                          '$percent%',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: progressValue),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return LinearProgressIndicator(
                      value: animatedValue,
                      minHeight: AppSpacing.progressBarHeight + 2,
                      backgroundColor: AppColors.progressTrack,
                      color: AppColors.green,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
