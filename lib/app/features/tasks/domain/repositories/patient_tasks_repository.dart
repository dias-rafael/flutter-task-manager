import '../domain.dart';

abstract class PatientTasksRepository {
  Stream<List<PatientTasks>> watchTasks();
  Future<void> refresh();
  Future<void> searchTasks({
    required String query,
    required int page,
    int pageSize = 20,
  });
  Future<void> updateStatus({required String taskId, required TaskStatus next});
  Stream<int> watchPendingSyncCount();
}
