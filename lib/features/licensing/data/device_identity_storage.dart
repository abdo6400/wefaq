import 'dart:convert';
import 'dart:io';

import '../domain/models/installation_identity.dart';
import '../domain/repositories/device_identity_storage.dart';

class InMemoryDeviceIdentityStorage implements DeviceIdentityStorage {
  InstallationIdentity? _identity;

  @override
  Future<InstallationIdentity?> readIdentity() async => _identity;

  @override
  Future<void> writeIdentity(InstallationIdentity identity) async {
    _identity = identity;
  }
}

class FileDeviceIdentityStorage implements DeviceIdentityStorage {
  FileDeviceIdentityStorage({required this.storageFile});

  final File storageFile;

  @override
  Future<InstallationIdentity?> readIdentity() async {
    try {
      if (!await storageFile.exists()) {
        return null;
      }
      final raw = await storageFile.readAsString();
      if (raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return InstallationIdentity.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeIdentity(InstallationIdentity identity) async {
    final parentDir = storageFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final tempFile = File('${storageFile.path}.tmp');
    final payload = jsonEncode(identity.toJson());

    await tempFile.writeAsString(payload, flush: true);
    if (await storageFile.exists()) {
      await storageFile.delete();
    }
    await tempFile.rename(storageFile.path);
  }
}
