import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/app/features/tasks/data/data.dart';
import 'package:task_manager_app/app/features/tasks/domain/domain.dart';
import 'package:task_manager_app/core/network/network_types.dart';

import '../../helpers/test_helpers.dart';

class MockLocal extends Mock implements PatientTasksLocalDataSource {}

class MockRemote extends Mock implements PatientTasksRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(makeTask());
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

  group('PatientTasksRepositoryImpl', () {
    late MockLocal local;
    late MockRemote remote;
    late PatientTasksRepositoryImpl repository;

    setUp(() {
      local = MockLocal();
      remote = MockRemote();
      repository = PatientTasksRepositoryImpl(local: local, remote: remote);
    });

    test('refresh replaces local tasks from remote', () async {
      final tasks = [makeTask(title: 'From API')];

      when(() => remote.fetchTasks()).thenAnswer((_) async => tasks);

      when(() => local.saveTasks(any())).thenAnswer((_) async {});

      await repository.refresh();

      verify(() => local.saveTasks(tasks)).called(1);
    });

    test('refresh maps DioException to NetworkException', () async {
      when(() => remote.fetchTasks()).thenThrow(
        DioException(requestOptions: RequestOptions(), message: 'offline'),
      );

      expect(() => repository.refresh(), throwsA(isA<NetworkException>()));
    });

    test('searchTasks page 0 replaces local tasks', () async {
      final tasks = [makeTask(id: 'a')];

      when(
        () => remote.fetchTasks(
          query: any(named: 'query'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => tasks);

      when(() => local.replaceTasks(any())).thenAnswer((_) async {});

      await repository.searchTasks(query: 'q', page: 0);

      verify(() => local.replaceTasks(tasks)).called(1);
      verifyNever(() => local.upsertTask(any()));
    });

    test('searchTasks page 1 upserts each task', () async {
      final tasks = [makeTask(), makeTask(id: '2', title: 'B')];

      when(
        () => remote.fetchTasks(
          query: any(named: 'query'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => tasks);

      when(() => local.upsertTask(any())).thenAnswer((_) async {});

      await repository.searchTasks(query: '', page: 1);

      verify(() => local.upsertTask(tasks[0])).called(1);
      verify(() => local.upsertTask(tasks[1])).called(1);
      verifyNever(() => local.replaceTasks(any()));
    });

    test(
      'searchTasks swallows non-cancel Dio errors (offline-first)',
      () async {
        when(
          () => remote.fetchTasks(
            query: any(named: 'query'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        when(() => local.replaceTasks(any())).thenAnswer((_) async {});

        await repository.searchTasks(query: '', page: 0);

        verifyNever(() => local.replaceTasks(any()));
      },
    );

    test('searchTasks ignores cancel without touching local', () async {
      when(
        () => remote.fetchTasks(
          query: any(named: 'query'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.cancel,
        ),
      );

      await repository.searchTasks(query: 'x', page: 0);

      verifyNever(() => local.replaceTasks(any()));
      verifyNever(() => local.upsertTask(any()));
    });

    test('updateStatus writes optimistic task and enqueues sync', () async {
      final current = makeTask(id: 't1');

      when(() => local.getTasks()).thenAnswer((_) async => [current]);

      when(() => local.upsertTask(any())).thenAnswer((_) async {});

      when(() => local.enqueueOperation(any())).thenAnswer((_) async {});

      await repository.updateStatus(taskId: 't1', next: TaskStatus.inProgress);

      final upsertCapture = verify(
        () => local.upsertTask(captureAny()),
      ).captured;

      final optimistic = upsertCapture.single as PatientTasks;

      expect(optimistic.status, TaskStatus.inProgress);
      expect(optimistic.version, current.version + 1);

      final opCapture = verify(
        () => local.enqueueOperation(captureAny()),
      ).captured;

      final op = opCapture.single as SyncOperationLocalModel;

      expect(op.taskId, 't1');
      expect(op.type, 'patch_status');

      final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;

      expect(payload['task_id'], 't1');
      expect(payload['version'], optimistic.version);
      expect(payload['status'], TaskStatus.inProgress.name);
    });
  });
}
