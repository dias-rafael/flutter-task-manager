import '../../models/patient_tasks_model.dart';

abstract class PatientTasksRemoteDataSource {
  Future<List<PatientTasksModel>> fetchTasks();
}
