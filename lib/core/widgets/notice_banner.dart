import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum NoticeStyle { warning, info }

/// A respectful, consistent notice and guidance banner.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.style = NoticeStyle.warning,
    this.isLiveRegion = false,
  });

  final String message;
  final IconData icon;
  final NoticeStyle style;
  final bool isLiveRegion;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (style) {
      NoticeStyle.warning => AppColors.surfaceWarm,
      NoticeStyle.info => AppColors.tipBackground,
    };

    final borderColor = switch (style) {
      NoticeStyle.warning => const Color(0xFFEBDAC0),
      NoticeStyle.info => AppColors.cardBorder,
    };

    final iconBgColor = switch (style) {
      NoticeStyle.warning => AppColors.iconContainerGold,
      NoticeStyle.info => AppColors.iconContainerGreen,
    };

    final iconColor = switch (style) {
      NoticeStyle.warning => AppColors.goldText,
      NoticeStyle.info => AppColors.green,
    };

    return Semantics(
      liveRegion: isLiveRegion,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
