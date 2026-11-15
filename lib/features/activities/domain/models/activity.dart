import '../../../sessions/session_data.dart';

/// Supported types of interactive discussion activities.
enum ActivityType {
  /// A situational real-world story followed by reflection questions.
  scenario,

  /// A collection of discussion concepts to reflect on and rank priorities mutually.
  priorityOrdering,
}

/// A structured conversational activity designed for couples to explore together.
///
/// In accordance with Wefaq privacy guidelines, activities do not capture or
/// store user answers, rankings, or audio.
class Activity {
  const Activity({
    required this.id,
    required this.type,
    required this.topic,
    required this.title,
    required this.situation,
    this.prompts = const <String>[],
    this.options = const <String>[],
    this.isDevelopmentOnly = true,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.trim().isEmpty) {
      throw const FormatException('Activity id must be a non-empty string');
    }

    final typeRaw = json['type'] as String?;
    final type = ActivityType.values.firstWhere(
      (t) => t.name == typeRaw,
      orElse: () => ActivityType.scenario,
    );

    final topicRaw = json['topic'] as String?;
    final topic = Topic.values.firstWhere(
      (t) => t.name == topicRaw,
      orElse: () => Topic.communication,
    );

    final title = json['title'] as String? ?? '';
    final situation = json['situation'] as String? ?? '';
    final promptsRaw = json['prompts'] as List<dynamic>? ?? const [];
    final prompts = promptsRaw.map((e) => e.toString()).toList();

    final optionsRaw = json['options'] as List<dynamic>? ?? const [];
    final options = optionsRaw.map((e) => e.toString()).toList();

    final isDevelopmentOnly = json['isDevelopmentOnly'] as bool? ?? true;

    return Activity(
      id: id,
      type: type,
      topic: topic,
      title: title,
      situation: situation,
      prompts: prompts,
      options: options,
      isDevelopmentOnly: isDevelopmentOnly,
    );
  }

  final String id;
  final ActivityType type;
  final Topic topic;
  final String title;
  final String situation;
  final List<String> prompts;
  final List<String> options;
  final bool isDevelopmentOnly;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'topic': topic.name,
    'title': title,
    'situation': situation,
    if (prompts.isNotEmpty) 'prompts': prompts,
    if (options.isNotEmpty) 'options': options,
    'isDevelopmentOnly': isDevelopmentOnly,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Activity(id: $id, type: ${type.name}, title: $title)';
}
