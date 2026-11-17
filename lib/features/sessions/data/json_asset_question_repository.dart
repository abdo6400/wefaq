import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../domain/models/question.dart';
import '../domain/repositories/question_repository.dart';
import 'in_memory_question_repository.dart';

typedef JsonStringLoader = Future<String> Function();

/// Implementation of [QuestionRepository] backed by a versioned JSON asset catalog.
class JsonAssetQuestionRepository implements QuestionRepository {
  JsonAssetQuestionRepository({
    this.assetPath = 'assets/content/questions_v1.json',
    JsonStringLoader? customLoader,
    Random? random,
  }) : _loader = customLoader,
       _random = random ?? Random();

  final String assetPath;
  final JsonStringLoader? _loader;
  final Random _random;

  List<Question>? _cachedQuestions;
  int _generation = 0;

  void invalidateCache() {
    _generation++;
    _cachedQuestions = null;
  }

  /// Loads and caches questions from the JSON asset catalog.
  Future<List<Question>> loadQuestions() async {
    if (_cachedQuestions != null) return _cachedQuestions!;
    final generation = _generation;
    List<Question> loaded;

    try {
      final jsonString = _loader != null
          ? await _loader()
          : await rootBundle.loadString(assetPath);

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        loaded = prototypeQuestions;
      } else {
        final rawList = decoded['questions'] as List<dynamic>? ?? const [];
        final parsed = <Question>[];

        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            try {
              parsed.add(Question.fromJson(item));
            } catch (_) {
              // Ignore malformed individual bundled question entry.
            }
          }
        }
        loaded = parsed.isNotEmpty ? parsed : prototypeQuestions;
      }
    } catch (_) {
      loaded = prototypeQuestions;
    }
    if (generation != _generation) return loadQuestions();
    _cachedQuestions = loaded;
    return _cachedQuestions!;
  }

  @override
  Future<List<Question>> getQuestions({
    Topic? topic,
    required Depth depth,
    ConversationMode? mode,
  }) async {
    final questions = await loadQuestions();
    return questions.where((q) {
      if (topic != null && q.topic != topic) return false;
      if (q.depth != depth) return false;
      if (mode != null && !q.suitableModes.contains(mode)) return false;
      return true;
    }).toList();
  }

  @override
  Future<QuestionQueryResult> queryQuestions(QuestionFilter filter) async {
    final matched = await getQuestions(
      topic: filter.topic,
      depth: filter.depth,
      mode: filter.mode,
    );

    final total = matched.length;
    if (total == 0) {
      return const QuestionQueryResult(questions: [], totalAvailable: 0);
    }

    final unseen =
        matched.where((q) => !filter.excludeQuestionIds.contains(q.id)).toList()
          ..shuffle(_random);
    final seen =
        matched.where((q) => filter.excludeQuestionIds.contains(q.id)).toList()
          ..shuffle(_random);

    final limit = filter.limit ?? total;
    final targetCount = limit.clamp(0, total);

    final selected = <Question>[...unseen];
    if (selected.length < targetCount) {
      selected.addAll(seen.take(targetCount - selected.length));
    }

    final finalSelection = selected.take(targetCount).toList();

    return QuestionQueryResult(
      questions: finalSelection,
      totalAvailable: total,
    );
  }
}
