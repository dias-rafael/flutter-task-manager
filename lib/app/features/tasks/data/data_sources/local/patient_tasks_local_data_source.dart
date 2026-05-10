import '../../../domain/domain.dart';
import '../../models/models.dart';

abstract class PatientTasksLocalDataSource {
  Stream<List<PatientTasks>> watchTasks();

  Future<List<PatientTasks>> getTasks();

  Future<void> saveTasks(List<PatientTasks> tasks);

  Future<void> upsertTask(PatientTasks task);

  Future<void> enqueueOperation(SyncOperationLocalModel operation);

  Future<List<SyncOperationLocalModel>> getPendingOperations();

  Future<void> removeOperation(String operationId);

  Future<bool> hasPendingOperation(String taskId);

  Future<void> updateOperation(SyncOperationLocalModel operation);

  Future<void> replaceTasks(List<PatientTasks> tasks);

  Stream<int> watchPendingSyncCount();

  Future<void> upsertOperation(SyncOperationLocalModel operation);
}
