import 'package:test/test.dart';
import 'package:skygear_sdk_flutter/src/url.dart';

void main() {
  group('encodeQuery', () {
    test('encode null to empty string', () {
      expect(encodeQuery(null), equals(''));
    });

    test('encode empty query to empty string', () {
      expect(encodeQuery([]), equals(''));
    });

    test('encode query with leading ?', () {
      expect(encodeQuery([QueryParam('a', 'b')]), equals('?a=b'));
    });

    test('encode more than one pair', () {
      expect(encodeQuery([QueryParam('a', 'b'), QueryParam('c', 'd')]),
          equals('?a=b&c=d'));
    });

    test('encode key and value', () {
      expect(
          encodeQuery(
              [QueryParam('key1', 'a b c'), QueryParam('key2', 'c d e')]),
          equals('?key1=a+b+c&key2=c+d+e'));
    });

    test('skip empty pair', () {
      expect(
          encodeQuery([
            QueryParam('', ''),
            QueryParam('a', 'b'),
            QueryParam('', ''),
            QueryParam('c', 'd')
          ]),
          equals('?a=b&c=d'));
    });

    test('omit empty value', () {
      expect(
          encodeQuery([
            QueryParam('a', ''),
            QueryParam('b', ''),
          ]),
          equals('?a&b'));
    });

    test('support empty name', () {
      expect(
          encodeQuery([
            QueryParam('', 'a'),
            QueryParam('', 'b'),
          ]),
          equals('?=a&=b'));
    });
  });
}
