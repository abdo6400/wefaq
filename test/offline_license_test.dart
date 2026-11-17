import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/licensing/domain/models/offline_license.dart';

void main() {
  final algorithm = Ed25519();
  final codec = OfflineLicenseCodec();
  const device1 = 'inst_12345678-1234-4234-8234-123456789abc';
  const device2 = 'inst_87654321-1234-4234-8234-123456789abc';

  test('signed code preserves both devices and per-device limits', () async {
    final key = await algorithm.newKeyPair();
    final license = OfflineLicense(
      id: 'license_1',
      installations: [device1, device2],
      issuedAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2027),
      sessionLimit: 20,
    );
    final code = await codec.sign(license, key);
    final verified = await codec.verify(code, await key.extractPublicKey());
    expect(verified.installations, [device1, device2]);
    expect(verified.sessionLimit, 20);
    expect(verified.expiresAt, DateTime.utc(2027));
    expect(verified.permits(device1, DateTime.utc(2026, 6)), isTrue);
    expect(verified.permits(device2, DateTime.utc(2026, 6)), isTrue);
    expect(verified.permits('other', DateTime.utc(2026, 6)), isFalse);
    expect(verified.permits(device1, DateTime.utc(2027)), isFalse);
    expect(verified.permits(device1, DateTime.utc(2025)), isFalse);
  });

  test('rejects altered payload and wrong signing key', () async {
    final key = await algorithm.newKeyPair();
    final otherKey = await algorithm.newKeyPair();
    final license = OfflineLicense(
      id: 'license_1',
      installations: [device1],
      issuedAt: DateTime.utc(2026),
      sessionLimit: 1,
    );
    final code = await codec.sign(license, key);
    final parts = code.split('.');
    final json = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
    ) as Map<String, dynamic>;
    json['sessionLimit'] = 999;
    final altered =
        '${base64Url.encode(utf8.encode(jsonEncode(json)))}.${parts[1]}';
    await expectLater(
      codec.verify(altered, await key.extractPublicKey()),
      throwsFormatException,
    );
    await expectLater(
      codec.verify(code, await otherKey.extractPublicKey()),
      throwsFormatException,
    );
  });

  test('rejects duplicate devices, absent limits and invalid dates', () {
    final payload = {
      'v': 1,
      'id': 'a',
      'devices': [device1, device1],
      'issuedAt': '2026-01-01T00:00:00.000Z',
      'sessionLimit': 2,
    };
    expect(() => OfflineLicense.fromJson(payload), throwsFormatException);
    payload['devices'] = [device1];
    payload.remove('sessionLimit');
    expect(() => OfflineLicense.fromJson(payload), throwsFormatException);
    payload['expiresAt'] = '2025-01-01T00:00:00.000Z';
    expect(() => OfflineLicense.fromJson(payload), throwsFormatException);
  });
}
