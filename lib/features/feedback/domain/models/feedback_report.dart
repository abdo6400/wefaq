import 'package:flutter/foundation.dart';

enum FeedbackCategory { general, questionClarity, suggestion, bugReport }

extension FeedbackCategoryLabel on FeedbackCategory {
  String get label => switch (this) {
    FeedbackCategory.general => 'انطباع عام',
    FeedbackCategory.questionClarity => 'وضوح الأسئلة',
    FeedbackCategory.suggestion => 'اقتراح تطوير',
    FeedbackCategory.bugReport => 'مشكلة فنية',
  };
}

/// A privacy-first model for beta feedback and question phrasing reports.
///
/// INVARIANT: Never contains conversation answers, transcripts, or personal data.
@immutable
class FeedbackReport {
  const FeedbackReport({
    required this.id,
    required this.category,
    this.rating,
    required this.comment,
    this.questionId,
    this.installationId,
    required this.createdAt,
  });

  final String id;
  final FeedbackCategory category;
  final int? rating;
  final String comment;
  final String? questionId;
  final String? installationId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    if (rating != null) 'rating': rating,
    'comment': comment,
    if (questionId != null) 'questionId': questionId,
    if (installationId != null) 'installationId': installationId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FeedbackReport.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final categoryName = json['category'] as String? ?? '';
    final comment = json['comment'] as String? ?? '';
    final rating = json['rating'] as int?;
    final questionId = json['questionId'] as String?;
    final installationId = json['installationId'] as String?;
    final createdAtStr = json['createdAt'] as String? ?? '';

    if (id.isEmpty || comment.trim().isEmpty) {
      throw const FormatException('Invalid feedback report payload');
    }

    final category = FeedbackCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => FeedbackCategory.general,
    );

    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now().toUtc();

    return FeedbackReport(
      id: id,
      category: category,
      rating: rating,
      comment: comment,
      questionId: questionId,
      installationId: installationId,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackReport &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
