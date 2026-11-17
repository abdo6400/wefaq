import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/models/question.dart';
import '../domain/repositories/question_repository.dart';
import '../domain/repositories/question_updates.dart';
import 'json_asset_question_repository.dart';

typedef CatalogDownload = Future<CatalogResponse> Function(String? etag);

class CatalogResponse {
  const CatalogResponse(this.status, {this.body, this.etag});
  final int status;
  final String? body;
  final String? etag;
}

/// Downloads only from the configured HTTPS URL. Redirects are never followed.
Future<CatalogResponse> downloadCatalog(Uri uri, String? etag) async {
  if (uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    throw const FormatException('Invalid catalog endpoint');
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (etag != null) request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode == 304) return const CatalogResponse(304);
    if (response.statusCode != 200 ||
        response.contentLength > 5 * 1024 * 1024) {
      throw const FormatException('Catalog request failed');
    }
    final bytes = <int>[];
    final elapsed = Stopwatch()..start();
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (elapsed.elapsed > const Duration(seconds: 20)) {
        throw const FormatException('Catalog download timed out');
      }
      if (bytes.length + chunk.length > 5 * 1024 * 1024) {
        throw const FormatException('Catalog too large');
      }
      bytes.addAll(chunk);
    }
    return CatalogResponse(
      200,
      body: utf8.decode(bytes),
      etag: response.headers.value(HttpHeaders.etagHeader),
    );
  } finally {
    client.close(force: true);
  }
}

/// Validates full snapshots before writing them; never clears an old cache on failure.
class CachedQuestionRepository implements QuestionRepository, QuestionUpdates {
  CachedQuestionRepository({
    required this.cacheFile,
    this.download,
    this.bundleLoader,
  }) {
    _delegate = JsonAssetQuestionRepository(customLoader: _load);
  }
  final File cacheFile;
  final CatalogDownload? download;
  final JsonStringLoader? bundleLoader;
  late final JsonAssetQuestionRepository _delegate;
  Future<void> _tail = Future.value();
  @override
  bool get isConfigured => download != null;

  Future<String> _bundle() =>
      bundleLoader?.call() ??
      rootBundle.loadString('assets/content/questions_v1.json');

  Map<String, dynamic> _parse(String raw) {
    if (utf8.encode(raw).length > 5 * 1024 * 1024) {
      throw const FormatException('Catalog too large');
    }
    final obj = jsonDecode(raw);
    if (obj is! Map<String, dynamic> ||
        obj['schemaVersion'] != 1 ||
        obj['revision'] is! int ||
        (obj['revision'] as int) < 1 ||
        obj['publishedAt'] is! String ||
        DateTime.tryParse(obj['publishedAt'] as String)?.isUtc != true ||
        obj['questions'] is! List ||
        (obj['questions'] as List).isEmpty ||
        (obj['questions'] as List).length > 100000) {
      throw const FormatException('Invalid catalog');
    }
    final ids = <String>{};
    for (final item in obj['questions'] as List) {
      if (item is! Map<String, dynamic> ||
          item['id'] is! String ||
          (item['id'] as String).trim().isEmpty ||
          (item['id'] as String).length > 200 ||
          !ids.add(item['id'] as String) ||
          item['text'] is! String ||
          (item['text'] as String).trim().isEmpty ||
          (item['text'] as String).length > 4000 ||
          (item['clarification'] != null &&
              (item['clarification'] is! String ||
                  (item['clarification'] as String).length > 4000)) ||
          !Topic.values.any((e) => e.name == item['topic']) ||
          !Depth.values.any((e) => e.name == item['depth']) ||
          item['suitableModes'] is! List ||
          (item['suitableModes'] as List).isEmpty ||
          (item['suitableModes'] as List).any(
            (m) => !ConversationMode.values.any((e) => e.name == m),
          ) ||
          (item['suitableModes'] as List).toSet().length !=
              (item['suitableModes'] as List).length ||
          item['isDevelopmentOnly'] != false) {
        throw const FormatException('Invalid catalog item');
      }
    }
    return obj;
  }

  Future<Map<String, dynamic>?> _cached() async {
    if (!await cacheFile.exists()) return null;
    final raw = await cacheFile.readAsString();
    final wrapper = jsonDecode(raw);
    if (wrapper is! Map<String, dynamic> ||
        wrapper['catalog'] is! String ||
        (wrapper['etag'] != null && wrapper['etag'] is! String)) {
      throw const FormatException('Invalid cache');
    }
    final catalog = _parse(wrapper['catalog'] as String);
    return {
      'catalog': catalog,
      'raw': wrapper['catalog'],
      'etag': wrapper['etag'],
    };
  }

  Future<String> _load() async {
    try {
      final cached = await _cached();
      if (cached != null) return cached['raw'] as String;
    } catch (_) {
      // Keep the damaged file for recovery; the bundled catalog remains usable.
    }
    return _bundle();
  }

  @override
  Future<bool> update() {
    final future = _tail.then((_) => _update());
    _tail = future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return future;
  }

  Future<bool> _update() async {
    if (download == null) throw StateError('Catalog endpoint not configured');
    final old = await _cached();
    final response = await download!(old?['etag'] as String?);
    if (response.status == 304 && old != null && old['etag'] != null) {
      return false;
    }
    if (response.status != 200 || response.body == null) {
      throw const FormatException('Invalid catalog response');
    }
    final next = _parse(response.body!);
    final previousRevision = old == null
        ? 0
        : (old['catalog'] as Map<String, dynamic>)['revision'] as int;
    if ((next['revision'] as int) <= previousRevision) {
      throw const FormatException('Catalog revision did not increase');
    }
    final baselineRaw = old == null ? await _bundle() : old['raw'] as String;
    final baseline = jsonDecode(baselineRaw) as Map<String, dynamic>;
    final oldIds = (baseline['questions'] as List)
        .map((q) => (q as Map)['id'])
        .toSet();
    final newIds = (next['questions'] as List)
        .map((q) => (q as Map)['id'])
        .toSet();
    if (!newIds.containsAll(oldIds)) {
      throw const FormatException('Catalog removes existing questions');
    }
    final tag = response.etag;
    if (tag != null &&
        (tag.length > 1024 || tag.contains('\r') || tag.contains('\n'))) {
      throw const FormatException('Invalid ETag');
    }
    await cacheFile.parent.create(recursive: true);
    final temp = File('${cacheFile.path}.tmp');
    await temp.writeAsString(
      jsonEncode({'catalog': response.body, 'etag': tag}),
      flush: true,
    );
    await temp.rename(cacheFile.path);
    _delegate.invalidateCache();
    return true;
  }

  @override
  Future<List<Question>> getQuestions({
    Topic? topic,
    required Depth depth,
    ConversationMode? mode,
  }) => _delegate.getQuestions(topic: topic, depth: depth, mode: mode);
  @override
  Future<QuestionQueryResult> queryQuestions(QuestionFilter filter) =>
      _delegate.queryQuestions(filter);
}
