import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/feedback/feedback_data.dart';
import 'package:wefaq/features/feedback/presentation/widgets/feedback_sheet.dart';
import 'package:wefaq/features/sessions/presentation/widgets/question_dialogue_card.dart';

void main() {
  group('FeedbackReport Domain Model', () {
    test('serializes and deserializes accurately', () {
      final now = DateTime.utc(2026, 11, 12, 19, 0, 0);
      final report = FeedbackReport(
        id: 'fb_123',
        category: FeedbackCategory.questionClarity,
        rating: 4,
        comment: 'صياغة السؤال تحتاج توضيح أكثر في السياق المصري',
        questionId: 'comm-intro-1',
        installationId: 'inst_abc_456',
        createdAt: now,
      );

      final json = report.toJson();
      final restored = FeedbackReport.fromJson(json);

      expect(restored.id, 'fb_123');
      expect(restored.category, FeedbackCategory.questionClarity);
      expect(restored.rating, 4);
      expect(
        restored.comment,
        'صياغة السؤال تحتاج توضيح أكثر في السياق المصري',
      );
      expect(restored.questionId, 'comm-intro-1');
      expect(restored.installationId, 'inst_abc_456');
      expect(restored.createdAt, now);
    });

    test('rejects empty id or comment with FormatException', () {
      expect(
        () => FeedbackReport.fromJson({
          'id': '',
          'category': 'general',
          'comment': 'ملاحظة',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => FeedbackReport.fromJson({
          'id': 'fb_1',
          'category': 'general',
          'comment': '   ',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('FeedbackReport equality is based on id', () {
      final now = DateTime.now().toUtc();
      final r1 = FeedbackReport(
        id: 'fb_1',
        category: FeedbackCategory.general,
        comment: 'Comment 1',
        createdAt: now,
      );
      final r2 = FeedbackReport(
        id: 'fb_1',
        category: FeedbackCategory.bugReport,
        comment: 'Comment 2',
        createdAt: now,
      );
      final r3 = FeedbackReport(
        id: 'fb_2',
        category: FeedbackCategory.general,
        comment: 'Comment 1',
        createdAt: now,
      );

      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3)));
    });
  });

  group('FeedbackStorage Invariants', () {
    late Directory tempDir;
    late FileFeedbackStorage fileStorage;
    late InMemoryFeedbackStorage memStorage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wefaq_fb_test_');
      fileStorage = FileFeedbackStorage(
        storageFile: File('${tempDir.path}/wefaq_feedback.json'),
      );
      memStorage = InMemoryFeedbackStorage();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'InMemoryFeedbackStorage saves, retrieves, and clears reports',
      () async {
        expect(await memStorage.getFeedbackReports(), isEmpty);

        final report = FeedbackReport(
          id: 'fb_mem_1',
          category: FeedbackCategory.general,
          rating: 5,
          comment: 'تجربة ممتازة',
          createdAt: DateTime.now().toUtc(),
        );

        await memStorage.saveFeedback(report);
        final reports = await memStorage.getFeedbackReports();
        expect(reports.length, 1);
        expect(reports.first.id, 'fb_mem_1');

        await memStorage.clearAllFeedback();
        expect(await memStorage.getFeedbackReports(), isEmpty);
      },
    );

    test('FileFeedbackStorage atomically saves and restores reports', () async {
      expect(await fileStorage.getFeedbackReports(), isEmpty);

      final report = FeedbackReport(
        id: 'fb_file_1',
        category: FeedbackCategory.suggestion,
        rating: 5,
        comment: 'اقتراح إضافة أسئلة عن السفر',
        createdAt: DateTime.now().toUtc(),
      );

      await fileStorage.saveFeedback(report);
      final list = await fileStorage.getFeedbackReports();
      expect(list.length, 1);
      expect(list.first.comment, 'اقتراح إضافة أسئلة عن السفر');

      await fileStorage.clearAllFeedback();
      expect(await fileStorage.getFeedbackReports(), isEmpty);
    });

    test('FileFeedbackStorage quarantines corrupt JSON safely', () async {
      final file = File(
        '${tempDir.path}/${FileFeedbackStorage.defaultFileName}',
      );
      await file.writeAsString('CORRUPTED_NON_JSON_DATA');

      final reports = await fileStorage.getFeedbackReports();
      expect(reports, isEmpty);

      // Verify file was quarantined
      final quarantined = tempDir
          .listSync()
          .where((f) => f.path.contains('.corrupt.'))
          .toList();
      expect(quarantined, isNotEmpty);
    });
  });

  group('FeedbackSheet Widget', () {
    testWidgets(
      'renders feedback sheet with rating, category, and text input',
      (tester) async {
        final storage = InMemoryFeedbackStorage();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => FeedbackSheet.show(
                    ctx,
                    installationId: 'test-inst-id',
                    storage: storage,
                  ),
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('افتح'));
        await tester.pumpAndSettle();

        expect(find.text('ملاحظات النسخة التجريبية'), findsOneWidget);
        expect(find.text('انطباع عام'), findsOneWidget);
        expect(find.text('وضوح الأسئلة'), findsOneWidget);
        expect(find.text('اقتراح تطوير'), findsOneWidget);
        expect(find.text('مشكلة فنية'), findsOneWidget);
        expect(find.text('حفظ الملاحظة'), findsOneWidget);
        expect(find.text('عبر واتساب'), findsOneWidget);
        expect(find.textContaining('خصوصيتكم محفوظة'), findsOneWidget);

        // Attempt submit without text shows error
        await tester.tap(find.text('حفظ الملاحظة'));
        await tester.pumpAndSettle();
        expect(
          find.text('يرجى كتابة ملاحظتك أو اقتراحك قبل الإرسال'),
          findsOneWidget,
        );

        // Enter valid feedback and submit
        await tester.enterText(
          find.byType(TextField),
          'تطبيق ممتاز ومفيد جدًا',
        );
        await tester.tap(find.text('حفظ الملاحظة'));
        await tester.pumpAndSettle();

        // Verify report was persisted in storage
        final saved = await storage.getFeedbackReports();
        expect(saved.length, 1);
        expect(saved.first.comment, 'تطبيق ممتاز ومفيد جدًا');
        expect(saved.first.installationId, 'test-inst-id');
      },
    );

    testWidgets('QuestionDialogueCard report button triggers callback', (
      tester,
    ) async {
      bool reported = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: QuestionDialogueCard(
                questionText: 'سؤال تجريبي',
                onReportQuestion: () => reported = true,
              ),
            ),
          ),
        ),
      );

      final reportButton = find.byTooltip('إبداء ملاحظة على هذا السؤال');
      expect(reportButton, findsOneWidget);
      await tester.tap(reportButton);
      expect(reported, isTrue);
    });
  });
}
