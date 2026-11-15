import '../models/question.dart';

/// Abstract contract for querying and retrieving discussion questions.
abstract interface class QuestionRepository {
  /// Retrieves eligible questions for given topic (or all topics if omitted) and depth.
  Future<List<Question>> getQuestions({
    Topic? topic,
    required Depth depth,
    ConversationMode? mode,
  });

  /// Queries questions using an explicit filter criteria.
  Future<QuestionQueryResult> queryQuestions(QuestionFilter filter);
}
