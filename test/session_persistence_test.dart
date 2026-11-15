import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/app_theme.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/home/home_screen.dart';
import 'package:wefaq/features/sessions/data/session_storage.dart';
import 'package:wefaq/features/sessions/data/in_memory_question_repository.dart';
import 'package:wefaq/features/sessions/domain/models/question.dart';
import 'package:wefaq/features/sessions/domain/models/saved_session_state.dart';
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
  group('SavedSessionState Serialization', () {
    test('serializes and deserializes cleanly without losing state', () {
      final now = DateTime.now().toUtc();
      final original = SavedSessionState(
        version: 1,
        sessionId: 'session-123',
        questionIds: const ['comm-intro-1', 'comm-intro-2', 'comm-intro-3'],
        mode: ConversationMode.phone,
        currentIndex: 1,
        skippedIndices: const {0},
        updatedAt: now,
      );

      final json = original.toJson();
      final reconstructed = SavedSessionState.fromJson(json);

      expect(reconstructed.version, 1);
      expect(reconstructed.sessionId, 'session-123');
      expect(reconstructed.questionIds, original.questionIds);
      expect(reconstructed.mode, ConversationMode.phone);
      expect(reconstructed.currentIndex, 1);
      expect(reconstructed.skippedIndices, const {0});
      expect(
        reconstructed.updatedAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('validates payload invariants and rejects invalid session data', () {
      expect(
        () => SavedSessionState.fromJson(const {
          'sessionId': '',
          'questionIds': ['comm-intro-1'],
        }),
        throwsFormatException,
      );

      expect(
        () => SavedSessionState.fromJson(const {
          'sessionId': 'test',
          'questionIds': [],
        }),
        throwsFormatException,
      );
    });

    test('re-clamps out-of-bounds currentIndex safely', () {
      final state = SavedSessionState.fromJson(const {
        'sessionId': 'test',
        'questionIds': ['q1', 'q2'],
        'currentIndex': 99,
      });

      expect(state.currentIndex, 1);
    });
  });

  group('FileSessionStorage Invariants', () {
    late Directory tempDir;
    late File testFile;
    late FileSessionStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wefaq_storage_test_');
      testFile = File('${tempDir.path}/active_session.json');
      storage = FileSessionStorage(storageFile: testFile);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns null when file does not exist', () async {
      final result = await storage.readActiveSession();
      expect(result, isNull);
    });

    test('atomically writes and restores saved session', () async {
      final state = SavedSessionState(
        sessionId: 'atomic-test',
        questionIds: const ['comm-intro-1', 'comm-intro-2'],
        mode: ConversationMode.together,
        currentIndex: 0,
        updatedAt: DateTime.now().toUtc(),
      );

      await storage.writeActiveSession(state);
      expect(await testFile.exists(), isTrue);

      final restored = await storage.readActiveSession();
      expect(restored, isNotNull);
      expect(restored!.sessionId, 'atomic-test');
      expect(restored.questionIds.length, 2);
    });

    test('preserves corrupted session and reports the error', () async {
      await testFile.writeAsString('MALFORMED_NON_JSON_DATA!!!');

      await expectLater(storage.readActiveSession(), throwsFormatException);
      expect(await testFile.exists(), isTrue);
    });

    test('clears file cleanly on clearActiveSession', () async {
      final state = SavedSessionState(
        sessionId: 'clear-test',
        questionIds: const ['comm-intro-1'],
        mode: ConversationMode.together,
        currentIndex: 0,
        updatedAt: DateTime.now().toUtc(),
      );

      await storage.writeActiveSession(state);
      expect(await testFile.exists(), isTrue);

      await storage.clearActiveSession();
      expect(await testFile.exists(), isFalse);
      expect(await storage.readActiveSession(), isNull);
    });
  });

  group('HomeScreen Session Resumption Flows', () {
    late InMemorySessionStorage storage;

    setUp(() {
      storage = InMemorySessionStorage();
    });

    testWidgets('does not show resume card when no active session exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          HomeScreen(
            sessionStorage: storage,
            questionRepository: InMemoryQuestionRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.resumeCardTitle), findsNothing);
      expect(find.text(AppStrings.resumeSessionButton), findsNothing);
    });

    testWidgets('shows resume card and can discard interrupted session', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await storage.writeActiveSession(
        SavedSessionState(
          sessionId: 'saved-1',
          questionIds: const ['comm-intro-1', 'comm-intro-2', 'comm-intro-3'],
          mode: ConversationMode.phone,
          currentIndex: 1,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          HomeScreen(
            sessionStorage: storage,
            questionRepository: InMemoryQuestionRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.resumeCardTitle), findsOneWidget);
      expect(find.text(AppStrings.resumeSessionButton), findsOneWidget);
      expect(find.text('السؤال 2 من 3'), findsOneWidget);

      // Tap Discard
      await tester.tap(find.text(AppStrings.discardSessionButton));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text(AppStrings.discardDialogTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.discardConfirmAction));
      await tester.pumpAndSettle();

      // Card disappears and storage is cleared
      expect(find.text(AppStrings.resumeCardTitle), findsNothing);
      expect(await storage.readActiveSession(), isNull);
    });

    testWidgets('tapping resume restores session at saved question', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await storage.writeActiveSession(
        SavedSessionState(
          sessionId: 'saved-2',
          questionIds: const ['comm-intro-1', 'comm-intro-2'],
          mode: ConversationMode.together,
          currentIndex: 1,
          skippedIndices: const {0},
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          HomeScreen(
            sessionStorage: storage,
            questionRepository: InMemoryQuestionRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.resumeSessionButton));
      await tester.pumpAndSettle();

      // Session screen opens at question 2 of 2
      expect(find.text(AppStrings.questionProgress(2, 2)), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(AppStrings.finishSessionButton),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(AppStrings.finishSessionButton), findsOneWidget);
      await tester.ensureVisible(find.text(AppStrings.finishSessionButton));
      await tester.pumpAndSettle();

      // Finish session
      await tester.tap(find.text(AppStrings.finishSessionButton));
      await tester.pumpAndSettle();

      // Result summary displayed
      expect(find.text(AppStrings.sessionFinishedTitle), findsOneWidget);

      // Storage cleared
      expect(await storage.readActiveSession(), isNull);
    });

    testWidgets('SessionScreen persists state upon advancing', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          SessionScreen(
            questions: const ['سؤال 1', 'سؤال 2'],
            mode: ConversationMode.together,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially persisted
      var active = await storage.readActiveSession();
      expect(active, isNotNull);
      expect(active!.currentIndex, 0);

      // Advance
      await tester.tap(find.text(AppStrings.nextButton));
      await tester.pumpAndSettle();

      active = await storage.readActiveSession();
      expect(active!.currentIndex, 1);
    });
  });
}
