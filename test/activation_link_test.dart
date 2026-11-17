import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/features/licensing/domain/models/activation_link.dart';

void main() {
  test('only accepts a credential on the exact configured HTTPS endpoint', () {
    const host = 'wefaq.example';
    expect(
      activationCodeFromLink(
        Uri.parse('https://wefaq.example/activate#abc.DEF_-'),
        host,
      ),
      'abc.DEF_-',
    );
    for (final link in [
      'http://wefaq.example/activate#abc.DEF',
      'https://evil.example/activate#abc.DEF',
      'https://user@wefaq.example/activate#abc.DEF',
      'https://wefaq.example:444/activate#abc.DEF',
      'https://wefaq.example/other#abc.DEF',
      'https://wefaq.example/activate?code=abc.DEF',
      'https://wefaq.example/activate#broken',
    ]) {
      expect(activationCodeFromLink(Uri.parse(link), host), isNull);
    }
    expect(
      activationCodeFromLink(
        Uri.parse('https://wefaq.example/activate#abc.DEF'),
        '',
      ),
      isNull,
    );
  });
}
