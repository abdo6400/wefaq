import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/app_theme.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/home/home_screen.dart';
import 'package:wefaq/features/licensing/data/offline_activation_service.dart';
import 'package:wefaq/features/licensing/domain/models/offline_license.dart';
import 'package:wefaq/features/licensing/presentation/offline_activation_gate.dart';
import 'package:wefaq/features/sessions/session_data.dart';

class _MemStorage implements ActivationStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  test('fresh install grants 14-day offline trial and latches expiry after 2 weeks even on clock rollback', () async {
    final keys = await Ed25519().newKeyPair();
    final pub = await keys.extractPublicKey();
    final storage = _MemStorage();
    var now = DateTime.utc(2026, 11, 1, 10);

    OfflineActivationService makeService() => OfflineActivationService(
      storage: storage,
      publicKey: pub,
      trialDuration: OfflineActivationService.defaultTrialDuration,
      clock: () => now,
    );

    var service = makeService();
    var state = await service.state();
    expect(state.license, isNull);
    expect(state.isTrialActive(now), isTrue);
    expect(state.hasAccess(now), isTrue);
    expect(state.canStartSession(now), isTrue);
    expect(state.trialRemainingDays(now), 14);

    // Day 10: still permitted; advances watermark.
    now = DateTime.utc(2026, 11, 11, 10);
    service = makeService();
    state = await service.state();
    expect(state.isTrialActive(now), isTrue);
    expect(state.trialRemainingDays(now), 4);

    // Rolling clock backward > 5 minutes blocks access.
    now = DateTime.utc(2026, 11, 5, 10);
    state = await service.state();
    expect(state.trialClockTampered, isTrue);
    expect(state.isTrialActive(now), isFalse);
    expect(state.hasAccess(now), isFalse);

    // Restoring real clock on Day 11 resumes remaining trial.
    now = DateTime.utc(2026, 11, 12, 10);
    state = await service.state();
    expect(state.trialClockTampered, isFalse);
    expect(state.isTrialActive(now), isTrue);
    expect(state.trialRemainingDays(now), 3);

    // Day 14 exact boundary: trial expires and stays permanently latched.
    now = DateTime.utc(2026, 11, 15, 10);
    state = await service.state();
    expect(state.trialExpired, isTrue);
    expect(state.isTrialActive(now), isFalse);
    expect(state.hasAccess(now), isFalse);
    expect(state.canStartSession(now), isFalse);

    // Rolling clock backward after expiry never re-opens trial.
    now = DateTime.utc(2026, 11, 2, 10);
    service = makeService();
    state = await service.state();
    expect(state.trialExpired, isTrue);
    expect(state.hasAccess(now), isFalse);
  });

  test('activating a license overrides trial and an expired license never falls back to trial', () async {
    final keys = await Ed25519().newKeyPair();
    final pub = await keys.extractPublicKey();
    final storage = _MemStorage();
    var now = DateTime.utc(2026, 11, 1, 10);

    final service = OfflineActivationService(
      storage: storage,
      publicKey: pub,
      trialDuration: OfflineActivationService.defaultTrialDuration,
      clock: () => now,
    );

    final initial = await service.state();
    expect(initial.isTrialActive(now), isTrue);

    final license = OfflineLicense(
      id: 'paid_short',
      installations: [initial.installationId],
      issuedAt: DateTime.utc(2026, 11, 1, 9),
      expiresAt: DateTime.utc(2026, 11, 3, 10),
    );
    final code = await OfflineLicenseCodec().sign(license, keys);
    await service.activate(code);

    // Day 5: license expired (even though Day 14 trial window wouldn't have ended yet).
    now = DateTime.utc(2026, 11, 6, 10);
    final afterExpiry = await service.state();
    expect(afterExpiry.license, isNotNull);
    expect(afterExpiry.isTrialActive(now), isFalse);
    expect(afterExpiry.hasAccess(now), isFalse);
    expect(afterExpiry.canStartSession(now), isFalse);
  });

  testWidgets('unconfigured build never unlocks a free trial', (tester) async {
    final service = OfflineActivationService(
      storage: _MemStorage(),
      publicKey: null,
      trialDuration: OfflineActivationService.defaultTrialDuration,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: OfflineActivationGate(
          service: service,
          child: const Scaffold(body: Text('unlocked')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('unlocked'), findsNothing);
    expect(find.text(AppStrings.activationUnconfigured), findsOneWidget);
  });

  testWidgets(
    'app opens immediately during 2-week trial, runs sessions, then auto-closes on resume after 2 weeks until activated',
    (tester) async {
      final keys = await Ed25519().newKeyPair();
      final pub = await keys.extractPublicKey();
      final storage = _MemStorage();
      var now = DateTime.now().toUtc();

      final service = OfflineActivationService(
        storage: storage,
        publicKey: pub,
        trialDuration: OfflineActivationService.defaultTrialDuration,
        clock: () => now,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
          home: OfflineActivationGate(
            service: service,
            clock: () => now,
            child: HomeScreen(
              activationService: service,
              sessionStorage: InMemorySessionStorage(),
              questionRepository: InMemoryQuestionRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Home opens directly with trial status bar.
      expect(find.text(AppStrings.startConversation), findsOneWidget);
      expect(find.text(AppStrings.trialBarStatus(14)), findsOneWidget);

      // Can start a session during the 2-week trial.
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

      // Advance clock 14 days offline and resume app while deep inside SessionScreen.
      now = now.add(const Duration(days: 14));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // App automatically closed back to the activation gate.
      expect(find.textContaining('السؤال 1 من'), findsNothing);
      expect(
        find.text(AppStrings.activationTrialExpiredNotice),
        findsOneWidget,
      );
      expect(find.text(AppStrings.activationTitle), findsOneWidget);

      // Activating a signed code unlocks the app again.
      final id = (await service.state()).installationId;
      final code = await OfflineLicenseCodec().sign(
        OfflineLicense(
          id: 'post_trial_1',
          installations: [id],
          issuedAt: now.subtract(const Duration(minutes: 1)),
          sessionLimit: 20,
        ),
        keys,
      );
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text(AppStrings.activate));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.startConversation), findsOneWidget);
      expect(find.text('المتبقي: 20 جلسة'), findsOneWidget);
    },
  );
}
