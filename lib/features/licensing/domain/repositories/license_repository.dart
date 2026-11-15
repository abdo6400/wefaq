import '../models/activation_result.dart';
import '../models/installation_identity.dart';
import '../models/license_entitlement.dart';

abstract class LicenseRepository {
  /// Fetches the currently stored or active entitlement (defaults to trial if none).
  Future<LicenseEntitlement> getEntitlement();

  /// Redeems an activation code for this device installation.
  Future<ActivationResult> activateCode(String code);

  /// Consumes one session from the remaining quota idempotently using [idempotencyKey].
  ///
  /// Returns `true` if the session was successfully reserved/started, or `false`
  /// if quota is exhausted.
  Future<bool> consumeSessionQuota(String idempotencyKey);

  /// Returns the persistent unique identity of this installation.
  Future<InstallationIdentity> getInstallationIdentity();
}
