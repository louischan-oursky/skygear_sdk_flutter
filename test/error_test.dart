import 'package:test/test.dart';
import 'package:skygear_sdk_flutter/skygear_sdk_flutter.dart';

void main() {
  group('decodeError', () {
    test('decode skygear error', () {
      final actual = decodeError({
        'name': 'name',
        'reason': 'reason',
        'message': 'message',
        'code': 401,
        'info': {
          'a': 'b',
        },
      });
      final expected = SkygearException(
          name: 'name',
          reason: 'reason',
          message: 'message',
          code: 401,
          info: {'a': 'b'});

      expect(actual, isA<SkygearException>());
      expect(actual.name, equals(expected.name));
      expect(actual.reason, equals(expected.reason));
      expect(actual.message, equals(expected.message));
      expect(actual.code, equals(expected.code));
      expect(actual.info, equals(expected.info));
    });

    test('decode any other thing by simply returning it', () {
      expect(decodeError(), equals(null));
      expect(decodeError(null), equals(null));
      expect(decodeError(0), equals(0));
      expect(decodeError(""), equals(""));
      expect(decodeError(false), equals(false));
    });
  });
}
