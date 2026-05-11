import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:task_manager_app/core/di/clients/getit_client.dart';

void main() {
  late GetItClient client;
  late GetIt getIt;

  setUp(() async {
    client = GetItClient();
    getIt = client.instance;

    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('GetItClient', () {
    test(
      '''
instance returns
GetIt singleton
''',
      () {
        expect(client.instance, isA<GetIt>());
      },
    );

    test(
      '''
get resolves
registered dependency
''',
      () {
        getIt.registerSingleton<String>('test-value');

        final result = client.get<String>();

        expect(result, 'test-value');
      },
    );

    test(
      '''
allReady completes
successfully
''',
      () async {
        getIt.registerSingleton<int>(123);

        await client.allReady();

        expect(true, true);
      },
    );

    test(
      '''
multiple clients share
same GetIt instance
''',
      () {
        final anotherClient = GetItClient();

        expect(identical(client.instance, anotherClient.instance), true);
      },
    );

    test(
      '''
get throws assertion
for unregistered type
''',
      () {
        expect(() => client.get<double>(), throwsA(isA<AssertionError>()));
      },
    );
  });
}
