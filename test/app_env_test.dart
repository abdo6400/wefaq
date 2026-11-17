import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/config/app_env.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.content);

  final String content;

  @override
  Future<ByteData> load(String key) =>
      throw StateError('Unexpected binary asset load: $key');

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == AppEnv.assetPath) return content;
    throw StateError('Missing asset: $key');
  }
}

void main() {
  test('parses env entries with comments, quotes, and equals signs', () {
    final parsed = AppEnv.parse('''
# comment line

WEFAQ_QUESTIONS_API_URL=https://wefaq-questions-api.vercel.app/v1/question-catalog
WEFAQ_LINK_HOST="example.com"
export WEFAQ_LICENSE_PUBLIC_KEY='abc=def=='
INVALID_LINE_WITHOUT_EQUALS
''');

    expect(
      parsed[AppEnv.questionsApiUrlKey],
      'https://wefaq-questions-api.vercel.app/v1/question-catalog',
    );
    expect(parsed[AppEnv.linkHostKey], 'example.com');
    expect(parsed[AppEnv.licensePublicKeyKey], 'abc=def==');
    expect(parsed.containsKey('INVALID_LINE_WITHOUT_EQUALS'), isFalse);
  });

  test('compile-time defines override .env values when non-empty', () {
    final env = AppEnv.fromValues(
      envFile: {
        AppEnv.questionsApiUrlKey:
            'https://wefaq-questions-api.vercel.app/v1/question-catalog',
        AppEnv.linkHostKey: 'env.example.com',
      },
      defines: {
        AppEnv.questionsApiUrlKey: '',
        AppEnv.linkHostKey: 'override.example.com',
      },
    );

    expect(
      env.questionsApiUrl,
      'https://wefaq-questions-api.vercel.app/v1/question-catalog',
    );
    expect(env.linkHost, 'override.example.com');
  });

  test(
    'loads .env asset via AssetBundle and handles bundled .env safely',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final fakeEnv = await AppEnv.load(
        bundle: _FakeAssetBundle(
          'WEFAQ_QUESTIONS_API_URL=https://wefaq-questions-api.vercel.app/v1/question-catalog\n',
        ),
      );
      expect(
        fakeEnv.questionsApiUrl,
        'https://wefaq-questions-api.vercel.app/v1/question-catalog',
      );

      final bundled = await AppEnv.load();
      expect(bundled.questionsApiUrl, isA<String>());
    },
  );
}
