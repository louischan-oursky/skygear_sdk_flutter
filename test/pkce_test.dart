import 'package:test/test.dart';
import 'package:skygear_sdk_flutter/src/pkce.dart';

void main() {
  group('generateCodeVerifier', () {
    test('length is 64', () {
      expect(generateCodeVerifier().length, equals(64));
    });
  });

  group('computeCodeChallenge', () {
    test('does not pad', () {
      final codeVerifier = 'secret';
      expect(computeCodeChallenge(codeVerifier),
          equals("K7gNU3sdo-OL0wNhqoVWhr3g6s1xYv72ol_pe_Unols"));
    });
  });

  group('encodeBase64UrlNoPad', () {
    test('does not pad', () {
      expect(encodeBase64UrlNoPad([0]), equals("AA"));
      expect(encodeBase64UrlNoPad([0, 1]), equals("AAE"));
      expect(encodeBase64UrlNoPad([0, 1, 2]), equals("AAEC"));
    });
  });
}
