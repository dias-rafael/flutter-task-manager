import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:task_manager_app/app/features/tasks/data/data.dart';
import 'package:task_manager_app/app/features/tasks/data/sync/retry_policy.dart';
import 'package:task_manager_app/app/features/tasks/data/sync/sync_manager.dart';
import 'package:task_manager_app/app/features/tasks/domain/domain.dart';
import 'package:task_manager_app/app/features/tasks/presentation/bloc/patient_tasks_bloc.dart';
import 'package:task_manager_app/core/di/dependency_injection.dart';
import 'package:task_manager_app/core/di/setup_injection.dart';
import 'package:task_manager_app/core/network/network.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final directory = Directory.systemTemp.createTempSync();

    return directory.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt getIt;

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  setUp(() async {
    getIt = (injector as dynamic).instance as GetIt;

    await getIt.reset();
    await setupDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('Dependency Injection', () {
    test(
      '''
RetryPolicy is
registered
''',
      () {
        expect(getIt.isRegistered<RetryPolicy>(), true);
      },
    );

    test(
      '''
SyncManager is
registered
''',
      () {
        expect(getIt.isRegistered<SyncManager>(), true);
      },
    );

    test(
      '''
SyncManager resolves
correctly
''',
      () {
        final manager = getIt<SyncManager>();

        expect(manager, isNotNull);
      },
    );

    test(
      '''
Network is
registered
''',
      () {
        expect(getIt.isRegistered<Network>(), true);
      },
    );

    test(
      '''
remote datasource
is registered
''',
      () {
        expect(getIt.isRegistered<PatientTasksRemoteDataSource>(), true);
      },
    );

    test(
      '''
local datasource
is registered
''',
      () {
        expect(getIt.isRegistered<PatientTasksLocalDataSource>(), true);
      },
    );

    test(
      '''
repository is
registered
''',
      () {
        expect(getIt.isRegistered<PatientTasksRepository>(), true);
      },
    );

    test(
      '''
repository resolves
correctly
''',
      () {
        final repository = getIt<PatientTasksRepository>();

        expect(repository, isNotNull);
      },
    );

    test(
      '''
PatientTasksBloc
is registered
''',
      () {
        expect(getIt.isRegistered<PatientTasksBloc>(), true);
      },
    );

    test(
      '''
PatientTasksBloc resolves
correctly
''',
      () {
        final bloc = getIt<PatientTasksBloc>();

        expect(bloc, isNotNull);
      },
    );

    test(
      '''
repository is singleton
''',
      () {
        final first = getIt<PatientTasksRepository>();
        final second = getIt<PatientTasksRepository>();

        expect(identical(first, second), true);
      },
    );

    test(
      '''
bloc is singleton
''',
      () {
        final first = getIt<PatientTasksBloc>();
        final second = getIt<PatientTasksBloc>();

        expect(identical(first, second), true);
      },
    );

    test(
      '''
sync manager is singleton
''',
      () {
        final first = getIt<SyncManager>();
        final second = getIt<SyncManager>();

        expect(identical(first, second), true);
      },
    );
  });
}
