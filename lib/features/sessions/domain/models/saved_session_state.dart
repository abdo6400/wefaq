import 'question.dart';

/// Serializable state for resuming an interrupted session locally.
///
/// Under no circumstances does this model store user answers, transcripts,
/// or audio recordings.
class SavedSessionState {
  const SavedSessionState({
    this.version = currentVersion,
    required this.sessionId,
    required this.questionIds,
    required this.mode,
    required this.currentIndex,
    this.skippedIndices = const {},
    required this.updatedAt,
  });

  static const int currentVersion = 1;

  final int version;
  final String sessionId;
  final List<String> questionIds;
  final ConversationMode mode;
  final int currentIndex;
  final Set<int> skippedIndices;
  final DateTime updatedAt;

  bool get isComplete =>
      questionIds.isNotEmpty && currentIndex >= questionIds.length;

  Map<String, dynamic> toJson() => {
    'version': version,
    'sessionId': sessionId,
    'questionIds': questionIds,
    'mode': mode.name,
    'currentIndex': currentIndex,
    'skippedIndices': skippedIndices.toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedSessionState.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    final sessionId = json['sessionId'] as String? ?? '';
    final rawQuestionIds = json['questionIds'] as List<dynamic>? ?? const [];
    final questionIds = rawQuestionIds.map((item) => item.toString()).toList();

    final modeName = json['mode'] as String? ?? ConversationMode.together.name;
    final mode = ConversationMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => ConversationMode.together,
    );

    final currentIndex = json['currentIndex'] as int? ?? 0;
    final rawSkipped = json['skippedIndices'] as List<dynamic>? ?? const [];
    final skippedIndices = rawSkipped
        .whereType<num>()
        .map((n) => n.toInt())
        .toSet();

    final rawUpdatedAt = json['updatedAt'] as String?;
    final updatedAt = rawUpdatedAt != null
        ? DateTime.tryParse(rawUpdatedAt) ?? DateTime.now()
        : DateTime.now();

    if (sessionId.isEmpty || questionIds.isEmpty) {
      throw const FormatException('Invalid saved session payload');
    }

    return SavedSessionState(
      version: version,
      sessionId: sessionId,
      questionIds: questionIds,
      mode: mode,
      currentIndex: currentIndex.clamp(0, questionIds.length - 1),
      skippedIndices: skippedIndices,
      updatedAt: updatedAt,
    );
  }

  SavedSessionState copyWith({
    int? currentIndex,
    Set<int>? skippedIndices,
    DateTime? updatedAt,
  }) {
    return SavedSessionState(
      version: version,
      sessionId: sessionId,
      questionIds: questionIds,
      mode: mode,
      currentIndex: currentIndex ?? this.currentIndex,
      skippedIndices: skippedIndices ?? this.skippedIndices,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
