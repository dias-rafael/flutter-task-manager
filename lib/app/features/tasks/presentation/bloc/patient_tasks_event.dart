part of 'patient_tasks_bloc.dart';

sealed class PatientTasksEvent {}

class LoadTasks extends PatientTasksEvent {}

class UpdateTaskStatus extends PatientTasksEvent {
  UpdateTaskStatus({required this.taskId, required this.status});

  final String taskId;
  final TaskStatus status;
}
