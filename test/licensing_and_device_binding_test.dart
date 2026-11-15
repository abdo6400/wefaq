import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/licensing/licensing_data.dart';

void main() {
  group('InstallationIdentity Model & Privacy Invariants', () {
    test('InstallationIdentity.generate generates unique identities', () {
      final id1 = InstallationIdentity.generate();
      final id2 = InstallationIdentity.generate();

      expect(id1.installationId, isNotEmpty);
      expect(id1.publicKey, isNotEmpty);
      expect(id1.installationId, startsWith('inst_'));
      expect(id1.installationId, isNot(equals(id2.installationId)));
    });

    test('serializes and deserializes InstallationIdentity cleanly', () {
      final original = InstallationIdentity.generate();
      final json = original.toJson();
      final reconstructed = InstallationIdentity.fromJson(json);

      expect(reconstructed.installationId, original.installationId);
      expect(reconstructed.publicKey, original.publicKey);
      expect(
        reconstructed.createdAt.toIso8601String(),
        original.createdAt.toIso8601String(),
      );
    });

    test('rejects empty installationId with FormatException', () {
      expect(
        () => InstallationIdentity.fromJson({'installationId': ''}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ADR 0002 2-Device Slot Enforcement', () {
    late MockLicenseServer server;

    setUp(() {
      server = MockLicenseServer();
    });

    test(
      'allows exactly 2 devices to claim a license, rejecting a 3rd device',
      () async {
        const code = 'WFQ-COUPLE-2026';

        // Device 1 claims slot 1
        final res1 = await server.redeemCode(
          code: code,
          installationId: 'device_01',
          publicKey: 'pub_01',
        );
        expect(res1.isSuccess, isTrue);
        expect(res1.entitlement?.assignedSlot, 1);
        expect(res1.entitlement?.status, EntitlementStatus.active);

        // Device 2 claims slot 2
        final res2 = await server.redeemCode(
          code: code,
          installationId: 'device_02',
          publicKey: 'pub_02',
        );
        expect(res2.isSuccess, isTrue);
        expect(res2.entitlement?.assignedSlot, 2);
        expect(res2.entitlement?.status, EntitlementStatus.active);

        // Device 3 attempts to claim 3rd slot -> MUST FAIL
        final res3 = await server.redeemCode(
          code: code,
          installationId: 'device_03',
          publicKey: 'pub_03',
        );
        expect(res3.isSuccess, isFalse);
        expect(res3.errorCode, ActivationErrorCode.slotsExhausted);
        expect(res3.message, contains('جهازين'));

        // Device 1 re-redeems -> idempotent, stays Slot 1
        final res1Reclaim = await server.redeemCode(
          code: code,
          installationId: 'device_01',
          publicKey: 'pub_01',
        );
        expect(res1Reclaim.isSuccess, isTrue);
        expect(res1Reclaim.entitlement?.assignedSlot, 1);
      },
    );

    test('rejects non-existent code', () async {
      final res = await server.redeemCode(
        code: 'INVALID-CODE-XYZ',
        installationId: 'dev_x',
        publicKey: 'pub_x',
      );
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, ActivationErrorCode.invalidCode);
    });

    test('rejects expired code', () async {
      final res = await server.redeemCode(
        code: 'WFQ-EXPIRED-TEST',
        installationId: 'dev_y',
        publicKey: 'pub_y',
      );
      expect(res.isSuccess, isFalse);
      expect(res.errorCode, ActivationErrorCode.expiredCode);
    });
  });

  group('Session Quota Consumption & Idempotency Invariants', () {
    late MockLicenseServer server;

    setUp(() {
      server = MockLicenseServer();
    });

    test('same idempotency key does not consume quota twice (double-spend protection)', () async {
      const code = 'WFQ-COUPLE-2026';
      final redeem = await server.redeemCode(
        code: code,
        installationId: 'dev_user_1',
        publicKey: 'pub_1',
      );
      final licId = redeem.entitlement!.licenseId;
      expect(redeem.entitlement!.remainingQuota, 20);

      // Start session with idempotency key A
      final token1 = await server.consumeSessionQuota(
        licenseId: licId,
        installationId: 'dev_user_1',
        idempotencyKey: 'key_attempt_01',
      );
      expect(token1, isNotNull);

      // Replay with exact same idempotency key A
      final token1Replay = await server.consumeSessionQuota(
        licenseId: licId,
        installationId: 'dev_user_1',
        idempotencyKey: 'key_attempt_01',
      );
      expect(
        token1Replay,
        equals(token1),
        reason: 'Replay must return exact same token',
      );

      // Check another claim on server via code redeem to see quota: should be 19, not 18!
      final check = await server.redeemCode(
        code: code,
        installationId: 'dev_user_1',
        publicKey: 'pub_1',
      );
      expect(check.entitlement!.remainingQuota, 19);

      // New distinct idempotency key B consumes quota to 18
      final token2 = await server.consumeSessionQuota(
        licenseId: licId,
        installationId: 'dev_user_1',
        idempotencyKey: 'key_attempt_02',
      );
      expect(token2, isNotNull);
      expect(token2, isNot(equals(token1)));

      final check2 = await server.redeemCode(
        code: code,
        installationId: 'dev_user_1',
        publicKey: 'pub_1',
      );
      expect(check2.entitlement!.remainingQuota, 18);
    });
  });

  group('DefaultLicenseRepository & Storage Integration', () {
    late InMemoryLicenseStorage licenseStorage;
    late InMemoryDeviceIdentityStorage identityStorage;
    late MockLicenseServer server;
    late DefaultLicenseRepository repository;

    setUp(() {
      licenseStorage = InMemoryLicenseStorage();
      identityStorage = InMemoryDeviceIdentityStorage();
      server = MockLicenseServer();
      repository = DefaultLicenseRepository(
        licenseStorage: licenseStorage,
        identityStorage: identityStorage,
        server: server,
      );
    });

    test('defaults to trial entitlement when unactivated', () async {
      final ent = await repository.getEntitlement();
      expect(ent.status, EntitlementStatus.trial);
      expect(ent.remainingQuota, 3);
      expect(ent.canStartSession(), isTrue);
    });

    test('activates valid license code and consumes quota', () async {
      final result = await repository.activateCode('WFQ-COUPLE-2026');
      expect(result.isSuccess, isTrue);

      final activeEnt = await repository.getEntitlement();
      expect(activeEnt.status, EntitlementStatus.active);
      expect(activeEnt.remainingQuota, 20);

      final consumed = await repository.consumeSessionQuota('session_req_1');
      expect(consumed, isTrue);

      final after = await repository.getEntitlement();
      expect(after.remainingQuota, 19);
    });

    test('FileLicenseStorage writes and restores atomically', () async {
      final tempDir = await Directory.systemTemp.createTemp('wefaq_lic_test_');
      final file = File('${tempDir.path}/license.json');
      final storage = FileLicenseStorage(storageFile: file);

      expect(await storage.readLicense(), isNull);

      final sample = LicenseEntitlement(
        licenseId: 'lic_file_test',
        status: EntitlementStatus.active,
        planName: 'باقة تجريبية للملفات',
        totalQuota: 15,
        remainingQuota: 14,
        assignedSlot: 1,
      );

      await storage.writeLicense(sample);
      final loaded = await storage.readLicense();

      expect(loaded, isNotNull);
      expect(loaded?.licenseId, 'lic_file_test');
      expect(loaded?.remainingQuota, 14);

      await storage.clearLicense();
      expect(await storage.readLicense(), isNull);

      await tempDir.delete(recursive: true);
    });
  });

  group('License UI Widgets', () {
    testWidgets(
      'LicenseStatusCard renders trial status and opens ActivationSheet',
      (tester) async {
        final repo = DefaultLicenseRepository();
        final trialEnt = LicenseEntitlement.trial();

        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: LicenseStatusCard(
                  entitlement: trialEnt,
                  repository: repo,
                ),
              ),
            ),
          ),
        );

        expect(find.text('حالة الاشتراك'), findsOneWidget);
        expect(find.text('جلسات تجريبية مجانية'), findsOneWidget);
        expect(find.text('الجلسات المتبقية: 3 من 3'), findsOneWidget);
        expect(find.text('تفعيل رمز اشتراك'), findsOneWidget);

        await tester.tap(find.text('تفعيل رمز اشتراك'));
        await tester.pumpAndSettle();

        expect(find.byType(ActivationSheet), findsOneWidget);
        expect(find.text('تفعيل رمز الاشتراك'), findsOneWidget);
      },
    );

    testWidgets(
      'ActivationSheet validates input and displays error on invalid code',
      (tester) async {
        final repo = DefaultLicenseRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: ActivationSheet(repository: repo)),
            ),
          ),
        );

        // Tap submit with empty code
        await tester.tap(find.text('تأكيد التفعيل'));
        await tester.pumpAndSettle();

        expect(find.text('يرجى إدخال رمز التفعيل'), findsOneWidget);

        // Enter invalid code
        await tester.enterText(find.byType(TextField), 'WRONG-CODE');
        await tester.tap(find.text('تأكيد التفعيل'));
        await tester.pumpAndSettle();

        expect(find.text('رمز التفعيل غير صحيح أو غير موجود'), findsOneWidget);
      },
    );
  });
}
