import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:wefaq/features/licensing/domain/models/offline_license.dart';

/// Run only on the operator's trusted computer, never inside the app.
/// The private key must be a 32-byte Ed25519 seed stored outside the project.
Future<void> main(List<String> args) async {
  if (!((args.length == 3 && args.first == 'issue') ||
      (args.length == 4 && args.first == 'issue-link') ||
      (args.length == 2 &&
          (args.first == 'public' || args.first == 'keygen')))) {
    stderr.writeln(
      'Usage: dart run tool/offline_license_issuer.dart issue <seed> <request> | issue-link <seed> <request> <https-origin> | public <seed> | keygen <new-seed>',
    );
    exitCode = 64;
    return;
  }
  try {
    if (args.first == 'keygen') {
      final file = File(args[1]);
      if (file.path != file.absolute.path || !await file.parent.exists()) {
        throw const FormatException(
          'Use an absolute path in an existing private directory',
        );
      }
      final root = await Directory.current.resolveSymbolicLinks();
      final parent = await file.parent.resolveSymbolicLinks();
      final normalizedRoot = Platform.isWindows ? root.toLowerCase() : root;
      final normalizedParent = Platform.isWindows
          ? parent.toLowerCase()
          : parent;
      if (normalizedParent == normalizedRoot ||
          normalizedParent.startsWith(
            '$normalizedRoot${Platform.pathSeparator}',
          )) {
        throw const FormatException(
          'Private key must be outside the project directory',
        );
      }
      final random = Random.secure();
      final seed = List<int>.generate(32, (_) => random.nextInt(256));
      await file.create(exclusive: true);
      await file.writeAsBytes(seed, flush: true);
      final key = await Ed25519().newKeyPairFromSeed(seed);
      stdout.writeln(
        base64Url
            .encode((await key.extractPublicKey()).bytes)
            .replaceAll('=', ''),
      );
      return;
    }
    final seed = await File(args[1]).readAsBytes();
    if (seed.length != 32) {
      throw const FormatException('Expected a 32-byte private seed');
    }
    final key = await Ed25519().newKeyPairFromSeed(seed);
    if (args.first == 'public') {
      stdout.writeln(
        base64Url
            .encode((await key.extractPublicKey()).bytes)
            .replaceAll('=', ''),
      );
      return;
    }
    final value = jsonDecode(await File(args[2]).readAsString());
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    final license = OfflineLicense.fromJson(value);
    final code = await OfflineLicenseCodec().sign(license, key);
    if (args.first == 'issue-link') {
      final origin = Uri.parse(args[3]);
      if (origin.scheme != 'https' ||
          origin.host.isEmpty ||
          origin.hasPort ||
          origin.userInfo.isNotEmpty ||
          (origin.path.isNotEmpty && origin.path != '/') ||
          origin.hasQuery ||
          origin.hasFragment) {
        throw const FormatException('Expected HTTPS origin');
      }
      stdout.writeln(
        Uri(
          scheme: 'https',
          host: origin.host,
          path: '/activate',
          fragment: code,
        ),
      );
    } else {
      stdout.writeln(code);
    }
  } catch (_) {
    // Avoid including private paths, key material or customer data in logs.
    stderr.writeln(
      'Could not issue code. Check the key and license file format.',
    );
    exitCode = 1;
  }
}
