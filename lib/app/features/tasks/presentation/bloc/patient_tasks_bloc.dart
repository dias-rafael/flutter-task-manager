import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/domain.dart';

part 'patient_tasks_event.dart';
part 'patient_tasks_state.dart';

class PatientTasksBloc extends Bloc<PatientTasksEvent, PatientTasksState> {
  PatientTasksBloc({required this.repository}) : super(PatientTasksInitial()) {
    on<FetchPatientTasks>(_onFetchTasks);
  }

  final PatientTasksRepository repository;

  Future<void> _onFetchTasks(
    FetchPatientTasks event,
    Emitter<PatientTasksState> emit,
  ) async {
    emit(PatientTasksLoading());

    try {
      final tasks = await repository.fetchTasks();

      emit(PatientTasksLoaded(tasks));
    } catch (e) {
      emit(PatientTasksError(e.toString()));
    }
  }
}
