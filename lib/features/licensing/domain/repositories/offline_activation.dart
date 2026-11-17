import '../models/offline_license.dart';

class ActivationState {
  const ActivationState({
    required this.installationId,
    this.license,
    this.remaining,
    this.trialStartedAt,
    this.trialEndsAt,
    this.trialExpired = false,
    this.trialClockTampered = false,
  });

  final String installationId;
  final OfflineLicense? license;
  final int? remaining;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final bool trialExpired;
  final bool trialClockTampered;

  bool isTrialActive(DateTime now) {
    if (license != null || trialExpired || trialClockTampered) return false;
    final start = trialStartedAt;
    final end = trialEndsAt;
    if (start == null || end == null) return false;
    final utc = now.toUtc();
    return !utc.isBefore(start) && utc.isBefore(end);
  }

  bool hasLicenseAccess(DateTime now) =>
      license != null && license!.permits(installationId, now);

  bool hasAccess(DateTime now) => hasLicenseAccess(now) || isTrialActive(now);

  bool canStartSession(DateTime now) {
    if (license != null) {
      return license!.permits(installationId, now) &&
          (remaining == null || remaining! > 0);
    }
    return isTrialActive(now);
  }

  int? trialRemainingDays(DateTime now) {
    if (!isTrialActive(now) || trialEndsAt == null) return null;
    final diff = trialEndsAt!.difference(now.toUtc());
    if (diff <= Duration.zero) return 0;
    return (diff.inSeconds / Duration.secondsPerDay).ceil();
  }
}

abstract interface class OfflineActivation {
  bool get isConfigured;
  Future<ActivationState> state();
  Future<OfflineLicense> inspect(String code);
  Future<void> activate(String code);
  Future<bool> reserve(String sessionId);
}
