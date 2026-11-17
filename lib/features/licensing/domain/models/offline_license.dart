import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Signed license payload. Quotas apply independently to each installation.
class OfflineLicense {
  const OfflineLicense({
    required this.id,
    required this.installations,
    required this.issuedAt,
    this.expiresAt,
    this.sessionLimit,
  });

  final String id;
  final List<String> installations;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final int? sessionLimit;

  bool permits(String installationId, DateTime now) {
    final utc = now.toUtc();
    return installations.contains(installationId) &&
        !utc.isBefore(issuedAt) &&
        (expiresAt == null || utc.isBefore(expiresAt!));
  }

  Map<String, Object> toJson() => {
    'v': 1,
    'id': id,
    'devices': installations,
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
    'sessionLimit': ?sessionLimit,
  };

  factory OfflineLicense.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final devices = json['devices'];
    final issuedRaw = json['issuedAt'];
    final expiresRaw = json['expiresAt'];
    final limit = json['sessionLimit'];
    if (json['v'] != 1 ||
        id is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(id) ||
        devices is! List ||
        devices.isEmpty ||
        devices.length > 20 ||
        devices.any(
          (d) => d is! String || !RegExp(r'^inst_[0-9a-f-]{36}$').hasMatch(d),
        ) ||
        devices.toSet().length != devices.length ||
        issuedRaw is! String ||
        (expiresRaw != null && expiresRaw is! String) ||
        (limit != null && (limit is! int || limit < 1 || limit > 1000000)) ||
        (expiresRaw == null && limit == null)) {
      throw const FormatException('Invalid license payload');
    }
    final issued = DateTime.tryParse(issuedRaw);
    final expires = expiresRaw is String ? DateTime.tryParse(expiresRaw) : null;
    if (issued == null ||
        !issued.isUtc ||
        (expiresRaw != null &&
            (expires == null || !expires.isUtc || !expires.isAfter(issued)))) {
      throw const FormatException('Invalid license dates');
    }
    return OfflineLicense(
      id: id,
      installations: List<String>.unmodifiable(devices.cast<String>()),
      issuedAt: issued,
      expiresAt: expires,
      sessionLimit: limit as int?,
    );
  }
}

/// Ed25519 signs the exact encoded payload; verification precedes parsing.
class OfflineLicenseCodec {
  OfflineLicenseCodec() : _algorithm = Ed25519();
  final Ed25519 _algorithm;

  Future<String> sign(OfflineLicense license, SimpleKeyPair keyPair) async {
    // Validate the operator input using the same rules as the app.
    OfflineLicense.fromJson(license.toJson());
    final payload = base64Url
        .encode(utf8.encode(jsonEncode(license.toJson())))
        .replaceAll('=', '');
    final signature = await _algorithm.sign(
      utf8.encode(payload),
      keyPair: keyPair,
    );
    return '$payload.${base64Url.encode(signature.bytes).replaceAll('=', '')}';
  }

  Future<OfflineLicense> verify(String code, SimplePublicKey publicKey) async {
    if (code.length > 16384) throw const FormatException('License too long');
    final parts = code.trim().split('.');
    if (parts.length != 2) throw const FormatException('Invalid license');
    try {
      final signature = base64Url.decode(base64Url.normalize(parts[1]));
      if (signature.length != 64 ||
          !await _algorithm.verify(
            utf8.encode(parts[0]),
            signature: Signature(signature, publicKey: publicKey),
          )) {
        throw const FormatException('Invalid signature');
      }
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid license');
      }
      return OfflineLicense.fromJson(decoded);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid license');
    }
  }
}
