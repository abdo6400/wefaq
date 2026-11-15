import '../models/feedback_report.dart';

abstract class FeedbackStorage {
  Future<void> saveFeedback(FeedbackReport report);
  Future<List<FeedbackReport>> getFeedbackReports();
  Future<void> clearAllFeedback();
}
