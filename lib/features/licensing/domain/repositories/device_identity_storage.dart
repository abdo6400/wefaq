import '../models/installation_identity.dart';

abstract class DeviceIdentityStorage {
  Future<InstallationIdentity?> readIdentity();
  Future<void> writeIdentity(InstallationIdentity identity);
}
