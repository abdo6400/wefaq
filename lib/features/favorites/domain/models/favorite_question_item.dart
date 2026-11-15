/// Represents a bookmarked question.
///
/// Under no circumstances does this record store answers, transcripts, or notes.
class FavoriteQuestionItem {
  const FavoriteQuestionItem({required this.questionId, required this.savedAt});

  final String questionId;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'savedAt': savedAt.toIso8601String(),
  };

  factory FavoriteQuestionItem.fromJson(Map<String, dynamic> json) {
    final questionId = json['questionId'] as String? ?? '';
    final rawSavedAt = json['savedAt'] as String?;
    final savedAt = rawSavedAt != null
        ? DateTime.tryParse(rawSavedAt) ?? DateTime.now()
        : DateTime.now();

    if (questionId.isEmpty) {
      throw const FormatException('Invalid favorite item: empty questionId');
    }

    return FavoriteQuestionItem(questionId: questionId, savedAt: savedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteQuestionItem &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId;

  @override
  int get hashCode => questionId.hashCode;
}
