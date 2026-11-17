import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../sessions/domain/models/question.dart';
import '../domain/models/activity.dart';
import '../domain/repositories/activity_repository.dart';
import 'in_memory_activity_repository.dart';

typedef ActivityCatalogDownload =
    Future<({int status, String? body, String? etag})> Function(String? etag);

Future<({int status, String? body, String? etag})> downloadActivityCatalog(
  Uri uri,
  String? etag,
) async {
  if (uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    throw const FormatException('Invalid activity catalog endpoint');
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 15));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (etag != null) request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode == 304) {
      return (status: 304, body: null, etag: null);
    }
    if (response.statusCode != 200 ||
        response.contentLength > 2 * 1024 * 1024) {
      throw const FormatException('Activity catalog request failed');
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 15))) {
      if (bytes.length + chunk.length > 2 * 1024 * 1024) {
        throw const FormatException('Activity catalog too large');
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

/// Validates and caches remote activity snapshots, falling back to built-in prototypes.
class CachedActivityRepository implements ActivityRepository {
  CachedActivityRepository({required this.cacheFile, this.download});

  final File cacheFile;
  final ActivityCatalogDownload? download;
  final InMemoryActivityRepository _fallback = InMemoryActivityRepository();
  List<Activity>? _cached;
  String? _etag;

  bool get isConfigured => download != null;

  List<Activity> _parseSnapshot(String raw) {
    final obj = jsonDecode(raw);
    if (obj is! Map<String, dynamic> ||
        obj['schemaVersion'] != 1 ||
        obj['revision'] is! int ||
        (obj['revision'] as int) < 1 ||
        obj['activities'] is! List ||
        (obj['activities'] as List).isEmpty) {
      throw const FormatException('Invalid activity catalog');
    }
    final items = <Activity>[];
    final ids = <String>{};
    for (final rawItem in obj['activities'] as List) {
      if (rawItem is! Map<String, dynamic>) {
        throw const FormatException('Invalid activity entry');
      }
      if (rawItem['isDevelopmentOnly'] != false) {
        throw const FormatException('Unapproved activity in remote catalog');
      }
      final activity = Activity.fromJson(rawItem);
      if (activity.title.trim().isEmpty ||
          activity.situation.trim().isEmpty ||
          !ids.add(activity.id)) {
        throw const FormatException('Invalid activity fields');
      }
      items.add(activity);
    }
    return items;
  }

  Future<List<Activity>> _loadAll() async {
    if (_cached != null) return _cached!;
    try {
      if (await cacheFile.exists()) {
        final raw = await cacheFile.readAsString();
        final wrapper = jsonDecode(raw);
        if (wrapper is Map<String, dynamic> && wrapper['catalog'] is String) {
          final parsed = _parseSnapshot(wrapper['catalog'] as String);
          _cached = parsed;
          _etag = wrapper['etag'] as String?;
          return parsed;
        }
      }
    } catch (_) {
      // Fall back safely to bundled prototypes.
    }
    return _fallback.getActivities();
  }

  Future<bool> update() async {
    if (download == null) return false;
    final response = await download!(_etag);
    if (response.status == 304) return false;
    if (response.status != 200 || response.body == null) {
      throw const FormatException('Invalid activity catalog response');
    }
    final next = _parseSnapshot(response.body!);
    await cacheFile.parent.create(recursive: true);
    final temp = File('${cacheFile.path}.tmp');
    await temp.writeAsString(
      jsonEncode({'catalog': response.body, 'etag': response.etag}),
      flush: true,
    );
    await temp.rename(cacheFile.path);
    _cached = next;
    _etag = response.etag;
    return true;
  }

  @override
  Future<List<Activity>> getActivities({
    Topic? topic,
    ActivityType? type,
    int? limit,
  }) async {
    final all = await _loadAll();
    var results = all.where((activity) {
      if (topic != null && activity.topic != topic) return false;
      if (type != null && activity.type != type) return false;
      return true;
    }).toList();
    if (limit != null && limit > 0 && results.length > limit) {
      results = results.sublist(0, limit);
    }
    return results;
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    final all = await _loadAll();
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}
