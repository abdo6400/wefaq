import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/sessions/session_data.dart';
import 'package:wefaq/features/sessions/session_screen.dart';
import 'package:wefaq/main.dart';

void main() {
  test('session tracks skips and permits changing a previous answer', () {
    final progress = SessionProgress(['a', 'b']);
    progress.advance(skipped: true);
    expect(progress.index, 1);
    progress.previous();
    progress.advance(skipped: false);
    progress.advance(skipped: true);
    expect(progress.complete, isTrue);
    expect(progress.skippedCount, 1);
    expect(progress.discussedCount, 1);
    progress.advance(skipped: false);
    expect(progress.skippedCount, 1);
    expect(() => SessionProgress([]), throwsArgumentError);
  });
  testWidgets('user sets up and completes a session', (tester) async {
    await tester.pumpWidget(const WefaqApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ جلسة تجريبية'));
    await tester.pumpAndSettle();
    expect(find.textContaining('لم تُراجع شرعيًا'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ابدأ الجلسة'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('ابدأ الجلسة'));
    await tester.pumpAndSettle();
    expect(find.text('السؤال 1 من 3'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('تخطي'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('السؤال 2 من 3'),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('السؤال 2 من 3'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('التالي'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('إنهاء الجلسة'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('إنهاء الجلسة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنهاء الجلسة'));
    await tester.pumpAndSettle();
    expect(find.text('الأسئلة المتخطاة: 1'), findsOneWidget);
    expect(find.text('الأسئلة التي انتقلتم منها: 2'), findsOneWidget);
  });
  testWidgets('choices select mode and topic', (tester) async {
    await tester.pumpWidget(const WefaqApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ جلسة تجريبية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('في مكالمة'));
    await tester.tap(find.text('الحياة اليومية'));
    await tester.pumpAndSettle();
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'الحياة اليومية'),
    );
    expect(chip.selected, isTrue);
    await tester.scrollUntilVisible(
      find.text('افتحوا مكالمة خارج التطبيق، ويقرأ أحدكما الأسئلة.'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('افتحوا مكالمة خارج التطبيق، ويقرأ أحدكما الأسئلة.'),
      findsOneWidget,
    );
  });
  testWidgets('phone mode can be selected from home', (tester) async {
    await tester.pumpWidget(const WefaqApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('في مكالمة'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('في مكالمة'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('افتحوا مكالمة خارج التطبيق، ويقرأ أحدكما الأسئلة.'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('افتحوا مكالمة خارج التطبيق، ويقرأ أحدكما الأسئلة.'),
      findsOneWidget,
    );
  });
  testWidgets('back warns before losing progress', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const Scaffold()),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const SessionScreen(
          questions: ['test'],
          mode: ConversationMode.together,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('لن يُحفظ تقدم الجلسة في هذه النسخة.'), findsOneWidget);
    await tester.tap(find.text('متابعة الجلسة'));
    await tester.pumpAndSettle();
    expect(find.text('test'), findsOneWidget);
  });
}
