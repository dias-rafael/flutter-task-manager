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
    required this.filter,
  });

  final List<PatientTasks> tasks;
  final String query;
  final int page;
  final bool isLoadingMore;
  final TaskFilter filter;

  PatientTasksLoaded copyWith({
    List<PatientTasks>? tasks,
    String? query,
    int? page,
    bool? isLoadingMore,
    TaskFilter? filter,
  }) {
    return PatientTasksLoaded(
      tasks: tasks != null
          ? List<PatientTasks>.from(tasks)
          : List<PatientTasks>.from(this.tasks),
      query: query ?? this.query,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filter: filter ?? this.filter,
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
