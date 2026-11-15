import 'dart:math';

import '../domain/models/activation_result.dart';
import '../domain/models/license_entitlement.dart';

class _ServerLicenseRecord {
  _ServerLicenseRecord({
    required this.licenseId,
    required this.planName,
    required this.totalQuota,
    required this.remainingQuota,
    required this.expiresAt,
    required this.code,
    this.slot1InstallationId,
    this.slot2InstallationId,
    this.isRevoked = false,
  });

  final String licenseId;
  final String planName;
  final int totalQuota;
  int remainingQuota;
  final DateTime expiresAt;
  final String code;
  String? slot1InstallationId;
  String? slot2InstallationId;
  bool isRevoked;

  // Idempotency ledger: idempotencyKey -> sessionToken
  final Map<String, String> sessionLedger = {};
}

/// Simulated authority verifying ADR 0002 licensing invariants.
///
/// Models transactional slot reservation (max 2 devices) and idempotent
/// session quota ledger consumption.
class MockLicenseServer {
  MockLicenseServer() {
    _seedDefaultLicenses();
  }

  final Map<String, _ServerLicenseRecord> _recordsByCode = {};

  void _seedDefaultLicenses() {
    // Normal 2-device couple license
    _recordsByCode['WFQ-COUPLE-2026'] = _ServerLicenseRecord(
      licenseId: 'lic_couple_2026',
      planName: 'باقة وفاق للمخطوبين (جهازين - 20 جلسة)',
      totalQuota: 20,
      remainingQuota: 20,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 180)),
      code: 'WFQ-COUPLE-2026',
    );

    // Expired license
    _recordsByCode['WFQ-EXPIRED-TEST'] = _ServerLicenseRecord(
      licenseId: 'lic_expired_test',
      planName: 'باقة منتهية الصلاحية',
      totalQuota: 10,
      remainingQuota: 5,
      expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      code: 'WFQ-EXPIRED-TEST',
    );

    // Exhausted slots license (both slots pre-occupied)
    _recordsByCode['WFQ-SLOTS-FULL'] = _ServerLicenseRecord(
      licenseId: 'lic_slots_full',
      planName: 'باقة مكتملة الأجهزة',
      totalQuota: 10,
      remainingQuota: 10,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 90)),
      code: 'WFQ-SLOTS-FULL',
      slot1InstallationId: 'inst_device_alpha_111',
      slot2InstallationId: 'inst_device_beta_222',
    );

    // Revoked license
    _recordsByCode['WFQ-REVOKED-TEST'] = _ServerLicenseRecord(
      licenseId: 'lic_revoked_test',
      planName: 'باقة ملغاة',
      totalQuota: 10,
      remainingQuota: 10,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      code: 'WFQ-REVOKED-TEST',
      isRevoked: true,
    );
  }

  /// Registers or redeems an activation code following ADR 0002 slot policy.
  Future<ActivationResult> redeemCode({
    required String code,
    required String installationId,
    required String publicKey,
  }) async {
    final cleanCode = code.trim().toUpperCase().replaceAll('-', '');
    final match = _recordsByCode.values.firstWhere(
      (r) => r.code.replaceAll('-', '') == cleanCode,
      orElse: () => _ServerLicenseRecord(
        licenseId: '',
        planName: '',
        totalQuota: 0,
        remainingQuota: 0,
        expiresAt: DateTime.now(),
        code: '',
      ),
    );

    if (match.licenseId.isEmpty) {
      return ActivationResult.failure(ActivationErrorCode.invalidCode);
    }

    if (match.isRevoked) {
      return ActivationResult.failure(ActivationErrorCode.revoked);
    }

    if (DateTime.now().toUtc().isAfter(match.expiresAt)) {
      return ActivationResult.failure(ActivationErrorCode.expiredCode);
    }

    // Check slot binding
    int assignedSlot;
    if (match.slot1InstallationId == installationId) {
      assignedSlot = 1;
    } else if (match.slot2InstallationId == installationId) {
      assignedSlot = 2;
    } else if (match.slot1InstallationId == null) {
      match.slot1InstallationId = installationId;
      assignedSlot = 1;
    } else if (match.slot2InstallationId == null) {
      match.slot2InstallationId = installationId;
      assignedSlot = 2;
    } else {
      // Both slots occupied by other devices
      return ActivationResult.failure(ActivationErrorCode.slotsExhausted);
    }

    final entitlement = LicenseEntitlement(
      licenseId: match.licenseId,
      status: match.remainingQuota > 0
          ? EntitlementStatus.active
          : EntitlementStatus.quotaExhausted,
      planName: match.planName,
      totalQuota: match.totalQuota,
      remainingQuota: match.remainingQuota,
      authorizedSlots: 2,
      assignedSlot: assignedSlot,
      expiresAt: match.expiresAt,
    );

    return ActivationResult.success(entitlement);
  }

  /// Consumes one session atomically with idempotency protection.
  Future<String?> consumeSessionQuota({
    required String licenseId,
    required String installationId,
    required String idempotencyKey,
  }) async {
    final record = _recordsByCode.values.firstWhere(
      (r) => r.licenseId == licenseId,
      orElse: () => _ServerLicenseRecord(
        licenseId: '',
        planName: '',
        totalQuota: 0,
        remainingQuota: 0,
        expiresAt: DateTime.now(),
        code: '',
      ),
    );

    if (record.licenseId.isEmpty || record.isRevoked) return null;

    // Idempotency check: if this idempotency key was already recorded, return existing token
    if (record.sessionLedger.containsKey(idempotencyKey)) {
      return record.sessionLedger[idempotencyKey];
    }

    if (record.remainingQuota <= 0) return null;

    record.remainingQuota -= 1;
    final sessionToken =
        'st_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    record.sessionLedger[idempotencyKey] = sessionToken;
    return sessionToken;
  }
}
