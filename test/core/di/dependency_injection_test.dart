import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/core/di/clients/getit_client.dart';
import 'package:task_manager_app/core/di/dependency_injection.dart';

void main() {
  group('dependency_injection.dart', () {
    test(
      '''
injector is
initialized
''',
      () {
        expect(injector, isNotNull);
      },
    );

    test(
      '''
injector implements
DI
''',
      () {
        expect(injector, isA<DI>());
      },
    );

    test(
      '''
injector uses
GetItClient
''',
      () {
        expect(injector, isA<GetItClient>());
      },
    );

    test(
      '''
injector remains
same instance
''',
      () {
        final first = injector;
        final second = injector;

        expect(identical(first, second), true);
      },
    );
  });
}
