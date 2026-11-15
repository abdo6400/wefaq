/// State of a user or device entitlement.
enum EntitlementStatus {
  /// Unlicensed trial mode with limited complimentary sessions.
  trial,

  /// Active licensed entitlement with available quota and time validity.
  active,

  /// Expired subscription or lease duration.
  expired,

  /// All allotted session quota consumed.
  quotaExhausted,

  /// License revoked or canceled by administrative action.
  revoked,
}

/// Represents the active licensing state and quota for a device installation.
///
/// Adheres to ADR 0002:
/// - Supports 2-device authorized slots for an engaged couple.
/// - Enforces transactional quota accounting.
/// - Validates offline leases against UTC timestamps.
class LicenseEntitlement {
  const LicenseEntitlement({
    required this.licenseId,
    required this.status,
    required this.planName,
    required this.totalQuota,
    required this.remainingQuota,
    this.authorizedSlots = 2,
    this.assignedSlot,
    this.expiresAt,
    this.offlineLeaseToken,
    this.offlineLeaseExpiresAt,
  });

  /// Default trial entitlement provided out-of-the-box for evaluation.
  factory LicenseEntitlement.trial({int remainingQuota = 3}) {
    return LicenseEntitlement(
      licenseId: 'trial_default',
      status: EntitlementStatus.trial,
      planName: 'جلسات تجريبية استكشافية',
      totalQuota: remainingQuota,
      remainingQuota: remainingQuota,
      authorizedSlots: 1,
    );
  }

  factory LicenseEntitlement.fromJson(Map<String, dynamic> json) {
    final licenseId = json['licenseId'] as String? ?? 'trial_default';
    final statusName = json['status'] as String? ?? 'trial';
    final status = EntitlementStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => EntitlementStatus.trial,
    );
    final planName = json['planName'] as String? ?? '';
    final totalQuota = json['totalQuota'] as int? ?? 0;
    final remainingQuota = json['remainingQuota'] as int? ?? 0;
    final authorizedSlots = json['authorizedSlots'] as int? ?? 2;
    final assignedSlot = json['assignedSlot'] as int?;

    final expiresAtRaw = json['expiresAt'] as String?;
    final expiresAt = expiresAtRaw != null
        ? DateTime.tryParse(expiresAtRaw)?.toUtc()
        : null;

    final offlineLeaseToken = json['offlineLeaseToken'] as String?;
    final offlineLeaseExpiresRaw = json['offlineLeaseExpiresAt'] as String?;
    final offlineLeaseExpiresAt = offlineLeaseExpiresRaw != null
        ? DateTime.tryParse(offlineLeaseExpiresRaw)?.toUtc()
        : null;

    return LicenseEntitlement(
      licenseId: licenseId,
      status: status,
      planName: planName,
      totalQuota: totalQuota,
      remainingQuota: remainingQuota,
      authorizedSlots: authorizedSlots,
      assignedSlot: assignedSlot,
      expiresAt: expiresAt,
      offlineLeaseToken: offlineLeaseToken,
      offlineLeaseExpiresAt: offlineLeaseExpiresAt,
    );
  }

  final String licenseId;
  final EntitlementStatus status;
  final String planName;
  final int totalQuota;
  final int remainingQuota;
  final int authorizedSlots;
  final int? assignedSlot;
  final DateTime? expiresAt;
  final String? offlineLeaseToken;
  final DateTime? offlineLeaseExpiresAt;

  /// Whether the installation is currently authorized to initiate a session.
  bool canStartSession([DateTime? currentTime]) {
    final now = (currentTime ?? DateTime.now()).toUtc();

    switch (status) {
      case EntitlementStatus.trial:
        return remainingQuota > 0;
      case EntitlementStatus.active:
        if (expiresAt != null && now.isAfter(expiresAt!)) {
          return false;
        }
        if (remainingQuota <= 0) {
          // Check for valid offline lease
          if (offlineLeaseToken != null &&
              offlineLeaseExpiresAt != null &&
              now.isBefore(offlineLeaseExpiresAt!)) {
            return true;
          }
          return false;
        }
        return true;
      case EntitlementStatus.expired:
      case EntitlementStatus.quotaExhausted:
      case EntitlementStatus.revoked:
        return false;
    }
  }

  LicenseEntitlement copyWith({
    String? licenseId,
    EntitlementStatus? status,
    String? planName,
    int? totalQuota,
    int? remainingQuota,
    int? authorizedSlots,
    int? assignedSlot,
    DateTime? expiresAt,
    String? offlineLeaseToken,
    DateTime? offlineLeaseExpiresAt,
  }) {
    return LicenseEntitlement(
      licenseId: licenseId ?? this.licenseId,
      status: status ?? this.status,
      planName: planName ?? this.planName,
      totalQuota: totalQuota ?? this.totalQuota,
      remainingQuota: remainingQuota ?? this.remainingQuota,
      authorizedSlots: authorizedSlots ?? this.authorizedSlots,
      assignedSlot: assignedSlot ?? this.assignedSlot,
      expiresAt: expiresAt ?? this.expiresAt,
      offlineLeaseToken: offlineLeaseToken ?? this.offlineLeaseToken,
      offlineLeaseExpiresAt:
          offlineLeaseExpiresAt ?? this.offlineLeaseExpiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'licenseId': licenseId,
    'status': status.name,
    'planName': planName,
    'totalQuota': totalQuota,
    'remainingQuota': remainingQuota,
    'authorizedSlots': authorizedSlots,
    if (assignedSlot != null) 'assignedSlot': assignedSlot,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (offlineLeaseToken != null) 'offlineLeaseToken': offlineLeaseToken,
    if (offlineLeaseExpiresAt != null)
      'offlineLeaseExpiresAt': offlineLeaseExpiresAt!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LicenseEntitlement &&
          runtimeType == other.runtimeType &&
          licenseId == other.licenseId &&
          status == other.status &&
          remainingQuota == other.remainingQuota &&
          assignedSlot == other.assignedSlot;

  @override
  int get hashCode =>
      Object.hash(licenseId, status, remainingQuota, assignedSlot);
}
