import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/sessions/data/cached_question_repository.dart';
import 'package:wefaq/features/sessions/domain/models/question.dart';

Map<String, Object> question(String id, {bool draft = false}) => {
  'id': id,
  'text': 'سؤال $id',
  'topic': 'communication',
  'depth': 'introductory',
  'suitableModes': ['together', 'phone'],
  'isDevelopmentOnly': draft,
};
String catalog(int revision, List<Map<String, Object>> questions) =>
    jsonEncode({
      'schemaVersion': 1,
      'revision': revision,
      'publishedAt': '2026-01-01T00:00:00Z',
      'questions': questions,
    });

void main() {
  late Directory dir;
  late File cache;
  final bundled = jsonEncode({
    'version': 1,
    'questions': [question('q1', draft: true)],
  });
  test('rejects non-HTTPS and credential-bearing endpoints', () async {
    await expectLater(
      downloadCatalog(Uri.parse('http://example.com/catalog'), null),
      throwsFormatException,
    );
    await expectLater(
      downloadCatalog(Uri.parse('https://user:pass@example.com/catalog'), null),
      throwsFormatException,
    );
  });
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('wefaq_catalog_test');
    cache = File('${dir.path}/catalog.json');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });

  test(
    'updates, caches on disk, sends etag and survives restart offline',
    () async {
      String? sentTag;
      var calls = 0;
      final repo = CachedQuestionRepository(
        cacheFile: cache,
        bundleLoader: () async => bundled,
        download: (tag) async {
          sentTag = tag;
          return calls++ == 0
              ? CatalogResponse(
                  200,
                  body: catalog(1, [question('q1'), question('q2')]),
                  etag: '"v1"',
                )
              : const CatalogResponse(304);
        },
      );
      expect((await repo.getQuestions(depth: Depth.introductory)).length, 1);
      expect(await repo.update(), isTrue);
      expect((await repo.getQuestions(depth: Depth.introductory)).length, 2);
      expect(await repo.update(), isFalse);
      expect(sentTag, '"v1"');
      final restarted = CachedQuestionRepository(
        cacheFile: cache,
        bundleLoader: () async => bundled,
      );
      expect(
        (await restarted.getQuestions(depth: Depth.introductory)).length,
        2,
      );
    },
  );

  test('invalid, unreviewed, duplicate, old and removed items keep last good cache', () async {
    var body = catalog(2, [question('q1'), question('q2')]);
    final repo = CachedQuestionRepository(
      cacheFile: cache,
      bundleLoader: () async => bundled,
      download: (_) async => CatalogResponse(200, body: body),
    );
    await repo.update();
    final original = await cache.readAsString();
    for (final candidate in [
      'bad json',
      catalog(3, [question('q1'), question('q1')]),
      catalog(3, [question('q1', draft: true), question('q2')]),
      catalog(2, [question('q1'), question('q2')]),
      catalog(3, [question('q1')]),
    ]) {
      body = candidate;
      await expectLater(repo.update(), throwsFormatException);
      expect(await cache.readAsString(), original);
      expect((await repo.getQuestions(depth: Depth.introductory)).length, 2);
    }
  });

  test('network and corrupt cache failure preserve files and fall back to bundled content', () async {
    await cache.writeAsString('broken');
    final repo = CachedQuestionRepository(
      cacheFile: cache,
      bundleLoader: () async => bundled,
      download: (_) async => throw const SocketException('offline'),
    );
    expect(
      (await repo.getQuestions(depth: Depth.introductory)).single.id,
      'q1',
    );
    await expectLater(repo.update(), throwsFormatException);
    expect(await cache.readAsString(), 'broken');
    await cache.delete();
    await expectLater(repo.update(), throwsA(isA<SocketException>()));
    expect(await cache.exists(), isFalse);
  });

  test('newer valid revision replaces the existing cache', () async {
    var revision = 1;
    final repo = CachedQuestionRepository(
      cacheFile: cache,
      bundleLoader: () async => bundled,
      download: (_) async => CatalogResponse(
        200,
        body: catalog(revision, [
          question('q1'),
          if (revision > 1) question('q2'),
        ]),
      ),
    );
    await repo.update();
    revision = 2;
    expect(await repo.update(), isTrue);
    expect((await repo.getQuestions(depth: Depth.introductory)).length, 2);
  });
}
