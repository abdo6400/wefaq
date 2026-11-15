import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/app_theme.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/favorites/data/favorites_storage.dart';
import 'package:wefaq/features/favorites/domain/models/favorite_question_item.dart';
import 'package:wefaq/features/favorites/presentation/favorites_screen.dart';
import 'package:wefaq/features/sessions/data/in_memory_question_repository.dart';
import 'package:wefaq/features/sessions/data/question_history_storage.dart';
import 'package:wefaq/features/sessions/domain/models/question.dart';
import 'package:wefaq/features/sessions/session_screen.dart';

Widget createTestApp(Widget home) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.light,
    home: home,
  );
}

void main() {
  group('FavoriteQuestionItem Model', () {
    test('serializes and deserializes accurately', () {
      final now = DateTime.now().toUtc();
      final original = FavoriteQuestionItem(
        questionId: 'comm-intro-1',
        savedAt: now,
      );

      final json = original.toJson();
      final restored = FavoriteQuestionItem.fromJson(json);

      expect(restored.questionId, 'comm-intro-1');
      expect(
        restored.savedAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('rejects empty questionId in fromJson', () {
      expect(
        () => FavoriteQuestionItem.fromJson(const {'questionId': ''}),
        throwsFormatException,
      );
    });
  });

  group('FileFavoritesStorage Invariants', () {
    late Directory tempDir;
    late File testFile;
    late FileFavoritesStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wefaq_fav_test_');
      testFile = File('${tempDir.path}/favorites.json');
      storage = FileFavoritesStorage(storageFile: testFile);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('starts with empty list when file does not exist', () async {
      expect(await storage.getFavorites(), isEmpty);
      expect(await storage.isFavorite('q1'), isFalse);
    });

    test('toggles favorite on and off atomically', () async {
      final added = await storage.toggleFavorite('comm-intro-1');
      expect(added, isTrue);
      expect(await storage.isFavorite('comm-intro-1'), isTrue);

      final removed = await storage.toggleFavorite('comm-intro-1');
      expect(removed, isFalse);
      expect(await storage.isFavorite('comm-intro-1'), isFalse);
    });

    test('preserves corrupt favorites and reports failure', () async {
      await testFile.writeAsString('{not valid json}');
      await expectLater(storage.getFavorites(), throwsFormatException);
      expect(await testFile.readAsString(), '{not valid json}');
    });
  });

  group('QuestionHistoryStorage & Anti-Repetition', () {
    test('tracks asked questions within max window', () async {
      final storage = InMemoryQuestionHistoryStorage();
      expect(await storage.getRecentlyAskedIds(), isEmpty);

      await storage.recordAskedQuestions(['q1', 'q2']);
      expect(await storage.getRecentlyAskedIds(), containsAll(['q1', 'q2']));

      await storage.clearHistory();
      expect(await storage.getRecentlyAskedIds(), isEmpty);
    });

    test('InMemoryQuestionRepository prioritizes unseen questions', () async {
      final repo = InMemoryQuestionRepository();

      // All 3 communication introductory questions
      final all = repo.getQuestionsSync(
        topic: Topic.communication,
        depth: Depth.introductory,
      );
      final firstTwoIds = {all[0].id, all[1].id};

      // Request 1 question while excluding first 2
      final result = await repo.queryQuestions(
        QuestionFilter(
          topic: Topic.communication,
          depth: Depth.introductory,
          limit: 1,
          excludeQuestionIds: firstTwoIds,
        ),
      );

      expect(result.questions.length, 1);
      // Must be the unseen third question!
      expect(result.questions.first.id, all[2].id);
    });

    test(
      'supplements from seen pool when unseen is fewer than limit',
      () async {
        final repo = InMemoryQuestionRepository();
        final all = repo.getQuestionsSync(
          topic: Topic.communication,
          depth: Depth.introductory,
        );
        final allIds = all.map((q) => q.id).toSet();

        // Request 2 questions even though all 3 have been seen
        final result = await repo.queryQuestions(
          QuestionFilter(
            topic: Topic.communication,
            depth: Depth.introductory,
            limit: 2,
            excludeQuestionIds: allIds,
          ),
        );

        // Successfully returns 2 questions by cycling
        expect(result.questions.length, 2);
      },
    );

    test('supports mixed topics query when topic is null', () async {
      final repo = InMemoryQuestionRepository();
      final result = await repo.queryQuestions(
        const QuestionFilter(
          topic: null, // Mixed topics
          depth: Depth.introductory,
          limit: 6,
        ),
      );

      expect(result.totalAvailable, 15); // 3 per topic * 5 topics
      expect(result.questions.length, 6);
    });
  });

  group('Favorites UI & In-Session Bookmarking', () {
    late InMemoryFavoritesStorage favStorage;

    setUp(() {
      favStorage = InMemoryFavoritesStorage();
    });

    testWidgets(
      'FavoritesScreen shows empty guidance when no favorites exist',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(FavoritesScreen(storage: favStorage)),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.favoritesTitle), findsAtLeastNWidgets(1));
        expect(find.text(AppStrings.emptyFavoritesMessage), findsOneWidget);
      },
    );

    testWidgets(
      'FavoritesScreen renders saved favorite card and removes on tap',
      (tester) async {
        await favStorage.toggleFavorite('comm-intro-1');

        await tester.pumpWidget(
          createTestApp(FavoritesScreen(storage: favStorage)),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('إيه اللي بيساعدك تتكلم براحة عن يومك؟'),
          findsOneWidget,
        );

        // Tap remove button
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        expect(await favStorage.isFavorite('comm-intro-1'), isFalse);
        expect(find.text(AppStrings.emptyFavoritesMessage), findsOneWidget);
      },
    );

    testWidgets('SessionScreen toggles favorite on star icon press', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          SessionScreen(
            questions: const ['سؤال تجريبي للاختبار'],
            questionIds: const ['comm-intro-1'],
            mode: ConversationMode.together,
            favoritesStorage: favStorage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(await favStorage.isFavorite('comm-intro-1'), isFalse);

      // Tap star to favorite
      await tester.tap(find.byIcon(Icons.star_border_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(await favStorage.isFavorite('comm-intro-1'), isTrue);

      // Tap again to un-favorite
      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(await favStorage.isFavorite('comm-intro-1'), isFalse);
    });
  });
}
