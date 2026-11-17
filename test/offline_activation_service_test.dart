import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/licensing/data/offline_activation_service.dart';
import 'package:wefaq/features/licensing/domain/models/offline_license.dart';

class MemoryStorage implements ActivationStorage {
  String? value;
  bool failWrites = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('write failed');
    this.value = value;
  }
}

void main() {
  test(
    'activation binds device and persists idempotent per-device quota',
    () async {
      final keys = await Ed25519().newKeyPair();
      final publicKey = await keys.extractPublicKey();
      final one = MemoryStorage();
      final two = MemoryStorage();
      DateTime clock() => DateTime.utc(2026, 6);
      var first = OfflineActivationService(
        storage: one,
        publicKey: publicKey,
        clock: clock,
      );
      final second = OfflineActivationService(
        storage: two,
        publicKey: publicKey,
        clock: clock,
      );
      final id1 = (await first.state()).installationId;
      final id2 = (await second.state()).installationId;
      final code = await OfflineLicenseCodec().sign(
        OfflineLicense(
          id: 'one',
          installations: [id1, id2],
          issuedAt: DateTime.utc(2026),
          sessionLimit: 1,
        ),
        keys,
      );
      await first.activate(code);
      await second.activate(code);
      expect(await first.reserve('session-a'), isTrue);
      expect(await first.reserve('session-a'), isTrue);
      expect(await first.reserve('session-b'), isFalse);
      await first.activate(code);
      expect((await first.state()).remaining, 0);
      first = OfflineActivationService(
        storage: one,
        publicKey: publicKey,
        clock: clock,
      );
      expect(await first.reserve('session-a'), isTrue);
      expect(await first.reserve('session-b'), isFalse);
      expect(await second.reserve('session-b'), isTrue);
      final third = OfflineActivationService(
        storage: MemoryStorage(),
        publicKey: publicKey,
        clock: clock,
      );
      await expectLater(third.activate(code), throwsFormatException);
    },
  );

  test('failed storage write does not consume quota and corrupt state fails closed', () async {
    final keys = await Ed25519().newKeyPair();
    final store = MemoryStorage();
    final service = OfflineActivationService(
      storage: store,
      publicKey: await keys.extractPublicKey(),
      clock: () => DateTime.utc(2026, 6),
    );
    final id = (await service.state()).installationId;
    final code = await OfflineLicenseCodec().sign(
      OfflineLicense(
        id: 'one',
        installations: [id],
        issuedAt: DateTime.utc(2026),
        sessionLimit: 1,
      ),
      keys,
    );
    await service.activate(code);
    store.failWrites = true;
    await expectLater(service.reserve('session-a'), throwsStateError);
    store.failWrites = false;
    expect((await service.state()).remaining, 1);
    store.value = '{broken';
    await expectLater(service.state(), throwsFormatException);
    expect(store.value, '{broken');
  });

  test('concurrent starts cannot spend the same last session', () async {
    final keys = await Ed25519().newKeyPair();
    final service = OfflineActivationService(
      storage: MemoryStorage(),
      publicKey: await keys.extractPublicKey(),
      clock: () => DateTime.utc(2026, 6),
    );
    final id = (await service.state()).installationId;
    final code = await OfflineLicenseCodec().sign(
      OfflineLicense(
        id: 'one',
        installations: [id],
        issuedAt: DateTime.utc(2026),
        sessionLimit: 1,
      ),
      keys,
    );
    await service.activate(code);
    final results = await Future.wait([
      service.reserve('a'),
      service.reserve('b'),
    ]);
    expect(results.where((x) => x), hasLength(1));
  });

  test(
    'renewal does not re-charge an already reserved saved session',
    () async {
      final keys = await Ed25519().newKeyPair();
      final service = OfflineActivationService(
        storage: MemoryStorage(),
        publicKey: await keys.extractPublicKey(),
        clock: () => DateTime.utc(2026, 6),
      );
      final id = (await service.state()).installationId;
      Future<String> code(String licenseId) => OfflineLicenseCodec().sign(
        OfflineLicense(
          id: licenseId,
          installations: [id],
          issuedAt: DateTime.utc(2026),
          sessionLimit: 1,
        ),
        keys,
      );
      await service.activate(await code('first'));
      expect(await service.reserve('old-session'), isTrue);
      await service.activate(await code('renewal'));
      expect(await service.reserve('old-session'), isTrue);
      expect((await service.state()).remaining, 1);
      expect(await service.reserve('new-session'), isTrue);
    },
  );
}
