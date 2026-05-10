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
  });

  final List<PatientTasks> tasks;
  final String query;
  final int page;
  final bool isLoadingMore;

  PatientTasksLoaded copyWith({
    List<PatientTasks>? tasks,
    String? query,
    int? page,
    bool? isLoadingMore,
  }) {
    return PatientTasksLoaded(
      tasks: tasks != null
          ? List<PatientTasks>.from(tasks)
          : List<PatientTasks>.from(this.tasks),
      query: query ?? this.query,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PatientTasksError extends PatientTasksState {
  PatientTasksError(this.message);

  final String message;
}

class PatientTasksUiMessage extends PatientTasksState {
  PatientTasksUiMessage({required this.alertMessage});

  final String alertMessage;
}
