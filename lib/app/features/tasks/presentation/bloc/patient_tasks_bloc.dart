import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/domain.dart';

part 'patient_tasks_event.dart';
part 'patient_tasks_state.dart';

class PatientTasksBloc extends Bloc<PatientTasksEvent, PatientTasksState> {
  PatientTasksBloc({required this.repository}) : super(PatientTasksInitial()) {
    on<LoadTasks>(_onLoad);

    on<UpdateTaskStatus>(_onUpdateStatus);
  }

  final PatientTasksRepository repository;

  Future<void> _onLoad(LoadTasks event, Emitter<PatientTasksState> emit) async {
    emit(PatientTasksLoading());

    try {
      // initial sync

      // stream local db updates

      await emit.forEach<List<PatientTasks>>(
        repository.watchTasks(),

        onData: (tasks) {
          return PatientTasksLoaded(tasks);
        },

        onError: (error, stackTrace) {
          return PatientTasksError(error.toString());
        },
      );
    } catch (e) {
      emit(PatientTasksError(e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateTaskStatus event,
    Emitter<PatientTasksState> emit,
  ) async {
    try {
      await repository.updateStatus(taskId: event.taskId, next: event.status);
    } catch (e) {
      emit(PatientTasksError(e.toString()));
    }
  }
}
