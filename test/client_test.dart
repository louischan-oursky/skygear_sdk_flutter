import 'package:test/test.dart';
import 'package:skygear_sdk_flutter/skygear_sdk_flutter.dart';

void main() {
  test('ApiClient', () {
    final c = ApiClient(apiKey: 'api_key', endpoint: 'http://localhost:3000/');
    expect(c.apiKey, equals('api_key'));
    expect(c.endpoint, equals('http://localhost:3000'));
  });
}
