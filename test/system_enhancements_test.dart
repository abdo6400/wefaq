import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/app_theme.dart';
import 'package:wefaq/core/config/app_config.dart';
import 'package:wefaq/core/config/app_env.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/core/widgets/wefaq_shimmer.dart';
import 'package:wefaq/features/activities/data/cached_activity_repository.dart';
import 'package:wefaq/features/feedback/feedback_data.dart';
import 'package:wefaq/features/home/home_screen.dart';
import 'package:wefaq/features/licensing/data/offline_activation_service.dart';
import 'package:wefaq/features/licensing/domain/models/offline_license.dart';
import 'package:wefaq/features/licensing/presentation/offline_activation_gate.dart';
import 'package:wefaq/features/sessions/session_data.dart';
import 'package:wefaq/features/sessions/session_screen.dart';
import 'package:wefaq/features/support/presentation/support_screen.dart';

class _MemActivationStorage implements ActivationStorage {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String value) async => data = value;
}

Widget _wrap(Widget home) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: AppTheme.light,
  home: home,
);

void main() {
  test('AppEnv derives activities and app-config URLs from questions URL', () {
    final env = AppEnv.fromValues(
      envFile: {
        AppEnv.questionsApiUrlKey:
            'https://api.wefaq.example/v1/question-catalog',
      },
      defines: const {},
    );
    expect(
      env.activitiesCatalogUri.toString(),
      'https://api.wefaq.example/v1/activity-catalog',
    );
    expect(
      env.appConfigUri.toString(),
      'https://api.wefaq.example/v1/app-config',
    );
  });

  test(
    'CachedAppConfigRepository caches valid config and ignores invalid updates',
    () async {
      final dir = await Directory.systemTemp.createTemp('wefaq-cfg-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/app_config.json');

      final repo = CachedAppConfigRepository(
        cacheFile: file,
        download: (etag) async => (
          status: 200,
          etag: '"cfg-v1-r2"',
          body: jsonEncode({
            'schemaVersion': 1,
            'revision': 2,
            'contact': {
              'whatsappNumber': '201001234567',
              'email': 'help@wefaq.app',
            },
            'announcement': {
              'enabled': true,
              'title': 'تنبيه',
              'message': 'محتوى جديد متاح',
              'style': 'info',
            },
            'features': {
              'quickSparkEnabled': true,
              'activitiesEnabled': true,
              'discEnabled': false,
              'feedbackEnabled': true,
            },
          }),
        ),
      );

      expect(await repo.refresh(), isTrue);
      final cfg = await repo.getConfig();
      expect(cfg.revision, 2);
      expect(cfg.announcement.enabled, isTrue);
      expect(cfg.announcement.message, 'محتوى جديد متاح');
      expect(cfg.features.discEnabled, isFalse);
      expect(cfg.contact.whatsappNumber, '201001234567');
    },
  );

  test('CachedActivityRepository caches approved activities and rejects draft remote items', () async {
    final dir = await Directory.systemTemp.createTemp('wefaq-act-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/activity_catalog.json');

    final approvedRepo = CachedActivityRepository(
      cacheFile: file,
      download: (etag) async => (
        status: 200,
        etag: '"act-v1-r2"',
        body: jsonEncode({
          'schemaVersion': 1,
          'revision': 2,
          'publishedAt': '2026-11-16T00:00:00Z',
          'activities': [
            {
              'id': 'act_approved_1',
              'type': 'scenario',
              'topic': 'communication',
              'title': 'موقف معتمد',
              'situation': 'وصف الموقف المعتمد',
              'prompts': ['سؤال أول'],
              'options': [],
              'isDevelopmentOnly': false,
            },
          ],
        }),
      ),
    );

    expect(await approvedRepo.update(), isTrue);
    final loaded = await approvedRepo.getActivities();
    expect(loaded.length, 1);
    expect(loaded.first.id, 'act_approved_1');

    final draftRepo = CachedActivityRepository(
      cacheFile: file,
      download: (etag) async => (
        status: 200,
        etag: '"act-v1-r3"',
        body: jsonEncode({
          'schemaVersion': 1,
          'revision': 3,
          'publishedAt': '2026-11-16T00:00:00Z',
          'activities': [
            {
              'id': 'act_draft',
              'type': 'scenario',
              'topic': 'communication',
              'title': 'مسودة',
              'situation': 'وصف',
              'prompts': ['سؤال'],
              'options': [],
              'isDevelopmentOnly': true,
            },
          ],
        }),
      ),
    );
    await expectLater(draftRepo.update(), throwsFormatException);
  });

  testWidgets(
    'SessionScreen shows topic/depth badges and permits reviewing skipped questions',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          SessionScreen.fromQuestions(
            items: const [
              Question(
                id: 'q1',
                text: 'السؤال الأول المتخطى',
                topic: Topic.communication,
                depth: Depth.introductory,
              ),
              Question(
                id: 'q2',
                text: 'السؤال الثاني',
                topic: Topic.finances,
                depth: Depth.deeper,
              ),
            ],
            mode: ConversationMode.together,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Topic.communication.label), findsOneWidget);
      expect(find.text(Depth.introductory.label), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AppStrings.skipButton),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(AppStrings.skipButton));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(AppStrings.finishSessionButton),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(AppStrings.finishSessionButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.reviewSkippedQuestions), findsOneWidget);
      await tester.tap(find.text(AppStrings.reviewSkippedQuestions));
      await tester.pumpAndSettle();

      expect(find.text('السؤال الأول المتخطى'), findsOneWidget);
      expect(find.text('السؤال 1 من 1'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen renders announcement banner and mixed topic Bento tile',
    (tester) async {
      final configRepo = InMemoryAppConfigRepository(
        const AppConfig(
          revision: 2,
          announcement: AppAnnouncementConfig(
            enabled: true,
            title: 'تحديث',
            message: 'مرحبًا بكم في النسخة الجديدة',
            style: AnnouncementStyle.info,
          ),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          HomeScreen(
            questionRepository: InMemoryQuestionRepository(),
            appConfigRepository: configRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تحديث: مرحبًا بكم في النسخة الجديدة'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(AppStrings.topicMixed),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(AppStrings.topicMixed), findsOneWidget);
    },
  );

  testWidgets(
    'OfflineActivationGate shows contact request dialog and SupportScreen shows saved feedback',
    (tester) async {
      final key = await Ed25519().newKeyPair();
      final service = OfflineActivationService(
        storage: _MemActivationStorage(),
        publicKey: await key.extractPublicKey(),
      );
      final id = (await service.state()).installationId;
      final code = await OfflineLicenseCodec().sign(
        OfflineLicense(
          id: 'lic_test',
          installations: [id],
          issuedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
          sessionLimit: 10,
        ),
        key,
      );
      await service.activate(code);

      await tester.pumpWidget(
        _wrap(
          OfflineActivationGate(
            service: service,
            forceActivation: true,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.activationCurrentLicense), findsOneWidget);
      expect(find.text(AppStrings.activationPasteCode), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AppStrings.activationRequestCode),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text(AppStrings.activationRequestCode));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.activationRequestCode));
      await tester.pumpAndSettle();
      expect(find.text('نسخ الرسالة'), findsOneWidget);
      await tester.tap(find.text(AppStrings.cancelAction));
      await tester.pumpAndSettle();

      final fbStorage = InMemoryFeedbackStorage();
      await fbStorage.saveFeedback(
        FeedbackReport(
          id: 'fb_1',
          category: FeedbackCategory.suggestion,
          rating: 5,
          comment: 'تجربة رائعة',
          createdAt: DateTime.now().toUtc(),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          SupportScreen(activationService: service, feedbackStorage: fbStorage),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.activationCurrentLicense), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('${AppStrings.viewSavedFeedback} (1)'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.text('${AppStrings.viewSavedFeedback} (1)'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('${AppStrings.viewSavedFeedback} (1)'));
      await tester.pumpAndSettle();
      expect(find.text('تجربة رائعة'), findsOneWidget);
    },
  );

  test('Dart OfflineLicenseCodec verifies Ed25519 signature generated by Node backend', () async {
    // Test vector generated by backend/dist/licenses/licenses.crypto.js with dummy test seed
    const pubB64 = 'ebVWLo_mVPlAeLES6KmLp5AfhTrmlb7X4OORC60ElmQ';
    const nodeCode =
        'eyJ2IjoxLCJpZCI6ImNyb3NzX2NvbXBhdF8xIiwiZGV2aWNlcyI6WyJpbnN0XzEyMzQ1Njc4LTEyMzQtNDIzNC04MjM0LTEyMzQ1Njc4OWFiYyJdLCJpc3N1ZWRBdCI6IjIwMjYtMTEtMTZUMDA6MDA6MDAuMDAwWiIsImV4cGlyZXNBdCI6IjIwMjctMTEtMTZUMDA6MDA6MDAuMDAwWiIsInNlc3Npb25MaW1pdCI6MjB9.8Vz0jJIpDXICQohqftJhQlA5BKT-dM8YoIzxLDwSJK6ixBcNmZwSx58_IzDDb9TeQ-Tp2BlgAWnSKQWU1I7-CQ';
    final pubKey = SimplePublicKey(
      base64Url.decode(base64Url.normalize(pubB64)),
      type: KeyPairType.ed25519,
    );
    final verified = await OfflineLicenseCodec().verify(nodeCode, pubKey);
    expect(verified.id, 'cross_compat_1');
    expect(verified.sessionLimit, 20);
    expect(verified.installations, [
      'inst_12345678-1234-4234-8234-123456789abc',
    ]);
  });

  testWidgets(
    'WefaqCardListShimmer and WefaqInlineShimmer animate while loading and settle cleanly',
    (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: FutureBuilder<String>(
              future: completer.future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Column(
                    children: [
                      WefaqInlineShimmer(height: 20),
                      Expanded(child: WefaqCardListShimmer(itemCount: 3)),
                    ],
                  );
                }
                return Center(child: Text(snapshot.data!));
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(tester.takeException(), isNull);
      expect(find.byType(WefaqInlineShimmer), findsOneWidget);
      expect(find.byType(WefaqCardListShimmer), findsOneWidget);
      expect(find.byType(WefaqShimmer), findsNWidgets(4));

      completer.complete('تم التحميل');
      await tester.pumpAndSettle();

      expect(find.byType(WefaqCardListShimmer), findsNothing);
      expect(find.text('تم التحميل'), findsOneWidget);
    },
  );
}
