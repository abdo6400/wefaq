import 'dart:convert';
import 'dart:io';

import '../domain/models/license_entitlement.dart';
import '../domain/repositories/license_storage.dart';

class InMemoryLicenseStorage implements LicenseStorage {
  LicenseEntitlement? _entitlement;

  @override
  Future<LicenseEntitlement?> readLicense() async => _entitlement;

  @override
  Future<void> writeLicense(LicenseEntitlement entitlement) async {
    _entitlement = entitlement;
  }

  @override
  Future<void> clearLicense() async {
    _entitlement = null;
  }
}

class FileLicenseStorage implements LicenseStorage {
  FileLicenseStorage({required this.storageFile});

  final File storageFile;

  @override
  Future<LicenseEntitlement?> readLicense() async {
    try {
      if (!await storageFile.exists()) {
        return null;
      }
      final raw = await storageFile.readAsString();
      if (raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _safeDeleteFile();
        return null;
      }
      return LicenseEntitlement.fromJson(decoded);
    } catch (_) {
      await _safeDeleteFile();
      return null;
    }
  }

  @override
  Future<void> writeLicense(LicenseEntitlement entitlement) async {
    final parentDir = storageFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final tempFile = File('${storageFile.path}.tmp');
    final payload = jsonEncode(entitlement.toJson());

    await tempFile.writeAsString(payload, flush: true);
    if (await storageFile.exists()) {
      await storageFile.delete();
    }
    await tempFile.rename(storageFile.path);
  }

  @override
  Future<void> clearLicense() async {
    await _safeDeleteFile();
  }

  Future<void> _safeDeleteFile() async {
    try {
      if (await storageFile.exists()) {
        await storageFile.delete();
      }
    } catch (_) {}
  }
}
