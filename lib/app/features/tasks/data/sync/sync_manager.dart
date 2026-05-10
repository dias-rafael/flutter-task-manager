import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../../core/network/network_types.dart';
import '../../domain/domain.dart';
import '../data_sources/data_sources.dart';
import '../models/sync_operation_local_model.dart';
import 'retry_policy.dart';

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
  StreamSubscription<PatientTasks>? _realtimeSubscription;
  bool _running = false;
  bool _isProcessing = false;

  // ----------------------------------------------------------
  // START
  // ----------------------------------------------------------

  Future<void> start() async {
    if (_running) return;

    _running = true;

    // initial pull sync

    await _safeRefresh();

    // subscribe realtime updates

    _subscribeRealtime();

    // start queue loop

    unawaited(_loop());
  }

  // ----------------------------------------------------------
  // STOP
  // ----------------------------------------------------------

  Future<void> stop() async {
    _running = false;

    await _realtimeSubscription?.cancel();
  }

  // ----------------------------------------------------------
  // LOOP
  // ----------------------------------------------------------

  Future<void> _loop() async {
    while (_running) {
      try {
        await processQueue();
      } catch (e) {
        debugPrint('Queue processing error: $e');
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // ----------------------------------------------------------
  // REFRESH
  // ----------------------------------------------------------

  Future<void> _safeRefresh() async {
    try {
      // ------------------------------------------------------
      // IMPORTANT:
      // do NOT refresh while pending sync exists
      // ------------------------------------------------------

      final pending = await local.getPendingOperations();

      if (pending.isNotEmpty) {
        debugPrint('''
Skipping refresh because
pending operations exist
''');

        return;
      }

      await repository.refresh();
    } catch (e) {
      debugPrint('Refresh failed: $e');
    }
  }

  // ----------------------------------------------------------
  // PROCESS QUEUE
  // ----------------------------------------------------------

  Future<void> processQueue() async {
    // --------------------------------------------------------
    // PREVENT CONCURRENT PROCESSING
    // --------------------------------------------------------

    if (_isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      final operations = await local.getPendingOperations();

      debugPrint('''
PROCESS QUEUE:
${operations.map((e) => e.id).toList()}
''');

      // preserve ordering

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

          // success

          await local.removeOperation(operation.id);
        } on ConflictException {
          await _resolveConflict(operation);
        } catch (e) {
          debugPrint('Sync operation failed: $e');

          await _scheduleRetry(operation);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  // ----------------------------------------------------------
  // RETRY
  // ----------------------------------------------------------

  Future<void> _scheduleRetry(SyncOperationLocalModel operation) async {
    final retries = operation.retryCount + 1;

    // exponential backoff

    final delaySeconds = 1 << retries;

    // jitter

    final jitter = Random().nextInt(3);

    final nextRetryAt = DateTime.now().add(
      Duration(seconds: delaySeconds + jitter),
    );

    final updated = operation.copyWith(
      retryCount: retries,
      nextRetryAt: nextRetryAt,
    );

    // IMPORTANT:
    // overwrite SAME operation

    await local.upsertOperation(updated);

    debugPrint('''
Retry scheduled:
${updated.id}
retryCount=${updated.retryCount}
''');
  }

  // ----------------------------------------------------------
  // CONFLICT RESOLUTION
  // ----------------------------------------------------------

  Future<void> _resolveConflict(SyncOperationLocalModel operation) async {
    debugPrint(
      'Conflict detected for '
      '${operation.taskId}',
    );

    // ------------------------------------------------------
    // SERVER-WINS STRATEGY
    // ------------------------------------------------------

    final serverTask = await remote.fetchTask(operation.taskId);

    // rollback optimistic state

    await local.upsertTask(serverTask);

    // remove failed mutation

    await local.removeOperation(operation.id);
  }

  // ----------------------------------------------------------
  // REALTIME
  // ----------------------------------------------------------

  void _subscribeRealtime() {
    _realtimeSubscription?.cancel();

    _realtimeSubscription = remote.watchTaskUpdates().listen(
      (serverTask) async {
        try {
          // IMPORTANT:
          // DO NOT overwrite optimistic
          // local state

          final hasPending = await local.hasPendingOperation(serverTask.id);

          if (hasPending) {
            debugPrint('''
Skipping realtime update
because optimistic mutation exists
''');

            return;
          }

          // safe reconciliation

          await local.upsertTask(serverTask);
        } catch (e) {
          debugPrint('Realtime merge error: $e');
        }
      },

      onError: (e) {
        debugPrint('Realtime stream error: $e');
      },
    );
  }
}
