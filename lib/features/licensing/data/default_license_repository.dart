import '../domain/models/activation_result.dart';
import '../domain/models/installation_identity.dart';
import '../domain/models/license_entitlement.dart';
import '../domain/repositories/device_identity_storage.dart';
import '../domain/repositories/license_repository.dart';
import '../domain/repositories/license_storage.dart';
import 'device_identity_storage.dart';
import 'license_storage.dart';
import 'mock_license_server.dart';

class DefaultLicenseRepository implements LicenseRepository {
  DefaultLicenseRepository({
    LicenseStorage? licenseStorage,
    DeviceIdentityStorage? identityStorage,
    MockLicenseServer? server,
  }) : _licenseStorage = licenseStorage ?? InMemoryLicenseStorage(),
       _identityStorage = identityStorage ?? InMemoryDeviceIdentityStorage(),
       _server = server ?? MockLicenseServer();

  final LicenseStorage _licenseStorage;
  final DeviceIdentityStorage _identityStorage;
  final MockLicenseServer _server;

  InstallationIdentity? _cachedIdentity;

  @override
  Future<InstallationIdentity> getInstallationIdentity() async {
    if (_cachedIdentity != null) return _cachedIdentity!;

    var stored = await _identityStorage.readIdentity();
    if (stored == null) {
      stored = InstallationIdentity.generate();
      await _identityStorage.writeIdentity(stored);
    }
    _cachedIdentity = stored;
    return stored;
  }

  @override
  Future<LicenseEntitlement> getEntitlement() async {
    final stored = await _licenseStorage.readLicense();
    if (stored != null) {
      return stored;
    }
    // Return default complimentary trial
    final trial = LicenseEntitlement.trial();
    await _licenseStorage.writeLicense(trial);
    return trial;
  }

  @override
  Future<ActivationResult> activateCode(String code) async {
    final identity = await getInstallationIdentity();
    final result = await _server.redeemCode(
      code: code,
      installationId: identity.installationId,
      publicKey: identity.publicKey,
    );

    if (result.isSuccess && result.entitlement != null) {
      await _licenseStorage.writeLicense(result.entitlement!);
    }
    return result;
  }

  @override
  Future<bool> consumeSessionQuota(String idempotencyKey) async {
    final current = await getEntitlement();
    if (!current.canStartSession()) {
      return false;
    }

    if (current.status == EntitlementStatus.trial) {
      final updated = current.copyWith(
        remainingQuota: current.remainingQuota - 1,
        status: current.remainingQuota - 1 <= 0
            ? EntitlementStatus.quotaExhausted
            : EntitlementStatus.trial,
      );
      await _licenseStorage.writeLicense(updated);
      return true;
    }

    // Active subscription: transact with license server
    final identity = await getInstallationIdentity();
    final sessionToken = await _server.consumeSessionQuota(
      licenseId: current.licenseId,
      installationId: identity.installationId,
      idempotencyKey: idempotencyKey,
    );

    if (sessionToken == null) {
      final updated = current.copyWith(
        status: EntitlementStatus.quotaExhausted,
      );
      await _licenseStorage.writeLicense(updated);
      return false;
    }

    final updated = current.copyWith(
      remainingQuota: current.remainingQuota > 0
          ? current.remainingQuota - 1
          : 0,
      status: current.remainingQuota - 1 <= 0
          ? EntitlementStatus.quotaExhausted
          : EntitlementStatus.active,
    );
    await _licenseStorage.writeLicense(updated);
    return true;
  }
}
