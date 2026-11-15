import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/sessions/data/json_asset_question_repository.dart';
import 'package:wefaq/features/sessions/domain/models/question.dart';

void main() {
  group('Question JSON Model', () {
    test('Question toJson and fromJson preserve all domain attributes', () {
      const original = Question(
        id: 'test-1',
        text: 'هل تفضل الحوار المباشر؟',
        clarification: 'استيضاح أسلوب الحوار',
        topic: Topic.communication,
        depth: Depth.introductory,
        suitableModes: {ConversationMode.together},
        isDevelopmentOnly: true,
      );

      final json = original.toJson();
      final restored = Question.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.clarification, original.clarification);
      expect(restored.topic, original.topic);
      expect(restored.depth, original.depth);
      expect(restored.suitableModes, original.suitableModes);
      expect(restored.isDevelopmentOnly, isTrue);
    });

    test('validates physical file assets/content/questions_v1.json exists and is valid', () async {
      final file = File('assets/content/questions_v1.json');
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;

      expect(decoded['version'], 1);
      final rawQuestions = decoded['questions'] as List<dynamic>;
      expect(rawQuestions.length, 600);

      for (final item in rawQuestions) {
        final parsed = Question.fromJson(item as Map<String, dynamic>);
        expect(parsed.id, isNotEmpty);
        expect(parsed.text, isNotEmpty);
        expect(parsed.isDevelopmentOnly, isTrue);
      }
    });
  });

  group('JsonAssetQuestionRepository', () {
    test(
      'loads questions from custom string loader and caches results',
      () async {
        int loadCount = 0;
        final repo = JsonAssetQuestionRepository(
          customLoader: () async {
            loadCount++;
            return jsonEncode({
              'version': 1,
              'questions': [
                {
                  'id': 'mock-1',
                  'text': 'Mock Question 1',
                  'topic': 'communication',
                  'depth': 'introductory',
                },
                {
                  'id': 'mock-2',
                  'text': 'Mock Question 2',
                  'topic': 'dailyLife',
                  'depth': 'deeper',
                },
              ],
            });
          },
        );

        final questions = await repo.loadQuestions();
        expect(questions.length, 2);
        expect(loadCount, 1);

        // Second call uses cache without re-invoking loader
        final cached = await repo.loadQuestions();
        expect(cached.length, 2);
        expect(loadCount, 1);
      },
    );

    test(
      'falls back gracefully to prototype questions on corrupt loader payload',
      () async {
        final repo = JsonAssetQuestionRepository(
          customLoader: () async => 'MALFORMED_NON_JSON',
        );

        final questions = await repo.loadQuestions();
        expect(questions, isNotEmpty);
        expect(
          questions.length,
          30,
        ); // prototype fallback (5 topics * 6 questions)
      },
    );

    test(
      'queryQuestions filters loaded questions with anti-repetition',
      () async {
        final repo = JsonAssetQuestionRepository(
          customLoader: () async => jsonEncode({
            'version': 1,
            'questions': [
              {
                'id': 'q1',
                'text': 'Question 1',
                'topic': 'communication',
                'depth': 'introductory',
              },
              {
                'id': 'q2',
                'text': 'Question 2',
                'topic': 'communication',
                'depth': 'introductory',
              },
            ],
          }),
        );

        final result = await repo.queryQuestions(
          const QuestionFilter(
            topic: Topic.communication,
            depth: Depth.introductory,
            limit: 1,
            excludeQuestionIds: {'q1'},
          ),
        );

        expect(result.questions.length, 1);
        expect(result.questions.first.id, 'q2');
      },
    );
  });
}
