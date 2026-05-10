import 'dart:async';

import 'package:hive/hive.dart';

import '../../../domain/domain.dart';
import '../../models/models.dart';
import 'patient_tasks_local_data_source.dart';

class PatientTasksLocalDataSourceImpl implements PatientTasksLocalDataSource {
  PatientTasksLocalDataSourceImpl({
    required this.tasksBox,
    required this.queueBox,
  });

  final Box<PatientTasksLocalModel> tasksBox;

  final Box<SyncOperationLocalModel> queueBox;

  final _controller = StreamController<List<PatientTasks>>.broadcast();

  @override
  Stream<List<PatientTasks>> watchTasks() async* {
    yield await getTasks();

    yield* _controller.stream;
  }

  @override
  Future<List<PatientTasks>> getTasks() async {
    return tasksBox.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> saveTasks(List<PatientTasks> tasks) async {
    final map = {
      for (final task in tasks)
        task.id: PatientTasksLocalModel.fromEntity(task),
    };

    await tasksBox.putAll(map);

    _emit();
  }

  @override
  Future<void> upsertTask(PatientTasks task) async {
    await tasksBox.put(task.id, PatientTasksLocalModel.fromEntity(task));

    _emit();
  }

  @override
  Future<void> enqueueOperation(SyncOperationLocalModel operation) async {
    await queueBox.put(operation.id, operation);
  }

  @override
  Future<List<SyncOperationLocalModel>> getPendingOperations() async {
    return queueBox.values.toList();
  }

  @override
  Future<void> removeOperation(String operationId) async {
    await queueBox.delete(operationId);
  }

  void _emit() {
    final tasks = tasksBox.values.map((e) => e.toEntity()).toList();

    _controller.add(tasks);
  }

  @override
  Future<bool> hasPendingOperation(String taskId) async {
    return queueBox.values.any((e) => e.taskId == taskId);
  }

  @override
  Future<void> updateOperation(SyncOperationLocalModel operation) async {
    await queueBox.put(operation.id, operation);
  }
}
