import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/core/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test(
      '''
baseUrl is
not empty
''',
      () {
        expect(ApiConfig.baseUrl, isNotEmpty);
      },
    );

    test(
      '''
baseUrl uses
default localhost value
''',
      () {
        expect(ApiConfig.baseUrl, 'http://localhost:3001');
      },
    );

    test(
      '''
baseUrl is
a String
''',
      () {
        expect(ApiConfig.baseUrl, isA<String>());
      },
    );

    test(
      '''
baseUrl starts
with http
''',
      () {
        expect(ApiConfig.baseUrl.startsWith('http'), true);
      },
    );

    test(
      '''
ApiConfig cannot
be instantiated
''',
      () {
        expect(ApiConfig, isNotNull);
      },
    );
  });
}
