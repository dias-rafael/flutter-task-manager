import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/network/network_types.dart';
import '../../domain/domain.dart';
import '../data.dart';

class PatientTasksRepositoryImpl implements PatientTasksRepository {
  PatientTasksRepositoryImpl({required this.local, required this.remote});

  final PatientTasksLocalDataSource local;

  final PatientTasksRemoteDataSource remote;

  @override
  Stream<List<PatientTasks>> watchTasks() {
    return local.watchTasks();
  }

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

  @override
  Future<void> updateStatus({
    required String taskId,
    required TaskStatus next,
  }) async {
    final tasks = await local.getTasks();

    final current = tasks.firstWhere((e) => e.id == taskId);

    final updated = current.transitionTo(next);

    // optimistic update

    await local.upsertTask(updated);

    // queue operation

    await local.enqueueOperation(
      SyncOperationLocalModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),

        taskId: updated.id,

        payload: {
          'task_id': updated.id,
          'version': updated.version,
          'status': updated.status.name,
        },
      ),
    );

    // try sync

    try {
      await remote.patchStatus(
        taskId: updated.id,
        version: updated.version,
        status: updated.status.name,
      );
    } catch (e) {
      debugPrint('Failed to sync operation: $e');
    }
  }
}
