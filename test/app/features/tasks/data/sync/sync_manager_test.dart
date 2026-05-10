import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/app/features/tasks/data/data.dart';
import 'package:task_manager_app/app/features/tasks/data/sync/retry_policy.dart';
import 'package:task_manager_app/app/features/tasks/data/sync/sync_manager.dart';
import 'package:task_manager_app/app/features/tasks/domain/domain.dart';
import 'package:task_manager_app/core/network/network_types.dart';

import '../../presentation/bloc/test_helpers.dart';

class MockRemoteDatasource extends Mock
    implements PatientTasksRemoteDataSource {}

class MockLocalDatasource extends Mock implements PatientTasksLocalDataSource {}

class MockRepository extends Mock implements PatientTasksRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(makeTask());
  });
  group('SyncManager', () {
    late MockRemoteDatasource remote;

    late MockLocalDatasource local;

    late MockRepository repository;

    late SyncManager syncManager;

    late SyncOperationLocalModel operation;

    late String rollbackMessage;

    setUp(() {
      remote = MockRemoteDatasource();

      local = MockLocalDatasource();

      repository = MockRepository();

      rollbackMessage = '';

      operation = SyncOperationLocalModel(
        id: 'op-1',
        taskId: 'task-1',
        type: 'update_status',

        // IMPORTANT:
        // adapt if your payload
        // structure differs
        payloadJson: '''
{
  "task_id": "task-1",
  "version": 1,
  "status": "completed"
}
''',

        retryCount: 0,

        createdAt: DateTime.now(),

        nextRetryAt: DateTime.now(),
      );

      syncManager = SyncManager(
        repository: repository,

        remote: remote,

        local: local,

        retryPolicy: const RetryPolicy(),

        onRollbackMessage: (message) {
          rollbackMessage = message;
        },
      );
    });

    // ===================================================
    // VALIDATION ROLLBACK
    // ===================================================

    test(
      '''
removes operation and
triggers rollback message
when ValidationException occurs
''',
      () async {
        // --------------------------------------------------
        // QUEUE
        // --------------------------------------------------

        when(
          () => local.getPendingOperations(),
        ).thenAnswer((_) async => [operation]);

        // --------------------------------------------------
        // REMOTE PATCH FAILURE
        // --------------------------------------------------

        when(
          () => remote.patchStatus(
            taskId: any(named: 'taskId'),
            version: any(named: 'version'),
            status: any(named: 'status'),
          ),
        ).thenThrow(ValidationException(message: 'Invalid status'));

        // --------------------------------------------------
        // FETCH REMOTE TASK
        // --------------------------------------------------

        final serverTask = makeTask(
          id: 'task-1',
          title: 'Recovered Task',
          status: TaskStatus.onHold,
        );

        when(
          () => remote.fetchTask(operation.taskId),
        ).thenAnswer((_) async => serverTask);

        // --------------------------------------------------
        // UPSERT TASK
        // --------------------------------------------------

        when(() => local.upsertTask(any())).thenAnswer((_) async {});

        // --------------------------------------------------
        // REMOVE OPERATION
        // --------------------------------------------------

        when(() => local.removeOperation(any())).thenAnswer((_) async {});

        // --------------------------------------------------
        // PROCESS QUEUE
        // --------------------------------------------------

        await syncManager.processQueue();

        // --------------------------------------------------
        // ASSERT REMOVAL
        // --------------------------------------------------

        verify(() => local.removeOperation(operation.id)).called(1);

        // --------------------------------------------------
        // ASSERT SERVER RESTORE
        // --------------------------------------------------

        verify(() => local.upsertTask(serverTask)).called(1);

        // --------------------------------------------------
        // ASSERT ROLLBACK MESSAGE
        // --------------------------------------------------

        expect(rollbackMessage.isNotEmpty, true);
      },
    );
  });
}
