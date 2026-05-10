import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/network/network_types.dart';
import '../../domain/domain.dart';
import '../data.dart';

class PatientTasksRepositoryImpl implements PatientTasksRepository {
  PatientTasksRepositoryImpl({required this.local, required this.remote});

  final PatientTasksLocalDataSource local;

  final PatientTasksRemoteDataSource remote;

  // ----------------------------------------------------------
  // LOCAL SOURCE OF TRUTH
  // ----------------------------------------------------------

  @override
  Stream<List<PatientTasks>> watchTasks() {
    return local.watchTasks();
  }

  // ----------------------------------------------------------
  // REFRESH
  // ----------------------------------------------------------

  @override
  Future<void> refresh() async {
    try {
      final remoteTasks = await remote.fetchTasks();

      await local.saveTasks(remoteTasks);
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Network error');
    } catch (e) {
      throw UnknownException(message: 'Failed to refresh tasks', error: e);
    }
  }

  // ----------------------------------------------------------
  // SEARCH + PAGINATION
  // ----------------------------------------------------------

  @override
  Future<void> searchTasks({
    required String query,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final tasks = await remote.fetchTasks(
        query: query,
        page: page,
        pageSize: pageSize,
      );

      if (page == 0) {
        await local.replaceTasks(tasks);
      } else {
        for (final task in tasks) {
          await local.upsertTask(task);
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return;
      }

      // offline-first:
      // keep local cache

      return;
    } catch (_) {
      return;
    }
  }

  // ----------------------------------------------------------
  // OPTIMISTIC UPDATE
  // ----------------------------------------------------------

  @override
  Future<void> updateStatus({
    required String taskId,
    required TaskStatus next,
  }) async {
    final tasks = await local.getTasks();

    final current = tasks.firstWhere((e) => e.id == taskId);

    final optimistic = current.transitionTo(next);

    // optimistic update

    await local.upsertTask(optimistic);

    // enqueue sync operation

    final operation = SyncOperationLocalModel(
      id: const Uuid().v4(),
      taskId: current.id,
      type: 'patch_status',
      retryCount: 0,
      createdAt: DateTime.now(),
      nextRetryAt: DateTime.now(),
      payloadJson: jsonEncode({
        'task_id': current.id,
        'version': optimistic.version,
        'status': optimistic.status.name,
      }),
    );

    await local.enqueueOperation(operation);
  }

  @override
  Stream<int> watchPendingSyncCount() {
    return local.watchPendingSyncCount();
  }
}
