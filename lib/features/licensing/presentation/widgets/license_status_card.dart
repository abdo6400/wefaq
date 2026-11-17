import 'package:flutter/material.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/wefaq_card.dart';
import '../../domain/models/license_entitlement.dart';
import '../../domain/repositories/license_repository.dart';
import 'activation_sheet.dart';

class LicenseStatusCard extends StatelessWidget {
  const LicenseStatusCard({
    super.key,
    required this.entitlement,
    required this.repository,
    this.onLicenseUpdated,
  });

  final LicenseEntitlement entitlement;
  final LicenseRepository repository;
  final VoidCallback? onLicenseUpdated;

  Future<void> _openActivation(BuildContext context) async {
    final result = await ActivationSheet.show(context, repository: repository);
    if (result != null && result.isSuccess) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.green,
          ),
        );
      }
      onLicenseUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = entitlement.status == EntitlementStatus.active;

    final badgeColor = switch (entitlement.status) {
      EntitlementStatus.active => AppColors.green,
      EntitlementStatus.trial => AppColors.goldText,
      _ => AppColors.muted,
    };

    final badgeBg = switch (entitlement.status) {
      EntitlementStatus.active => AppColors.tagBackground,
      EntitlementStatus.trial => AppColors.iconContainerGold,
      _ => AppColors.progressTrack,
    };

    final statusText = switch (entitlement.status) {
      EntitlementStatus.active => AppStrings.activeStatusLabel,
      EntitlementStatus.trial => AppStrings.trialStatusLabel,
      EntitlementStatus.expired => AppStrings.expiredStatusLabel,
      EntitlementStatus.quotaExhausted => AppStrings.quotaExhaustedStatusLabel,
      EntitlementStatus.revoked => 'ملغى',
    };

    return WefaqCard(
      hasShadow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  isActive ? Icons.verified_outlined : Icons.card_membership,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.licenseStatusTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            entitlement.planName,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.0,
              color: AppColors.dark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${AppStrings.remainingQuotaPrefix} ${entitlement.remainingQuota} من ${entitlement.totalQuota}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.0,
                  color: AppColors.muted,
                ),
              ),
              if (entitlement.assignedSlot != null)
                Text(
                  '(جهاز ${entitlement.assignedSlot} من ${entitlement.authorizedSlots})',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.0,
                    color: AppColors.goldText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _openActivation(context),
            icon: const Icon(Icons.key, size: 18),
            label: const Text(AppStrings.activateCodeButton),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
              side: const BorderSide(color: AppColors.inputBorder),
              textStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
