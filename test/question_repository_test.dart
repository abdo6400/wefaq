import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/sessions/data/in_memory_question_repository.dart';
import 'package:wefaq/features/sessions/domain/models/question.dart';
import 'package:wefaq/features/sessions/domain/models/session_progress.dart';

void main() {
  group('Question Model & Prototype Data', () {
    test('all prototype questions are explicitly marked as development only', () {
      expect(prototypeQuestions, isNotEmpty);
      for (final question in prototypeQuestions) {
        expect(
          question.isDevelopmentOnly,
          isTrue,
          reason:
              'Question ${question.id} must be flagged as development-only until reviewed',
        );
        expect(question.id, isNotEmpty);
        expect(question.text, isNotEmpty);
      }
    });

    test('prototype question IDs are completely unique', () {
      final ids = prototypeQuestions.map((q) => q.id).toSet();
      expect(ids.length, prototypeQuestions.length);
    });

    test('Question equality is based on id', () {
      const q1 = Question(
        id: 'q1',
        text: 'Text A',
        topic: Topic.communication,
        depth: Depth.introductory,
      );
      const q2 = Question(
        id: 'q1',
        text: 'Text B',
        topic: Topic.dailyLife,
        depth: Depth.deeper,
      );
      const q3 = Question(
        id: 'q3',
        text: 'Text A',
        topic: Topic.communication,
        depth: Depth.introductory,
      );

      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
      expect(q1, isNot(equals(q3)));
    });
  });

  group('InMemoryQuestionRepository', () {
    late InMemoryQuestionRepository repository;

    setUp(() {
      repository = InMemoryQuestionRepository(random: Random(42));
    });

    test('filters questions synchronously by topic and depth', () {
      final commIntro = repository.getQuestionsSync(
        topic: Topic.communication,
        depth: Depth.introductory,
      );
      expect(commIntro.length, 3);
      for (final q in commIntro) {
        expect(q.topic, Topic.communication);
        expect(q.depth, Depth.introductory);
      }

      final dailyDeeper = repository.getQuestionsSync(
        topic: Topic.dailyLife,
        depth: Depth.deeper,
      );
      expect(dailyDeeper.length, 3);
      for (final q in dailyDeeper) {
        expect(q.topic, Topic.dailyLife);
        expect(q.depth, Depth.deeper);
      }
    });

    test(
      'filters questions asynchronously matching synchronous output',
      () async {
        final asyncQuestions = await repository.getQuestions(
          topic: Topic.communication,
          depth: Depth.deeper,
        );
        final syncQuestions = repository.getQuestionsSync(
          topic: Topic.communication,
          depth: Depth.deeper,
        );
        expect(asyncQuestions, equals(syncQuestions));
      },
    );

    test(
      'queryQuestions handles limit and returns accurate QuestionQueryResult',
      () async {
        final result = await repository.queryQuestions(
          const QuestionFilter(
            topic: Topic.communication,
            depth: Depth.introductory,
            limit: 2,
          ),
        );

        expect(result.questions.length, 2);
        expect(result.totalAvailable, 3);
        expect(result.isEmpty, isFalse);
        expect(result.hasFewerThanRequested, isTrue);
      },
    );

    test(
      'handles request when limit exceeds available count gracefully',
      () async {
        final result = await repository.queryQuestions(
          const QuestionFilter(
            topic: Topic.communication,
            depth: Depth.introductory,
            limit: 10,
          ),
        );

        expect(result.questions.length, 3);
        expect(result.totalAvailable, 3);
        expect(result.hasFewerThanRequested, isFalse);
      },
    );

    test(
      'handles zero matching questions cleanly without exceptions',
      () async {
        final emptyRepo = InMemoryQuestionRepository(questions: const []);
        final result = await emptyRepo.queryQuestions(
          const QuestionFilter(
            topic: Topic.communication,
            depth: Depth.introductory,
            limit: 3,
          ),
        );

        expect(result.isEmpty, isTrue);
        expect(result.questions, isEmpty);
        expect(result.totalAvailable, 0);
      },
    );

    test('filters by ConversationMode suitability when specified', () {
      const togetherOnlyQuestion = Question(
        id: 'together-only',
        text: 'Together test',
        topic: Topic.communication,
        depth: Depth.introductory,
        suitableModes: {ConversationMode.together},
      );
      final customRepo = InMemoryQuestionRepository(
        questions: [togetherOnlyQuestion],
      );

      final togetherMatches = customRepo.getQuestionsSync(
        topic: Topic.communication,
        depth: Depth.introductory,
        mode: ConversationMode.together,
      );
      expect(togetherMatches.length, 1);

      final phoneMatches = customRepo.getQuestionsSync(
        topic: Topic.communication,
        depth: Depth.introductory,
        mode: ConversationMode.phone,
      );
      expect(phoneMatches, isEmpty);
    });
  });

  group('SessionProgress Domain Invariants', () {
    test('enforces non-empty questions list on initialization', () {
      expect(() => SessionProgress<String>([]), throwsArgumentError);
      expect(() => SessionProgress<Question>([]), throwsArgumentError);
    });

    test('correctly computes properties through session lifecycle', () {
      final progress = SessionProgress<String>(['Q1', 'Q2', 'Q3']);

      expect(progress.index, 0);
      expect(progress.hasPrevious, isFalse);
      expect(progress.isLastQuestion, isFalse);
      expect(progress.complete, isFalse);
      expect(progress.discussedCount, 3);
      expect(progress.skippedCount, 0);

      // Advance Q1 as discussed
      progress.advance(skipped: false);
      expect(progress.index, 1);
      expect(progress.hasPrevious, isTrue);
      expect(progress.isLastQuestion, isFalse);

      // Advance Q2 as skipped
      progress.advance(skipped: true);
      expect(progress.index, 2);
      expect(progress.isLastQuestion, isTrue);
      expect(progress.skippedCount, 1);
      expect(progress.discussedCount, 2);

      // Go back to Q2 and change to discussed
      progress.previous();
      expect(progress.index, 1);
      progress.advance(skipped: false);
      expect(progress.index, 2);
      expect(progress.skippedCount, 0);
      expect(progress.discussedCount, 3);

      // Complete on last question
      progress.advance(skipped: true);
      expect(progress.complete, isTrue);
      expect(progress.skippedCount, 1);
      expect(progress.discussedCount, 2);

      // Additional calls after completion do not alter state
      progress.advance(skipped: false);
      expect(progress.complete, isTrue);
      expect(progress.skippedCount, 1);

      progress.previous();
      expect(progress.complete, isTrue);
    });
  });
}
