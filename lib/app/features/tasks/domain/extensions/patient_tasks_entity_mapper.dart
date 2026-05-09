import '../../data/models/patient_tasks_local_model.dart';
import '../domain.dart';

extension PatientTaskEntityMapper on PatientTasks {
  PatientTasksLocalModel toLocal() {
    return PatientTasksLocalModel(
      id: id,
      version: version,
      title: title,
      status: status.name,
      priority: priority.name,
      patientReference: patientReference,
      lastModified: lastModified,
      dueDate: dueDate,
      assignee: assignee,
    );
  }
}
