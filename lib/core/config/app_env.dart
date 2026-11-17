import 'package:flutter/services.dart';

/// Application environment configuration loaded from the bundled `.env` asset
/// with optional `--dart-define` compile-time overrides.
class AppEnv {
  /// Creates an immutable environment configuration instance.
  const AppEnv({
    this.questionsApiUrl = '',
    this.activitiesApiUrl = '',
    this.appConfigApiUrl = '',
    this.licensePublicKey = '',
    this.linkHost = '',
  });

  /// Resolves values using non-empty [defines] first, then [envFile].
  factory AppEnv.fromValues({
    Map<String, String> envFile = const {},
    Map<String, String> defines = _compileTimeDefines,
  }) {
    String resolve(String key) {
      final defineValue = defines[key]?.trim();
      if (defineValue != null && defineValue.isNotEmpty) {
        return defineValue;
      }
      return envFile[key]?.trim() ?? '';
    }

    return AppEnv(
      questionsApiUrl: resolve(questionsApiUrlKey),
      activitiesApiUrl: resolve(activitiesApiUrlKey),
      appConfigApiUrl: resolve(appConfigApiUrlKey),
      licensePublicKey: resolve(licensePublicKeyKey),
      linkHost: resolve(linkHostKey),
    );
  }

  /// Asset path of the bundled environment file.
  static const String assetPath = '.env';

  /// Key for the HTTPS question catalog endpoint.
  static const String questionsApiUrlKey = 'WEFAQ_QUESTIONS_API_URL';

  /// Key for the HTTPS activities catalog endpoint.
  static const String activitiesApiUrlKey = 'WEFAQ_ACTIVITIES_API_URL';

  /// Key for the HTTPS app configuration endpoint.
  static const String appConfigApiUrlKey = 'WEFAQ_APP_CONFIG_API_URL';

  /// Key for the base64url Ed25519 offline-license verification public key.
  static const String licensePublicKeyKey = 'WEFAQ_LICENSE_PUBLIC_KEY';

  /// Key for the Android/universal activation deep-link host.
  static const String linkHostKey = 'WEFAQ_LINK_HOST';

  static const Map<String, String> _compileTimeDefines = {
    questionsApiUrlKey: String.fromEnvironment(questionsApiUrlKey),
    activitiesApiUrlKey: String.fromEnvironment(activitiesApiUrlKey),
    appConfigApiUrlKey: String.fromEnvironment(appConfigApiUrlKey),
    licensePublicKeyKey: String.fromEnvironment(licensePublicKeyKey),
    linkHostKey: String.fromEnvironment(linkHostKey),
  };

  /// Full HTTPS URL for `GET /v1/question-catalog`.
  final String questionsApiUrl;

  /// Optional explicit HTTPS URL for `GET /v1/activity-catalog`.
  final String activitiesApiUrl;

  /// Optional explicit HTTPS URL for `GET /v1/app-config`.
  final String appConfigApiUrl;

  /// Base64url-encoded 32-byte Ed25519 public key for offline activation.
  final String licensePublicKey;

  /// Hostname permitted for `/activate` deep links.
  final String linkHost;

  /// Returns validated HTTPS URI for questions catalog, or null if invalid.
  Uri? get questionsCatalogUri => _parseHttpsUri(questionsApiUrl);

  /// Returns validated HTTPS URI for activities catalog (explicit or derived).
  Uri? get activitiesCatalogUri =>
      _parseHttpsUri(activitiesApiUrl) ??
      _deriveEndpoint('/v1/activity-catalog');

  /// Returns validated HTTPS URI for app configuration (explicit or derived).
  Uri? get appConfigUri =>
      _parseHttpsUri(appConfigApiUrl) ?? _deriveEndpoint('/v1/app-config');

  Uri? _deriveEndpoint(String path) {
    final base = questionsCatalogUri;
    if (base == null) return null;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
    );
  }

  static Uri? _parseHttpsUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return null;
    }
    return uri;
  }

  /// Loads [path] from [bundle] (defaulting to [rootBundle]) and merges
  /// compile-time `--dart-define` overrides on top.
  static Future<AppEnv> load({
    AssetBundle? bundle,
    String path = assetPath,
  }) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(path);
      return AppEnv.fromValues(envFile: parse(raw));
    } catch (_) {
      // Missing or unreadable .env still allows --dart-define overrides.
      return AppEnv.fromValues();
    }
  }

  /// Parses `KEY=VALUE` lines from a `.env` file into a trimmed map.
  static Map<String, String> parse(String raw) {
    final values = <String, String>{};
    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final normalized = line.startsWith('export ')
          ? line.substring('export '.length).trimLeft()
          : line;
      final eqIndex = normalized.indexOf('=');
      if (eqIndex <= 0) continue;
      final key = normalized.substring(0, eqIndex).trim();
      if (key.isEmpty) continue;
      values[key] = _unquote(normalized.substring(eqIndex + 1).trim());
    }
    return values;
  }

  static String _unquote(String value) {
    if (value.length >= 2) {
      final first = value[0];
      final last = value[value.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        return value.substring(1, value.length - 1);
      }
    }
    return value;
  }
}
