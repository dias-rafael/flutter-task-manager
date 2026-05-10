import 'dart:async';

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
  Stream<List<PatientTasks>> watchTasks() async* {
    // --------------------------------------------------------
    // INITIAL EMISSION
    // --------------------------------------------------------

    yield _tasksBox.values.map((e) => e.toEntity()).toList();

    // --------------------------------------------------------
    // REACTIVE UPDATES
    // --------------------------------------------------------

    await for (final _ in _tasksBox.watch()) {
      yield _tasksBox.values.map((e) => e.toEntity()).toList();
    }
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
    return _queueBox.values.toList();
  }

  @override
  Future<void> removeOperation(String operationId) async {
    await _queueBox.delete(operationId);
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
}
