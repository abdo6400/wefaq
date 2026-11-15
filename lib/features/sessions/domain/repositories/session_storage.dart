import '../models/saved_session_state.dart';

/// Contract for reading, persisting, and discarding interrupted session state.
abstract interface class SessionStorage {
  /// Reads the active interrupted session if one exists.
  Future<SavedSessionState?> readActiveSession();

  /// Atomically persists the active session state.
  Future<void> writeActiveSession(SavedSessionState state);

  /// Clears the saved session state upon explicit finish or abandonment.
  Future<void> clearActiveSession();
}
