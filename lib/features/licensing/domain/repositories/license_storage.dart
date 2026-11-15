import '../models/license_entitlement.dart';

abstract class LicenseStorage {
  Future<LicenseEntitlement?> readLicense();
  Future<void> writeLicense(LicenseEntitlement entitlement);
  Future<void> clearLicense();
}
