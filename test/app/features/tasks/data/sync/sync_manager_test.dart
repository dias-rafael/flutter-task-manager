import 'dart:math';

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

class MockPatientTasksRepository extends Mock
    implements PatientTasksRepository {}

class _FakeRandom extends Fake implements Random {
  @override
  int nextInt(int max) => 500;
}

void main() {
  setUpAll(() {
    registerFallbackValue(makeTask());
    registerFallbackValue(TaskStatus.requested);

    registerFallbackValue(
      SyncOperationLocalModel(
        id: '',
        taskId: '',
        type: '',
        payloadJson: '{}',
        retryCount: 0,
        createdAt: DateTime(2000),
        nextRetryAt: DateTime(2000),
      ),
    );
  });

  group('SyncManager', () {
    late MockRemoteDatasource remote;
    late MockLocalDatasource local;
    late MockPatientTasksRepository repository;
    late SyncManager syncManager;
    late SyncOperationLocalModel operation;
    late String rollbackMessage;

    SyncOperationLocalModel buildOperation() {
      return SyncOperationLocalModel(
        id: 'op-1',
        taskId: 'task-1',
        type: 'update_status',
        payloadJson: '''
{
  "task_id": "task-1",
  "version": 1,
  "status": "completed"
}
''',
        retryCount: 0,
        createdAt: DateTime.now(),
        nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
    }

    setUp(() {
      remote = MockRemoteDatasource();
      local = MockLocalDatasource();
      repository = MockPatientTasksRepository();
      rollbackMessage = '';
      operation = buildOperation();

      syncManager = SyncManager(
        remote: remote,
        local: local,
        repository: repository,
        retryPolicy: RetryPolicy(random: _FakeRandom()),
        onRollbackMessage: (message) {
          rollbackMessage = message;
        },
      );
    });

    test(
      '''
removes operation and
triggers rollback message
when ValidationException occurs
''',
      () async {
        when(
          () => local.getPendingOperations(),
        ).thenAnswer((_) async => [operation]);

        when(
          () => remote.patchStatus(
            taskId: any(named: 'taskId'),
            version: any(named: 'version'),
            status: any(named: 'status'),
          ),
        ).thenThrow(ValidationException(message: 'Invalid status'));

        final serverTask = makeTask(
          id: 'task-1',
          title: 'Recovered Task',
          status: TaskStatus.onHold,
        );

        when(
          () => remote.fetchTask(operation.taskId),
        ).thenAnswer((_) async => serverTask);

        when(() => local.upsertTask(any())).thenAnswer((_) async {});

        when(() => local.removeOperation(any())).thenAnswer((_) async {});

        await syncManager.processQueue();

        verify(() => local.removeOperation(operation.id)).called(1);
        verify(() => local.upsertTask(serverTask)).called(1);

        expect(rollbackMessage, '''
This change could not be synced
and was reverted.
''');
      },
    );

    test('removes operation when patch succeeds', () async {
      when(
        () => local.getPendingOperations(),
      ).thenAnswer((_) async => [operation]);

      when(
        () => remote.patchStatus(
          taskId: any(named: 'taskId'),
          version: any(named: 'version'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});

      when(() => local.removeOperation(any())).thenAnswer((_) async {});

      await syncManager.processQueue();

      verify(() => local.removeOperation(operation.id)).called(1);
      verifyNever(() => remote.fetchTask(any()));
    });

    test(
      'on ConflictException fetches server task and clears operation',
      () async {
        when(
          () => local.getPendingOperations(),
        ).thenAnswer((_) async => [operation]);

        when(
          () => remote.patchStatus(
            taskId: any(named: 'taskId'),
            version: any(named: 'version'),
            status: any(named: 'status'),
          ),
        ).thenThrow(ConflictException(message: 'version mismatch'));

        final serverTask = makeTask(
          id: 'task-1',
          title: 'Server wins',
          status: TaskStatus.completed,
        );

        when(
          () => remote.fetchTask(operation.taskId),
        ).thenAnswer((_) async => serverTask);

        when(() => local.upsertTask(any())).thenAnswer((_) async {});

        when(() => local.removeOperation(any())).thenAnswer((_) async {});

        await syncManager.processQueue();

        verify(() => local.upsertTask(serverTask)).called(1);
        verify(() => local.removeOperation(operation.id)).called(1);
      },
    );

    test(
      'on generic failure schedules retry via local upsertOperation',
      () async {
        when(
          () => local.getPendingOperations(),
        ).thenAnswer((_) async => [operation]);

        when(
          () => remote.patchStatus(
            taskId: any(named: 'taskId'),
            version: any(named: 'version'),
            status: any(named: 'status'),
          ),
        ).thenThrow(Exception('network'));

        when(() => local.upsertOperation(any())).thenAnswer((_) async {});

        final before = DateTime.now();

        await syncManager.processQueue();

        final captured = verify(
          () => local.upsertOperation(captureAny()),
        ).captured;

        expect(captured, hasLength(1));

        final updated = captured.single as SyncOperationLocalModel;

        expect(updated.id, operation.id);
        expect(updated.retryCount, 1);

        final untilRetry = updated.nextRetryAt
            .difference(before)
            .inMilliseconds;

        expect(untilRetry, inInclusiveRange(2400, 2600));
      },
    );

    test(
      'on generic failure past max retries removes op and reverts from server',
      () async {
        final op = operation.copyWith(retryCount: 2);

        syncManager = SyncManager(
          remote: remote,
          local: local,
          repository: repository,
          retryPolicy: RetryPolicy(maxRetries: 2, random: _FakeRandom()),
          onRollbackMessage: (message) {
            rollbackMessage = message;
          },
        );

        when(
          () => local.getPendingOperations(),
        ).thenAnswer((_) async => [op]);

        when(
          () => remote.patchStatus(
            taskId: any(named: 'taskId'),
            version: any(named: 'version'),
            status: any(named: 'status'),
          ),
        ).thenThrow(Exception('network'));

        final serverTask = makeTask(
          id: 'task-1',
          title: 'Server copy',
          status: TaskStatus.inProgress,
        );

        when(
          () => remote.fetchTask(op.taskId),
        ).thenAnswer((_) async => serverTask);

        when(() => local.upsertTask(any())).thenAnswer((_) async {});

        when(() => local.removeOperation(any())).thenAnswer((_) async {});

        await syncManager.processQueue();

        verify(() => local.removeOperation(op.id)).called(1);
        verify(() => local.upsertTask(serverTask)).called(1);
        verifyNever(() => local.upsertOperation(any()));

        expect(rollbackMessage, contains('several tries'));
        expect(rollbackMessage, contains('reverted'));
      },
    );
  });
}
