import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/activities/data/in_memory_activity_repository.dart';
import 'package:wefaq/features/activities/domain/models/activity.dart';
import 'package:wefaq/features/sessions/domain/models/question.dart';

void main() {
  group('Content Catalog Integrity & Audit (questions_v1.json)', () {
    late Map<String, dynamic> catalogJson;
    late List<dynamic> questionsList;

    setUpAll(() async {
      final file = File('assets/content/questions_v1.json');
      expect(
        await file.exists(),
        isTrue,
        reason: 'Catalog file must exist on disk',
      );
      final content = await file.readAsString();
      catalogJson = jsonDecode(content) as Map<String, dynamic>;
      questionsList = catalogJson['questions'] as List<dynamic>;
    });

    test(
      'catalog schema version is 1 and questions count meets pilot baseline',
      () {
        expect(catalogJson['version'], 1);
        expect(questionsList.length, 600);
      },
    );

    test('all question IDs are unique and well-formatted', () {
      final seenIds = <String>{};
      for (final item in questionsList) {
        final q = item as Map<String, dynamic>;
        final id = q['id'] as String;
        expect(id.trim(), isNotEmpty);
        expect(
          seenIds.contains(id),
          isFalse,
          reason: 'Duplicate ID detected: $id',
        );
        seenIds.add(id);
      }
    });

    test(
      'all questions have text, clarifications, and are development-only',
      () {
        for (final item in questionsList) {
          final q = item as Map<String, dynamic>;
          final text = q['text'] as String?;
          final clarification = q['clarification'] as String?;
          final isDev = q['isDevelopmentOnly'] as bool?;

          expect(
            text?.trim(),
            isNotEmpty,
            reason: 'Question text must not be empty',
          );
          expect(
            clarification?.trim(),
            isNotEmpty,
            reason: 'Clarification guide must exist',
          );
          expect(
            isDev,
            isTrue,
            reason: 'Unapproved questions must have isDevelopmentOnly=true',
          );
        }
      },
    );

    test('maintains strict domain balance (120 questions per topic)', () {
      final counts = <String, int>{};
      for (final item in questionsList) {
        final q = item as Map<String, dynamic>;
        final topic = q['topic'] as String;
        counts[topic] = (counts[topic] ?? 0) + 1;
      }

      expect(counts['communication'], 120);
      expect(counts['dailyLife'], 120);
      expect(counts['familyRelations'], 120);
      expect(counts['finances'], 120);
      expect(counts['coreValues'], 120);
    });

    test(
      'maintains 50/50 depth distribution between introductory and deeper',
      () {
        int introCount = 0;
        int deeperCount = 0;
        for (final item in questionsList) {
          final q = item as Map<String, dynamic>;
          final depth = q['depth'] as String;
          if (depth == 'introductory') introCount++;
          if (depth == 'deeper') deeperCount++;
        }

        expect(introCount, 300);
        expect(deeperCount, 300);
      },
    );

    test('all questions support both together and phone modes', () {
      for (final item in questionsList) {
        final q = item as Map<String, dynamic>;
        final modes = (q['suitableModes'] as List<dynamic>)
            .map((m) => m.toString())
            .toSet();
        expect(modes, contains('together'));
        expect(modes, contains('phone'));
      }
    });
  });

  group('Activities Catalog Invariants (InMemoryActivityRepository)', () {
    final activities = InMemoryActivityRepository.prototypes;

    test('contains 10 rich prototype activities', () {
      expect(activities.length, 10);
    });

    test('all activity IDs are unique and marked as development-only', () {
      final seenIds = <String>{};
      for (final act in activities) {
        expect(act.id.trim(), isNotEmpty);
        expect(
          seenIds.contains(act.id),
          isFalse,
          reason: 'Duplicate activity ID: ${act.id}',
        );
        expect(act.isDevelopmentOnly, isTrue);
        seenIds.add(act.id);
      }
    });

    test(
      'covers all 5 topics and both scenario and priorityOrdering types',
      () {
        final topics = activities.map((a) => a.topic).toSet();
        expect(topics, contains(Topic.communication));
        expect(topics, contains(Topic.dailyLife));
        expect(topics, contains(Topic.familyRelations));
        expect(topics, contains(Topic.finances));
        expect(topics, contains(Topic.coreValues));

        final types = activities.map((a) => a.type).toSet();
        expect(types, contains(ActivityType.scenario));
        expect(types, contains(ActivityType.priorityOrdering));
      },
    );
  });
}
