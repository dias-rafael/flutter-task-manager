part of 'patient_tasks_bloc.dart';

sealed class PatientTasksEvent {}

class LoadTasks extends PatientTasksEvent {}

class UpdateTaskStatus extends PatientTasksEvent {
  UpdateTaskStatus({required this.taskId, required this.status});

  final String taskId;

  final TaskStatus status;
}

class SearchTasks extends PatientTasksEvent {
  SearchTasks(this.query);

  final String query;
}

class LoadNextPage extends PatientTasksEvent {}

// ============================================================
// INTERNAL STREAM EVENT
// ============================================================

class TasksUpdated extends PatientTasksEvent {
  TasksUpdated(this.tasks);

  final List<PatientTasks> tasks;
}
