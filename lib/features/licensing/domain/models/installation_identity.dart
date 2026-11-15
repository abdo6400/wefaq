import 'dart:convert';
import 'dart:math';

/// Secure installation identity generated locally on the device.
///
/// In compliance with ADR 0002 and privacy requirements (Egyptian Law 151/2020),
/// Wefaq NEVER uses hardware fingerprints, IMEI, MAC address, or advertising IDs.
/// Instead, an installation-specific random identity and cryptographic key
/// are generated per installation.
class InstallationIdentity {
  const InstallationIdentity({
    required this.installationId,
    required this.publicKey,
    required this.createdAt,
  });

  /// Generates a high-entropy random installation identity.
  factory InstallationIdentity.generate([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // UUID v4 format
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hexChars = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final uuid =
        '${hexChars.substring(0, 8)}-${hexChars.substring(8, 12)}-${hexChars.substring(12, 16)}-${hexChars.substring(16, 20)}-${hexChars.substring(20)}';

    final keyBytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final pubKey = base64UrlEncode(keyBytes);

    return InstallationIdentity(
      installationId: 'inst_$uuid',
      publicKey: pubKey,
      createdAt: DateTime.now().toUtc(),
    );
  }

  factory InstallationIdentity.fromJson(Map<String, dynamic> json) {
    final installationId = json['installationId'] as String?;
    if (installationId == null || installationId.trim().isEmpty) {
      throw const FormatException('installationId must be a non-empty string');
    }
    final publicKey = json['publicKey'] as String? ?? '';
    final createdAtRaw = json['createdAt'] as String?;
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw)?.toUtc() ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    return InstallationIdentity(
      installationId: installationId,
      publicKey: publicKey,
      createdAt: createdAt,
    );
  }

  final String installationId;
  final String publicKey;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'installationId': installationId,
    'publicKey': publicKey,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationIdentity &&
          runtimeType == other.runtimeType &&
          installationId == other.installationId;

  @override
  int get hashCode => installationId.hashCode;

  @override
  String toString() => 'InstallationIdentity(id: $installationId)';
}
