/// Contract for tracking recently asked question IDs to prevent repeats.
abstract interface class QuestionHistoryStorage {
  /// Retrieves IDs assigned to sessions previously started on this device.
  Future<Set<String>> getRecentlyAskedIds();

  /// Records question IDs assigned to a newly started session.
  Future<void> recordAskedQuestions(List<String> questionIds);

  /// Clears question history.
  Future<void> clearHistory();
}
