import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/wefaq_card.dart';
import '../../domain/models/activity.dart';

/// Reusable card displaying a structured conversational activity or scenario.
///
/// Complies with Wefaq accessibility standards:
/// - Directionality-aware Arabic RTL layout
/// - Minimum contrast ratios
/// - High legibility typography
/// - Zero data collection
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, this.trailing});

  final Activity activity;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isScenario = activity.type == ActivityType.scenario;
    final badgeLabel = isScenario ? 'سيناريو للنقاش' : 'ترتيب أولويات مشتركة';
    final badgeIcon = isScenario
        ? Icons.explore_outlined
        : Icons.format_list_numbered_rtl;

    return WefaqCard(
      hasShadow: true,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Type Badge + Trailing Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tagBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 16.0, color: AppColors.green),
                    const SizedBox(width: 6.0),
                    Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            activity.title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Situation Container
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              activity.situation,
              style: const TextStyle(
                fontSize: 15.0,
                color: AppColors.dark,
                height: 1.5,
              ),
            ),
          ),

          // Options section (for priority ordering)
          if (activity.options.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'النقاط المقترحة للنقاش:',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...activity.options.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22.0,
                      height: 22.0,
                      margin: const EdgeInsets.only(top: 2.0),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.tagBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: AppColors.dark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Reflection Prompts
          if (activity.prompts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'محاور لتبادل الرأي:',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...activity.prompts.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: Icon(
                        Icons.circle,
                        size: 6.0,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: AppColors.dark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (activity.isDevelopmentOnly) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'نشاط تجريبي قيد المراجعة والاستكشاف',
              style: TextStyle(
                fontSize: 11.0,
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
