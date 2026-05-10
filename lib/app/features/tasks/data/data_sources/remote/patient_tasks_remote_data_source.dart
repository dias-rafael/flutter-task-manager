import '../../../domain/domain.dart';

abstract class PatientTasksRemoteDataSource {
  Future<List<PatientTasks>> fetchTasks();

  Future<void> patchStatus({
    required String taskId,
    required int version,
    required String status,
  });

  Stream<PatientTasks> watchTaskUpdates();

  Future<PatientTasks> fetchTask(String taskId);
}
