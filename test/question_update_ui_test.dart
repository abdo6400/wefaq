import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/sessions/domain/models/question.dart';
import 'package:wefaq/features/sessions/domain/models/saved_session_state.dart';
import 'package:wefaq/features/sessions/domain/repositories/question_updates.dart';
import 'package:wefaq/features/sessions/data/session_storage.dart';
import 'package:wefaq/features/support/presentation/support_screen.dart';

class _Updates implements QuestionUpdates {
  int calls = 0;
  @override
  bool get isConfigured => true;
  @override
  Future<bool> update() async {
    calls++;
    return true;
  }
}

void main() {
  testWidgets('saved session blocks updates without discarding progress', (
    tester,
  ) async {
    final updates = _Updates();
    final storage = InMemorySessionStorage();
    await storage.writeActiveSession(
      SavedSessionState(
        sessionId: 'saved',
        questionIds: const ['q1'],
        mode: ConversationMode.together,
        currentIndex: 0,
        updatedAt: DateTime.now(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SupportScreen(questionUpdates: updates, sessionStorage: storage),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, AppStrings.updateQuestions),
    );
    await tester.tap(
      find.widgetWithText(OutlinedButton, AppStrings.updateQuestions),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.updateHasSession), findsOneWidget);
    expect(updates.calls, 0);
    expect(await storage.readActiveSession(), isNotNull);
    await storage.clearActiveSession();
    await tester.tap(
      find.widgetWithText(OutlinedButton, AppStrings.updateQuestions),
    );
    await tester.pumpAndSettle();
    expect(updates.calls, 1);
    expect(find.text(AppStrings.updateSuccess), findsOneWidget);
  });
}
