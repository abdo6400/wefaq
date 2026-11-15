import 'dart:convert';
import 'dart:io';

import '../domain/models/saved_session_state.dart';
import '../domain/repositories/session_storage.dart';

/// In-memory implementation of [SessionStorage] for testing and runtime fallbacks.
class InMemorySessionStorage implements SessionStorage {
  SavedSessionState? _activeState;

  @override
  Future<SavedSessionState?> readActiveSession() async => _activeState;

  @override
  Future<void> writeActiveSession(SavedSessionState state) async {
    _activeState = state;
  }

  @override
  Future<void> clearActiveSession() async {
    _activeState = null;
  }
}

/// Robust file-backed implementation of [SessionStorage] with atomic writes.
class FileSessionStorage implements SessionStorage {
  FileSessionStorage({required this.storageFile});

  final File storageFile;

  @override
  Future<SavedSessionState?> readActiveSession() async {
    if (!await storageFile.exists()) return null;
    final decoded = jsonDecode(await storageFile.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid session');
    }
    return SavedSessionState.fromJson(decoded);
  }

  @override
  Future<void> writeActiveSession(SavedSessionState state) async {
    await storageFile.parent.create(recursive: true);
    final tempFile = File('${storageFile.path}.tmp');
    await tempFile.writeAsString(jsonEncode(state.toJson()), flush: true);
    await tempFile.rename(storageFile.path);
  }

  @override
  Future<void> clearActiveSession() async {
    if (await storageFile.exists()) await storageFile.delete();
    final tempFile = File('${storageFile.path}.tmp');
    if (await tempFile.exists()) await tempFile.delete();
  }
}
