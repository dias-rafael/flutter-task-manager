import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../domain/domain.dart';
import '../../models/models.dart';
import 'patient_tasks_local_data_source.dart';

class PatientTasksLocalDataSourceImpl implements PatientTasksLocalDataSource {
  PatientTasksLocalDataSourceImpl({
    required Box<PatientTasksLocalModel> tasksBox,
    required Box<SyncOperationLocalModel> queueBox,
  }) : _tasksBox = tasksBox,
       _queueBox = queueBox;

  final Box<PatientTasksLocalModel> _tasksBox;
  final Box<SyncOperationLocalModel> _queueBox;
  final _controller = StreamController<List<PatientTasks>>.broadcast();

  @override
  Stream<List<PatientTasks>> watchTasks() {
    return Stream.multi((controller) {
      controller.add(_tasksBox.values.map((e) => e.toEntity()).toList());
      final subscription = _tasksBox.watch().listen((_) {
        controller.add(_tasksBox.values.map((e) => e.toEntity()).toList());
      });
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<List<PatientTasks>> getTasks() async {
    return _tasksBox.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> saveTasks(List<PatientTasks> tasks) async {
    final map = {
      for (final task in tasks)
        task.id: PatientTasksLocalModel.fromEntity(task),
    };
    await _tasksBox.putAll(map);
    _emit();
  }

  @override
  Future<void> upsertTask(PatientTasks task) async {
    await _tasksBox.put(task.id, PatientTasksLocalModel.fromEntity(task));
    _emit();
  }

  @override
  Future<void> enqueueOperation(SyncOperationLocalModel operation) async {
    await _queueBox.put(operation.id, operation);
  }

  @override
  Future<List<SyncOperationLocalModel>> getPendingOperations() async {
    debugPrint('BOX KEYS: ${_queueBox.keys.toList()}');
    debugPrint('BOX VALUES RAW: ${_queueBox.values}');

    for (final key in _queueBox.keys) {
      try {
        final item = _queueBox.get(key);
        debugPrint('ITEM [$key]: $item');
      } catch (e) {
        debugPrint('ERROR READING [$key]: $e');
      }
    }

    return _queueBox.values.toList();
  }

  @override
  Future<void> removeOperation(String id) async {
    debugPrint('REMOVE OPERATION: $id');

    await _queueBox.delete(id);

    debugPrint(
      'QUEUE AFTER REMOVE: '
      '${_queueBox.keys.toList()}',
    );
  }

  void _emit() {
    final tasks = _tasksBox.values.map((e) => e.toEntity()).toList();
    _controller.add(tasks);
  }

  @override
  Future<bool> hasPendingOperation(String taskId) async {
    return _queueBox.values.any((e) => e.taskId == taskId);
  }

  @override
  Future<void> updateOperation(SyncOperationLocalModel operation) async {
    await _queueBox.put(operation.id, operation);
  }

  @override
  Future<void> replaceTasks(List<PatientTasks> tasks) async {
    await _tasksBox.clear();

    for (final task in tasks) {
      await _tasksBox.put(task.id, PatientTasksLocalModel.fromEntity(task));
    }
  }

  @override
  Stream<int> watchPendingSyncCount() {
    return Stream.multi((controller) {
      controller.add(_queueBox.length);

      final subscription = _queueBox.watch().listen((_) {
        controller.add(_queueBox.length);
      });

      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> upsertOperation(SyncOperationLocalModel operation) async {
    debugPrint('''
UPSERT OPERATION:
id=${operation.id}
retry=${operation.retryCount}
''');

    await _queueBox.put(operation.id, operation);

    debugPrint(
      'QUEUE AFTER UPSERT: '
      '${_queueBox.keys.toList()}',
    );
  }
}
