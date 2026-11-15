import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/sessions/session_data.dart';
import 'package:wefaq/features/sessions/session_setup_screen.dart';

void main() {
  test('history keeps more than 100 question IDs after restart', () async {
    final dir = await Directory.systemTemp.createTemp('wefaq-history-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/history.json');
    final storage = FileQuestionHistoryStorage(storageFile: file);
    await storage.recordAskedQuestions(List.generate(150, (i) => 'q$i'));
    final restored = await FileQuestionHistoryStorage(storageFile: file)
        .getRecentlyAskedIds();
    expect(restored.length, 150);
    expect(restored, contains('q0'));
  });
  test('corrupted history fails without overwriting the old file', () async {
    final dir = await Directory.systemTemp.createTemp('wefaq-history-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/history.json');
    await file.writeAsString('bad data');
    final storage = FileQuestionHistoryStorage(storageFile: file);
    await expectLater(
      storage.recordAskedQuestions(['q1']),
      throwsFormatException,
    );
    expect(await file.readAsString(), 'bad data');
  });
  testWidgets('quick counts and strict no-repeat handle exhaustion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final items = List.generate(
      12,
      (i) => Question(
        id: 'q$i',
        text: 'Question $i',
        topic: Topic.communication,
        depth: Depth.introductory,
      ),
    );
    final history = InMemoryQuestionHistoryStorage();
    await history.recordAskedQuestions(List.generate(10, (i) => 'q$i'));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SessionSetupScreen(
          repository: InMemoryQuestionRepository(questions: items),
          historyStorage: history,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.quickCount),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '10'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '10')).selected,
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.text(AppStrings.avoidPreviousQuestions),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(AppStrings.avoidPreviousQuestions));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.newQuestionCount(2, 12)), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AppStrings.startSessionButton),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text(AppStrings.startSessionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.startSessionButton));
    await tester.pumpAndSettle();
    expect(await history.getRecentlyAskedIds(), containsAll(['q10', 'q11']));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.exitSessionAction));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.noNewQuestions),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(AppStrings.noNewQuestions), findsOneWidget);
    final start = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, AppStrings.startSessionButton),
    );
    expect(start.onPressed, isNull);
  });
}
