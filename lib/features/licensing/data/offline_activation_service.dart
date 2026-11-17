import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/models/offline_license.dart';
import '../domain/repositories/offline_activation.dart';

abstract interface class ActivationStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureActivationStorage implements ActivationStorage {
  const SecureActivationStorage(this.storage);
  final FlutterSecureStorage storage;
  static const _key = 'offline_activation_v1';
  @override
  Future<String?> read() => storage.read(key: _key);
  @override
  Future<void> write(String value) => storage.write(key: _key, value: value);
}

/// Serializes all access through one service instance. The signed credential,
/// installation ID, and idempotency ledger are one secure-storage record.
class OfflineActivationService implements OfflineActivation {
  static const Duration defaultTrialDuration = Duration(days: 14);
  static const Duration _clockRollbackTolerance = Duration(minutes: 5);
  static const Duration _clockWatermarkInterval = Duration(hours: 6);

  OfflineActivationService({
    required this.storage,
    required this.publicKey,
    this.trialDuration,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ActivationStorage storage;
  final SimplePublicKey? publicKey;
  final Duration? trialDuration;
  @override
  bool get isConfigured => publicKey != null;
  bool get _hasTrial =>
      publicKey != null &&
      trialDuration != null &&
      trialDuration! > Duration.zero;
  final DateTime Function() _clock;
  final _codec = OfflineLicenseCodec();
  Future<void> _tail = Future.value();

  Future<T> _locked<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  DateTime? _parseOptionalUtc(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key) || data[key] == null) return null;
    final raw = data[key];
    if (raw is! String) throw const FormatException('Invalid activation state');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null || !parsed.isUtc) {
      throw const FormatException('Invalid activation state');
    }
    return parsed;
  }

  Future<Map<String, dynamic>> _read() async {
    final nowUtc = _clock().toUtc();
    final raw = await storage.read();
    if (raw == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 15) | 64;
      bytes[8] = (bytes[8] & 63) | 128;
      final hex = bytes.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
      final id =
          'inst_${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
      final state = <String, dynamic>{
        'v': 1,
        'installationId': id,
        'licenses': <String, dynamic>{},
        if (_hasTrial) ...{
          'trialStartedAt': nowUtc.toIso8601String(),
          'trialLastAt': nowUtc.toIso8601String(),
          'trialExpired': false,
        },
      };
      await storage.write(jsonEncode(state));
      return state;
    }
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['v'] != 1 ||
        value['installationId'] is! String ||
        value['licenses'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid activation state');
    }
    final expiredFlag = value['trialExpired'];
    if (expiredFlag != null && expiredFlag is! bool) {
      throw const FormatException('Invalid activation state');
    }
    final trialStartedAt = _parseOptionalUtc(value, 'trialStartedAt');
    final trialLastAt = _parseOptionalUtc(value, 'trialLastAt');

    if (_hasTrial &&
        value['active'] == null &&
        (value['licenses'] as Map<String, dynamic>).isEmpty) {
      if (trialStartedAt == null) {
        value['trialStartedAt'] = nowUtc.toIso8601String();
        value['trialLastAt'] = nowUtc.toIso8601String();
        value['trialExpired'] = false;
        await storage.write(jsonEncode(value));
      } else {
        final endsAt = trialStartedAt.add(trialDuration!);
        final lastAt = trialLastAt ?? trialStartedAt;
        if (expiredFlag != true && !nowUtc.isBefore(endsAt)) {
          value['trialExpired'] = true;
          value['trialLastAt'] = endsAt.toIso8601String();
          await storage.write(jsonEncode(value));
        } else if (expiredFlag != true &&
            nowUtc.isAfter(lastAt) &&
            nowUtc.difference(lastAt) >= _clockWatermarkInterval) {
          value['trialLastAt'] = nowUtc.toIso8601String();
          await storage.write(jsonEncode(value));
        }
      }
    }
    return value;
  }

  Future<ActivationState> _snapshot(Map<String, dynamic> data) async {
    final id = data['installationId'] as String;
    final active = data['active'];
    if (active == null) {
      if (!_hasTrial) return ActivationState(installationId: id);
      final trialStartedAt = _parseOptionalUtc(data, 'trialStartedAt');
      final trialLastAt = _parseOptionalUtc(data, 'trialLastAt');
      final expiredFlag = data['trialExpired'] == true;
      if (trialStartedAt == null) {
        return ActivationState(installationId: id);
      }
      final trialEndsAt = trialStartedAt.add(trialDuration!);
      final nowUtc = _clock().toUtc();
      final lastAt = trialLastAt ?? trialStartedAt;
      final clockTampered = nowUtc.isBefore(
        lastAt.subtract(_clockRollbackTolerance),
      );
      final expired = expiredFlag || !nowUtc.isBefore(trialEndsAt);
      return ActivationState(
        installationId: id,
        trialStartedAt: trialStartedAt,
        trialEndsAt: trialEndsAt,
        trialExpired: expired,
        trialClockTampered: clockTampered,
      );
    }
    final entries = data['licenses'] as Map<String, dynamic>;
    final entry = entries[active];
    if (publicKey == null ||
        entry is! Map<String, dynamic> ||
        entry['code'] is! String ||
        entry['sessions'] is! List) {
      throw const FormatException('Invalid activation state');
    }
    final license = await _codec.verify(entry['code'] as String, publicKey!);
    if (license.id != active ||
        !license.installations.contains(id) ||
        (entry['sessions'] as List).any((x) => x is! String)) {
      throw const FormatException('Invalid activation state');
    }
    final count = (entry['sessions'] as List).length;
    return ActivationState(
      installationId: id,
      license: license,
      remaining: license.sessionLimit == null
          ? null
          : max(0, license.sessionLimit! - count),
    );
  }

  @override
  Future<ActivationState> state() =>
      _locked(() async => _snapshot(await _read()));

  @override
  Future<OfflineLicense> inspect(String code) => _locked(() async {
    if (publicKey == null) throw StateError('Verification key not configured');
    final data = await _read();
    final license = await _codec.verify(code.trim(), publicKey!);
    if (!license.permits(data['installationId'] as String, _clock())) {
      throw const FormatException(
        'License not valid for this installation or time',
      );
    }
    return license;
  });

  @override
  Future<void> activate(String code) => _locked(() async {
    if (publicKey == null) throw StateError('Verification key not configured');
    final data = await _read();
    final license = await _codec.verify(code.trim(), publicKey!);
    if (!license.permits(data['installationId'] as String, _clock())) {
      throw const FormatException(
        'License not valid for this installation or time',
      );
    }
    final entries = data['licenses'] as Map<String, dynamic>;
    final existing = entries[license.id];
    if (existing != null &&
        (existing is! Map<String, dynamic> ||
            existing['code'] != code.trim())) {
      throw const FormatException('License ID already used');
    }
    entries.putIfAbsent(
      license.id,
      () => {'code': code.trim(), 'sessions': <String>[]},
    );
    data['active'] = license.id;
    await storage.write(jsonEncode(data));
  });

  /// Idempotent across restarts: the caller must persist and reuse sessionId.
  @override
  Future<bool> reserve(String sessionId) => _locked(() async {
    if (sessionId.isEmpty) throw ArgumentError('Empty session ID');
    final data = await _read();
    // A session already paid for remains paid even after a later renewal.
    // Verify its original signed credential rather than trusting the ledger alone.
    final entries = data['licenses'] as Map<String, dynamic>;
    for (final item in entries.entries) {
      final value = item.value;
      if (value is! Map<String, dynamic> ||
          value['sessions'] is! List ||
          value['code'] is! String) {
        throw const FormatException('Invalid activation state');
      }
      if ((value['sessions'] as List).contains(sessionId)) {
        if (publicKey == null) {
          throw StateError('Verification key not configured');
        }
        final previous = await _codec.verify(
          value['code'] as String,
          publicKey!,
        );
        if (previous.id != item.key ||
            !previous.installations.contains(data['installationId'])) {
          throw const FormatException('Invalid activation state');
        }
        return true;
      }
    }
    final current = await _snapshot(data);
    final license = current.license;
    if (license == null || !license.permits(current.installationId, _clock())) {
      return false;
    }
    final entry =
        (data['licenses'] as Map<String, dynamic>)[license.id]
            as Map<String, dynamic>;
    final sessions = entry['sessions'] as List;
    if (sessions.contains(sessionId)) return true;
    if (current.remaining != null && current.remaining! <= 0) return false;
    sessions.add(sessionId);
    await storage.write(jsonEncode(data));
    return true;
  });
}
