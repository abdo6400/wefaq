import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/licensing/data/offline_activation_service.dart';
import 'package:wefaq/features/licensing/domain/models/offline_license.dart';
import 'package:wefaq/features/licensing/presentation/offline_activation_gate.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/sessions/session_data.dart';
import 'package:wefaq/main.dart';

class _Storage implements ActivationStorage {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String value) async => data = value;
}

class _FlakyHistory implements QuestionHistoryStorage {
  bool failNext = true;
  final Set<String> ids = {};
  @override
  Future<void> clearHistory() async => ids.clear();
  @override
  Future<Set<String>> getRecentlyAskedIds() async => Set.of(ids);
  @override
  Future<void> recordAskedQuestions(List<String> questionIds) async {
    if (failNext) {
      failNext = false;
      throw StateError('write failed');
    }
    ids.addAll(questionIds);
  }
}

void main() {
  testWidgets(
    'failed history write retains the charged session and recovery records it',
    (tester) async {
      final key = await Ed25519().newKeyPair();
      final service = OfflineActivationService(
        storage: _Storage(),
        publicKey: await key.extractPublicKey(),
      );
      final id = (await service.state()).installationId;
      final code = await OfflineLicenseCodec().sign(
        OfflineLicense(
          id: 'recovery',
          installations: [id],
          issuedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
          sessionLimit: 1,
        ),
        key,
      );
      await service.activate(code);
      final storage = InMemorySessionStorage();
      final history = _FlakyHistory();
      await tester.pumpWidget(
        WefaqApp(
          activationService: service,
          sessionStorage: storage,
          historyStorage: history,
          questionRepository: InMemoryQuestionRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startConversation));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(AppStrings.startSessionButton),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text(AppStrings.startSessionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startSessionButton));
      await tester.pumpAndSettle();
      expect(await storage.readActiveSession(), isNotNull);
      expect((await service.state()).remaining, 0);
      expect(history.ids, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(AppStrings.resumeSessionButton),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text(AppStrings.resumeSessionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.resumeSessionButton));
      await tester.pumpAndSettle();
      expect(history.ids, isNotEmpty);
      expect((await service.state()).remaining, 0);
      expect(find.textContaining('السؤال 1 من'), findsOneWidget);
    },
  );
  testWidgets(
    'activation links verify host, activate and confirm replacements',
    (tester) async {
      final key = await Ed25519().newKeyPair();
      final service = OfflineActivationService(
        storage: _Storage(),
        publicKey: await key.extractPublicKey(),
      );
      final id = (await service.state()).installationId;
      Future<String> makeCode(String licenseId) => OfflineLicenseCodec().sign(
        OfflineLicense(
          id: licenseId,
          installations: [id],
          issuedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
          sessionLimit: 2,
        ),
        key,
      );
      final first = await makeCode('first');
      final second = await makeCode('second');
      final links = StreamController<Uri>();
      addTearDown(links.close);
      await tester.pumpWidget(
        MaterialApp(
          home: OfflineActivationGate(
            service: service,
            linkHost: 'wefaq.example',
            links: links.stream,
            child: const Scaffold(body: Text('unlocked')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      links.addError(StateError('link transport unavailable'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.activationLinkFailure), findsOneWidget);
      links.add(Uri.parse('https://other.example/activate#$first'));
      await tester.pumpAndSettle();
      expect((await service.state()).license, isNull);
      links.add(Uri.parse('https://wefaq.example/activate#$first'));
      await tester.pumpAndSettle();
      expect(find.text('unlocked'), findsOneWidget);
      links.add(Uri.parse('https://wefaq.example/activate#$second'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.activationReplaceTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.cancelAction));
      await tester.pumpAndSettle();
      expect((await service.state()).license!.id, 'first');
      links.add(Uri.parse('https://wefaq.example/activate#$second'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.activationReplaceConfirm));
      await tester.pumpAndSettle();
      expect((await service.state()).license!.id, 'second');
    },
  );
  testWidgets(
    'starting a saved session spends once and resume does not spend again',
    (tester) async {
      final key = await Ed25519().newKeyPair();
      final service = OfflineActivationService(
        storage: _Storage(),
        publicKey: await key.extractPublicKey(),
      );
      final id = (await service.state()).installationId;
      final code = await OfflineLicenseCodec().sign(
        OfflineLicense(
          id: 'flow',
          installations: [id],
          issuedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
          sessionLimit: 2,
        ),
        key,
      );
      await service.activate(code);
      final sessionStorage = InMemorySessionStorage();
      Widget app() => WefaqApp(
        activationService: service,
        sessionStorage: sessionStorage,
        questionRepository: InMemoryQuestionRepository(),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startConversation));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(AppStrings.startSessionButton),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text(AppStrings.startSessionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startSessionButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('السؤال 1 من'), findsOneWidget);
      expect((await service.state()).remaining, 1);
      expect(await sessionStorage.readActiveSession(), isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(AppStrings.resumeSessionButton),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text(AppStrings.resumeSessionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.resumeSessionButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('السؤال 1 من'), findsOneWidget);
      expect((await service.state()).remaining, 1);
    },
  );
  testWidgets('activation rejects an invalid code then unlocks a valid one', (
    tester,
  ) async {
    final key = await Ed25519().newKeyPair();
    final service = OfflineActivationService(
      storage: _Storage(),
      publicKey: await key.extractPublicKey(),
    );
    final id = (await service.state()).installationId;
    final license = OfflineLicense(
      id: 'test',
      installations: [id],
      issuedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      sessionLimit: 2,
    );
    final code = await OfflineLicenseCodec().sign(license, key);
    await tester.pumpWidget(
      MaterialApp(
        home: OfflineActivationGate(
          service: service,
          child: const Scaffold(body: Text('unlocked')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('unlocked'), findsNothing);
    await tester.enterText(find.byType(TextField), 'invalid');
    await tester.tap(find.text('تفعيل'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذر التفعيل'), findsOneWidget);
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('تفعيل'));
    await tester.pumpAndSettle();
    expect(find.text('unlocked'), findsOneWidget);
  });
}
