import '../domain.dart';

abstract class PatientTasksRepository {
  // ----------------------------------------------------------
  // LOCAL SOURCE OF TRUTH
  // ----------------------------------------------------------

  Stream<List<PatientTasks>> watchTasks();

  // ----------------------------------------------------------
  // INITIAL / MANUAL REFRESH
  // ----------------------------------------------------------

  Future<void> refresh();

  // ----------------------------------------------------------
  // SEARCH + PAGINATION
  // ----------------------------------------------------------

  Future<void> searchTasks({
    required String query,
    required int page,
    int pageSize = 20,
  });

  // ----------------------------------------------------------
  // OPTIMISTIC MUTATION
  // ----------------------------------------------------------

  Future<void> updateStatus({required String taskId, required TaskStatus next});

  Stream<int> watchPendingSyncCount();
}
