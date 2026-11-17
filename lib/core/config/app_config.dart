import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../strings/app_strings.dart';

enum AnnouncementStyle { info, warning, success }

class AppContactConfig {
  const AppContactConfig({
    this.whatsappNumber = '',
    this.whatsappDisplay = AppStrings.openWhatsAppSupport,
    this.email = 'support@wefaq.app',
    this.supportHours = AppStrings.supportWorkingHours,
    this.contactMessageTemplate =
        'السلام عليكم، أحتاج مساعدة أو الاستفسار بخصوص تطبيق وفاق.',
  });

  final String whatsappNumber;
  final String whatsappDisplay;
  final String email;
  final String supportHours;
  final String contactMessageTemplate;

  factory AppContactConfig.fromJson(Map<String, dynamic> json) {
    final whatsapp = (json['whatsappNumber'] as String? ?? '').trim();
    final display = (json['whatsappDisplay'] as String? ?? '').trim();
    final email = (json['email'] as String? ?? '').trim();
    final hours = (json['supportHours'] as String? ?? '').trim();
    final template = (json['contactMessageTemplate'] as String? ?? '').trim();
    return AppContactConfig(
      whatsappNumber: RegExp(r'^\d{7,15}$').hasMatch(whatsapp) ? whatsapp : '',
      whatsappDisplay: display.isEmpty
          ? AppStrings.openWhatsAppSupport
          : display,
      email: email.isEmpty ? 'support@wefaq.app' : email,
      supportHours: hours.isEmpty ? AppStrings.supportWorkingHours : hours,
      contactMessageTemplate: template.isEmpty
          ? 'السلام عليكم، أحتاج مساعدة أو الاستفسار بخصوص تطبيق وفاق.'
          : template,
    );
  }
}

class AppAnnouncementConfig {
  const AppAnnouncementConfig({
    this.enabled = false,
    this.title = '',
    this.message = '',
    this.style = AnnouncementStyle.info,
  });

  final bool enabled;
  final String title;
  final String message;
  final AnnouncementStyle style;

  factory AppAnnouncementConfig.fromJson(Map<String, dynamic> json) {
    final styleStr = json['style'] as String? ?? 'info';
    final style = switch (styleStr) {
      'warning' => AnnouncementStyle.warning,
      'success' => AnnouncementStyle.success,
      _ => AnnouncementStyle.info,
    };
    return AppAnnouncementConfig(
      enabled: json['enabled'] == true,
      title: (json['title'] as String? ?? '').trim(),
      message: (json['message'] as String? ?? '').trim(),
      style: style,
    );
  }
}

class AppFeaturesConfig {
  const AppFeaturesConfig({
    this.quickSparkEnabled = true,
    this.activitiesEnabled = true,
    this.discEnabled = true,
    this.feedbackEnabled = true,
  });

  final bool quickSparkEnabled;
  final bool activitiesEnabled;
  final bool discEnabled;
  final bool feedbackEnabled;

  factory AppFeaturesConfig.fromJson(Map<String, dynamic> json) {
    return AppFeaturesConfig(
      quickSparkEnabled: json['quickSparkEnabled'] as bool? ?? true,
      activitiesEnabled: json['activitiesEnabled'] as bool? ?? true,
      discEnabled: json['discEnabled'] as bool? ?? true,
      feedbackEnabled: json['feedbackEnabled'] as bool? ?? true,
    );
  }
}

class AppReleaseConfig {
  const AppReleaseConfig({
    this.latestVersion = '0.2.0+16',
    this.minSupportedVersion = '0.1.0+1',
    this.releaseNotes = '',
    this.downloadUrl = '',
  });

  final String latestVersion;
  final String minSupportedVersion;
  final String releaseNotes;
  final String downloadUrl;

  factory AppReleaseConfig.fromJson(Map<String, dynamic> json) {
    return AppReleaseConfig(
      latestVersion: (json['latestVersion'] as String? ?? '0.2.0+16').trim(),
      minSupportedVersion: (json['minSupportedVersion'] as String? ?? '0.1.0+1')
          .trim(),
      releaseNotes: (json['releaseNotes'] as String? ?? '').trim(),
      downloadUrl: (json['downloadUrl'] as String? ?? '').trim(),
    );
  }
}

class AppConfig {
  const AppConfig({
    this.revision = 1,
    this.contact = const AppContactConfig(),
    this.announcement = const AppAnnouncementConfig(),
    this.features = const AppFeaturesConfig(),
    this.appRelease = const AppReleaseConfig(),
  });

  static const AppConfig defaults = AppConfig();

  final int revision;
  final AppContactConfig contact;
  final AppAnnouncementConfig announcement;
  final AppFeaturesConfig features;
  final AppReleaseConfig appRelease;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported app config schemaVersion');
    }
    final revision = json['revision'];
    if (revision is! int || revision < 1) {
      throw const FormatException('Invalid app config revision');
    }
    final contactJson = json['contact'];
    final announcementJson = json['announcement'];
    final featuresJson = json['features'];
    final releaseJson = json['appRelease'];

    return AppConfig(
      revision: revision,
      contact: contactJson is Map<String, dynamic>
          ? AppContactConfig.fromJson(contactJson)
          : const AppContactConfig(),
      announcement: announcementJson is Map<String, dynamic>
          ? AppAnnouncementConfig.fromJson(announcementJson)
          : const AppAnnouncementConfig(),
      features: featuresJson is Map<String, dynamic>
          ? AppFeaturesConfig.fromJson(featuresJson)
          : const AppFeaturesConfig(),
      appRelease: releaseJson is Map<String, dynamic>
          ? AppReleaseConfig.fromJson(releaseJson)
          : const AppReleaseConfig(),
    );
  }
}

typedef AppConfigDownload =
    Future<({int status, String? body, String? etag})> Function(String? etag);

Future<({int status, String? body, String? etag})> downloadAppConfig(
  Uri uri,
  String? etag,
) async {
  if (uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    throw const FormatException('Invalid app config endpoint');
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 12));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (etag != null) request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
    final response = await request.close().timeout(const Duration(seconds: 12));
    if (response.statusCode == 304) {
      return (status: 304, body: null, etag: null);
    }
    if (response.statusCode != 200 || response.contentLength > 512 * 1024) {
      throw const FormatException('App config request failed');
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 12))) {
      if (bytes.length + chunk.length > 512 * 1024) {
        throw const FormatException('App config response too large');
      }
      bytes.addAll(chunk);
    }
    return (
      status: 200,
      body: utf8.decode(bytes),
      etag: response.headers.value(HttpHeaders.etagHeader),
    );
  } finally {
    client.close(force: true);
  }
}

abstract interface class AppConfigRepository {
  bool get isConfigured;
  Future<AppConfig> getConfig();
  Future<bool> refresh();
}

class InMemoryAppConfigRepository implements AppConfigRepository {
  InMemoryAppConfigRepository([this._config = AppConfig.defaults]);

  final AppConfig _config;

  @override
  bool get isConfigured => false;

  @override
  Future<AppConfig> getConfig() async => _config;

  @override
  Future<bool> refresh() async => false;
}

class CachedAppConfigRepository implements AppConfigRepository {
  CachedAppConfigRepository({required this.cacheFile, this.download});

  final File cacheFile;
  final AppConfigDownload? download;
  AppConfig? _memoryCache;
  String? _etag;

  @override
  bool get isConfigured => download != null;

  @override
  Future<AppConfig> getConfig() async {
    if (_memoryCache != null) return _memoryCache!;
    try {
      if (await cacheFile.exists()) {
        final raw = await cacheFile.readAsString();
        final wrapper = jsonDecode(raw);
        if (wrapper is Map<String, dynamic> && wrapper['config'] is String) {
          final parsed = AppConfig.fromJson(
            jsonDecode(wrapper['config'] as String) as Map<String, dynamic>,
          );
          _memoryCache = parsed;
          _etag = wrapper['etag'] as String?;
          return parsed;
        }
      }
    } catch (_) {
      // Keep damaged cache untouched and fall back to built-in defaults.
    }
    return AppConfig.defaults;
  }

  @override
  Future<bool> refresh() async {
    if (download == null) return false;
    final current = await getConfig();
    final response = await download!(_etag);
    if (response.status == 304) return false;
    if (response.status != 200 || response.body == null) return false;
    final decoded = jsonDecode(response.body!);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid app config JSON');
    }
    final next = AppConfig.fromJson(decoded);
    if (next.revision < current.revision) {
      return false;
    }
    await cacheFile.parent.create(recursive: true);
    final temp = File('${cacheFile.path}.tmp');
    await temp.writeAsString(
      jsonEncode({'config': response.body, 'etag': response.etag}),
      flush: true,
    );
    await temp.rename(cacheFile.path);
    _memoryCache = next;
    _etag = response.etag;
    return true;
  }
}
