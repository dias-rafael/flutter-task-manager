import '../../../domain/domain.dart';

abstract class PatientTasksRemoteDataSource {
  Future<List<PatientTasks>> fetchTasks({
    String query = '',
    int page = 0,
    int pageSize = 20,
  });
  Future<void> patchStatus({
    required String taskId,
    required int version,
    required String status,
  });
  Stream<PatientTasks> watchTaskUpdates();
  Future<PatientTasks> fetchTask(String taskId);
}
