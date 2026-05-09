import '../entities/patient_task_entity.dart';

abstract class PatientTasksRepository {
  Future<List<PatientTasks>> fetchTasks();
}
