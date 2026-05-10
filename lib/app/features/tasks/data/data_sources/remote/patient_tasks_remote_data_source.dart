import '../../../domain/domain.dart';

abstract class PatientTasksRemoteDataSource {
  // ----------------------------------------------------------
  // FETCH TASKS
  // ----------------------------------------------------------

  Future<List<PatientTasks>> fetchTasks({
    String query = '',
    int page = 0,
    int pageSize = 20,
  });

  // ----------------------------------------------------------
  // PATCH STATUS
  // ----------------------------------------------------------

  Future<void> patchStatus({
    required String taskId,
    required int version,
    required String status,
  });

  // ----------------------------------------------------------
  // REALTIME UPDATES
  // ----------------------------------------------------------

  Stream<PatientTasks> watchTaskUpdates();

  // ----------------------------------------------------------
  // FETCH SINGLE TASK
  // ----------------------------------------------------------

  Future<PatientTasks> fetchTask(String taskId);
}
