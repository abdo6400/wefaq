import '../../../../core/strings/app_strings.dart';

enum ConversationMode { together, phone }

enum Topic { communication, dailyLife, familyRelations, finances, coreValues }

enum Depth { introductory, deeper }

extension ModeLabel on ConversationMode {
  String get label => switch (this) {
    ConversationMode.together => AppStrings.modeTogetherTitle,
    ConversationMode.phone => AppStrings.modePhoneTitle,
  };
}

extension TopicLabel on Topic {
  String get label => switch (this) {
    Topic.communication => AppStrings.topicCommunication,
    Topic.dailyLife => AppStrings.topicDailyLife,
    Topic.familyRelations => AppStrings.topicFamilyRelations,
    Topic.finances => AppStrings.topicFinances,
    Topic.coreValues => AppStrings.topicValues,
  };
}

extension DepthLabel on Depth {
  String get label => switch (this) {
    Depth.introductory => AppStrings.depthIntroductory,
    Depth.deeper => AppStrings.depthDeeper,
  };
}

/// A strongly typed domain model for discussion questions.
///
/// Unreviewed questions must always have [isDevelopmentOnly] set to true.
class Question {
  const Question({
    required this.id,
    required this.text,
    required this.topic,
    required this.depth,
    this.suitableModes = const {
      ConversationMode.together,
      ConversationMode.phone,
    },
    this.isDevelopmentOnly = true,
    this.clarification,
  });

  final String id;
  final String text;
  final Topic topic;
  final Depth depth;
  final Set<ConversationMode> suitableModes;
  final bool isDevelopmentOnly;
  final String? clarification;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Question(id: $id, topic: $topic, depth: $depth)';

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'topic': topic.name,
    'depth': depth.name,
    'suitableModes': suitableModes.map((m) => m.name).toList(),
    'isDevelopmentOnly': isDevelopmentOnly,
    if (clarification != null) 'clarification': clarification,
  };

  factory Question.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final text = json['text'] as String? ?? '';
    final topicName = json['topic'] as String? ?? '';
    final depthName = json['depth'] as String? ?? '';
    final isDev = json['isDevelopmentOnly'] as bool? ?? true;
    final clarification = json['clarification'] as String?;

    final topic = Topic.values.firstWhere(
      (t) => t.name == topicName,
      orElse: () => Topic.communication,
    );
    final depth = Depth.values.firstWhere(
      (d) => d.name == depthName,
      orElse: () => Depth.introductory,
    );

    final rawModes = json['suitableModes'] as List<dynamic>?;
    final modes = rawModes != null
        ? rawModes
              .map(
                (m) => ConversationMode.values.firstWhere(
                  (val) => val.name == m.toString(),
                  orElse: () => ConversationMode.together,
                ),
              )
              .toSet()
        : const {ConversationMode.together, ConversationMode.phone};

    if (id.isEmpty || text.isEmpty) {
      throw const FormatException('Invalid question payload');
    }

    return Question(
      id: id,
      text: text,
      topic: topic,
      depth: depth,
      suitableModes: modes,
      isDevelopmentOnly: isDev,
      clarification: clarification,
    );
  }
}

/// Specification filter for querying available questions.
class QuestionFilter {
  const QuestionFilter({
    this.topic,
    required this.depth,
    this.mode,
    this.limit,
    this.excludeQuestionIds = const {},
  });

  final Topic? topic;
  final Depth depth;
  final ConversationMode? mode;
  final int? limit;
  final Set<String> excludeQuestionIds;
}

/// Explicit result of a question query, guaranteeing transparency on available counts.
class QuestionQueryResult {
  const QuestionQueryResult({
    required this.questions,
    required this.totalAvailable,
  });

  final List<Question> questions;
  final int totalAvailable;

  bool get isEmpty => questions.isEmpty;
  bool get hasFewerThanRequested => questions.length < totalAvailable;
}
