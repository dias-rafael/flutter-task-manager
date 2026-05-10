part of 'patient_tasks_bloc.dart';

sealed class PatientTasksState {}

class PatientTasksInitial extends PatientTasksState {}

class PatientTasksLoading extends PatientTasksState {}

class PatientTasksLoaded extends PatientTasksState {
  PatientTasksLoaded({
    required this.tasks,
    required this.query,
    required this.page,
    required this.isLoadingMore,
    this.alertMessage,
  });

  final List<PatientTasks> tasks;
  final String query;
  final int page;
  final bool isLoadingMore;
  final String? alertMessage;

  PatientTasksLoaded copyWith({
    List<PatientTasks>? tasks,
    String? query,
    int? page,
    bool? isLoadingMore,
    String? alertMessage,
    bool clearSnackbar = false,
  }) {
    return PatientTasksLoaded(
      tasks: tasks != null
          ? List<PatientTasks>.from(tasks)
          : List<PatientTasks>.from(this.tasks),
      query: query ?? this.query,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      alertMessage: clearSnackbar ? null : alertMessage ?? this.alertMessage,
    );
  }
}

class PatientTasksError extends PatientTasksState {
  PatientTasksError(this.message);

  final String message;
}
