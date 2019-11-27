import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final rand = Random.secure();

const alphabet =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

int randomBetween(int from, int to) {
  final randomDouble = rand.nextDouble();
  return ((to - from) * randomDouble).toInt() + from;
}

String randomString(String alphabet, int length) {
  final buf = StringBuffer();
  for (var i = 0; i < length; ++i) {
    buf.write(alphabet[randomBetween(0, alphabet.length)]);
  }
  return buf.toString();
}

String generateCodeVerifier() {
  return randomString(alphabet, 64);
}

String encodeBase64UrlNoPad(List<int> bytes) {
  final padded = base64Url.encode(bytes);
  return padded.replaceAll("=", "");
}

String computeCodeChallenge(String codeVerifier) {
  final bytes = utf8.encode(codeVerifier);
  final digest = sha256.convert(bytes);
  return encodeBase64UrlNoPad(digest.bytes);
}
