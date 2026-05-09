import '../domain.dart';

abstract class PatientTasksRepository {
  Stream<List<PatientTasks>> watchTasks();

  Future<void> refresh();

  Future<void> updateStatus({required String taskId, required TaskStatus next});
}
