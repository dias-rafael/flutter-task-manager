import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:task_manager_app/app/features/tasks/data/data.dart';
import 'package:task_manager_app/app/features/tasks/domain/domain.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late Box<PatientTasksLocalModel> tasksBox;
  late Box<SyncOperationLocalModel> queueBox;
  late PatientTasksLocalDataSource datasource;

  setUpAll(() async {
    Hive
      ..init('./test_hive')
      ..registerAdapter(PatientTasksLocalModelAdapter())
      ..registerAdapter(SyncOperationLocalModelAdapter());
  });

  setUp(() async {
    tasksBox = await Hive.openBox<PatientTasksLocalModel>('tasks_test');
    queueBox = await Hive.openBox<SyncOperationLocalModel>('queue_test');
    await tasksBox.clear();
    await queueBox.clear();

    datasource = PatientTasksLocalDataSourceImpl(
      tasksBox: tasksBox,
      queueBox: queueBox,
    );
  });

  tearDown(() async {
    await tasksBox.close();
    await queueBox.close();
  });

  group('PatientTasksLocalDataSource', () {
    test('saveTasks persists tasks', () async {
      final task = makeTask(title: 'Task 1');

      await datasource.saveTasks([task]);

      final result = await datasource.getTasks();

      expect(result.length, 1);
      expect(result.first.title, 'Task 1');
    });

    test('upsertTask replaces existing task', () async {
      final oldTask = makeTask(title: 'Old', status: TaskStatus.onHold);

      final updatedTask = makeTask(
        title: 'Updated',
        status: TaskStatus.completed,
      );

      await datasource.saveTasks([oldTask]);
      await datasource.upsertTask(updatedTask);

      final result = await datasource.getTasks();

      expect(result.first.title, 'Updated');
      expect(result.first.status, TaskStatus.completed);
    });

    test('enqueueOperation persists operation', () async {
      final operation = SyncOperationLocalModel(
        id: 'op-1',
        taskId: '1',
        type: 'update_status',
        payloadJson: '{"status":"completed"}',
        retryCount: 0,
        createdAt: DateTime.now(),
        nextRetryAt: DateTime.now(),
      );

      await datasource.enqueueOperation(operation);

      final result = await datasource.getPendingOperations();

      expect(result.length, 1);
      expect(result.first.id, 'op-1');
    });

    test('hasPendingOperation returns true', () async {
      final operation = SyncOperationLocalModel(
        id: 'op-1',
        taskId: '1',
        type: 'update_status',
        payloadJson: '{"status":"completed"}',
        retryCount: 0,
        createdAt: DateTime.now(),
        nextRetryAt: DateTime.now(),
      );

      await datasource.enqueueOperation(operation);

      final result = await datasource.hasPendingOperation('1');

      expect(result, true);
    });

    test('watchTasks emits updates', () async {
      final emitted = <List<PatientTasks>>[];
      final subscription = datasource.watchTasks().listen(emitted.add);
      final task = makeTask(title: 'Task 1');

      await datasource.saveTasks([task]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emitted.last.length, 1);
      expect(emitted.last.first.title, 'Task 1');

      await subscription.cancel();
    });
  });
}
