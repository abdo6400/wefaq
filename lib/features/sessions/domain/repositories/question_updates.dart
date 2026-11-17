abstract interface class QuestionUpdates {
  bool get isConfigured;

  /// True if a newer catalog was applied, false if already up to date.
  Future<bool> update();
}
