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
  });

  final String message;
  final IconData icon;
  final NoticeStyle style;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (style) {
      NoticeStyle.warning => AppColors.noticeBackground,
      NoticeStyle.info => AppColors.tipBackground,
    };

    final iconColor = switch (style) {
      NoticeStyle.warning => AppColors.dark,
      NoticeStyle.info => AppColors.green,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: AppSpacing.iconSizeSmall),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.dark, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
