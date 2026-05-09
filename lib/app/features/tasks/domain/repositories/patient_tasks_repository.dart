import '../domain.dart';

abstract class PatientTasksRepository {
  Future<List<PatientTasks>> fetchTasks();

  Future<void> patchStatus({
    required String taskId,
    required TaskStatus status,
  });
}
