import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../core/network/network_types.dart';
import '../../domain/domain.dart';
import '../data_sources/data_sources.dart';
import '../models/sync_operation_local_model.dart';
import 'retry_police.dart';

class SyncManager {
  SyncManager({
    required this.local,
    required this.remote,
    required this.repository,
    required this.retryPolicy,
  });

  final PatientTasksLocalDataSource local;

  final PatientTasksRemoteDataSource remote;

  final PatientTasksRepository repository;

  final RetryPolicy retryPolicy;

  bool _running = false;

  // ----------------------------------------------------------
  // START
  // ----------------------------------------------------------

  Future<void> start() async {
    if (_running) return;

    _running = true;

    // INITIAL PULL

    await _safeRefresh();

    // START REALTIME

    _subscribeRealtime();

    // START LOOP

    unawaited(_loop());
  }

  // ----------------------------------------------------------
  // LOOP
  // ----------------------------------------------------------

  Future<void> _loop() async {
    while (_running) {
      await processQueue();

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // ----------------------------------------------------------
  // SAFE REFRESH
  // ----------------------------------------------------------

  Future<void> _safeRefresh() async {
    try {
      await repository.refresh();
    } catch (e) {
      debugPrint('Refresh failed: $e');
    }
  }

  // ----------------------------------------------------------
  // PROCESS QUEUE
  // ----------------------------------------------------------

  Future<void> processQueue() async {
    final operations = await local.getPendingOperations();

    // IMPORTANT:
    // ordered processing

    operations.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final operation in operations) {
      // not ready yet

      if (DateTime.now().isBefore(operation.nextRetryAt)) {
        continue;
      }

      try {
        await remote.patchStatus(
          taskId: operation.payload['task_id'] as String,
          version: operation.payload['version'] as int,
          status: operation.payload['status'] as String,
        );

        // SUCCESS

        await local.removeOperation(operation.id);
      } on ConflictException {
        await _resolveConflict(operation);
      } catch (e) {
        await _scheduleRetry(operation);
      }
    }
  }

  // ----------------------------------------------------------
  // RETRY
  // ----------------------------------------------------------

  Future<void> _scheduleRetry(SyncOperationLocalModel operation) async {
    operation.retryCount++;

    final delay = retryPolicy.nextDelay(operation.retryCount);

    operation.nextRetryAt = DateTime.now().add(delay);

    await local.updateOperation(operation);
  }

  // ----------------------------------------------------------
  // CONFLICT RESOLUTION
  // ----------------------------------------------------------

  Future<void> _resolveConflict(SyncOperationLocalModel operation) async {
    // SERVER-WINS STRATEGY

    final serverTask = await remote.fetchTask(operation.taskId);

    // ROLLBACK LOCAL OPTIMISTIC STATE

    await local.upsertTask(serverTask);

    // REMOVE FAILED OPERATION

    await local.removeOperation(operation.id);
  }

  // ----------------------------------------------------------
  // REALTIME UPDATES
  // ----------------------------------------------------------

  void _subscribeRealtime() {
    remote.watchTaskUpdates().listen((serverTask) async {
      // IMPORTANT:
      // DO NOT overwrite optimistic state

      final hasPending = await local.hasPendingOperation(serverTask.id);

      if (hasPending) {
        debugPrint('''
Skipping realtime update
because optimistic mutation exists
''');

        return;
      }

      // SAFE TO APPLY

      await local.upsertTask(serverTask);
    });
  }
}
