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

    return Semantics(
      label:
          '${AppStrings.questionProgress(currentIndex + 1, totalQuestions)}. $modeLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tagBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  modeLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    AppStrings.questionProgress(
                      currentIndex + 1,
                      totalQuestions,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.radiusChip),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: AppSpacing.progressBarHeight + 2,
              backgroundColor: AppColors.progressTrack,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}
