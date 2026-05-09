part of 'patient_tasks_bloc.dart';

sealed class PatientTasksEvent {}

class FetchPatientTasks extends PatientTasksEvent {}

class UpdatePatientTaskStatus extends PatientTasksEvent {
  UpdatePatientTaskStatus({required this.taskId, required this.status});

  final String taskId;
  final TaskStatus status;
}
