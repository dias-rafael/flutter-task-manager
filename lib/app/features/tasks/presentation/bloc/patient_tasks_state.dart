part of 'patient_tasks_bloc.dart';

sealed class PatientTasksState {}

class PatientTasksInitial extends PatientTasksState {}

class PatientTasksLoading extends PatientTasksState {}

class PatientTasksLoaded extends PatientTasksState {
  PatientTasksLoaded(this.tasks);

  final List<PatientTasks> tasks;
}

class PatientTasksError extends PatientTasksState {
  PatientTasksError(this.message);

  final String message;
}
