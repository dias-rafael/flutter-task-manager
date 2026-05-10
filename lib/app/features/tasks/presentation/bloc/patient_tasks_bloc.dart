import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../domain/domain.dart';

part 'patient_tasks_event.dart';
part 'patient_tasks_state.dart';

EventTransformer<T> debounceRestartable<T>(Duration duration) {
  return (events, mapper) {
    return restartable<T>().call(events.debounce(duration), mapper);
  };
}

class PatientTasksBloc extends Bloc<PatientTasksEvent, PatientTasksState> {
  PatientTasksBloc({required this.repository}) : super(PatientTasksInitial()) {
    // --------------------------------------------------------
    // LOAD
    // --------------------------------------------------------

    on<LoadTasks>(_onLoad, transformer: droppable());

    // --------------------------------------------------------
    // LOCAL TASK STREAM
    // --------------------------------------------------------

    on<TasksUpdated>(_onTasksUpdated);

    // --------------------------------------------------------
    // SEARCH
    // --------------------------------------------------------

    on<SearchTasks>(
      _onSearch,

      transformer: debounceRestartable(const Duration(milliseconds: 300)),
    );

    // --------------------------------------------------------
    // PAGINATION
    // --------------------------------------------------------

    on<LoadNextPage>(_onLoadNextPage, transformer: droppable());

    // --------------------------------------------------------
    // UPDATE STATUS
    // --------------------------------------------------------

    on<UpdateTaskStatus>(_onUpdateStatus, transformer: sequential());
  }

  final PatientTasksRepository repository;

  StreamSubscription<List<PatientTasks>>? _tasksSubscription;

  String _currentQuery = '';

  List<PatientTasks> _allTasks = [];

  // =========================================================
  // LOAD
  // =========================================================

  Future<void> _onLoad(LoadTasks event, Emitter<PatientTasksState> emit) async {
    await _tasksSubscription?.cancel();

    // --------------------------------------------------------
    // LOCAL SOURCE OF TRUTH
    // --------------------------------------------------------

    _tasksSubscription = repository.watchTasks().listen((tasks) {
      add(TasksUpdated(tasks));
    });

    // --------------------------------------------------------
    // BACKGROUND REMOTE SYNC
    // --------------------------------------------------------

    unawaited(repository.searchTasks(query: _currentQuery, page: 0));
  }

  // =========================================================
  // LOCAL TASK UPDATE
  // =========================================================

  void _onTasksUpdated(TasksUpdated event, Emitter<PatientTasksState> emit) {
    _allTasks = List<PatientTasks>.from(event.tasks);

    final filtered = _filterTasks(_allTasks, _currentQuery);

    final current = state;

    if (current is PatientTasksLoaded) {
      emit(current.copyWith(tasks: filtered));

      return;
    }

    emit(
      PatientTasksLoaded(
        tasks: filtered,
        query: _currentQuery,
        page: 0,
        isLoadingMore: false,
      ),
    );
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<void> _onSearch(
    SearchTasks event,
    Emitter<PatientTasksState> emit,
  ) async {
    _currentQuery = event.query;

    final current = state;

    if (current is! PatientTasksLoaded) {
      return;
    }

    final filtered = _filterTasks(_allTasks, _currentQuery);

    emit(current.copyWith(tasks: filtered));
  }

  // =========================================================
  // PAGINATION
  // =========================================================

  Future<void> _onLoadNextPage(
    LoadNextPage event,
    Emitter<PatientTasksState> emit,
  ) async {
    final current = state;

    if (current is! PatientTasksLoaded) {
      return;
    }

    try {
      emit(current.copyWith(isLoadingMore: true));

      final nextPage = current.page + 1;

      await repository.searchTasks(query: _currentQuery, page: nextPage);

      emit(current.copyWith(page: nextPage, isLoadingMore: false));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  // =========================================================
  // UPDATE STATUS
  // =========================================================

  Future<void> _onUpdateStatus(
    UpdateTaskStatus event,
    Emitter<PatientTasksState> emit,
  ) async {
    try {
      await repository.updateStatus(taskId: event.taskId, next: event.status);
    } catch (e) {
      final current = state;

      // ------------------------------------------------------
      // TRANSIENT ERROR
      // ------------------------------------------------------

      if (current is PatientTasksLoaded) {
        emit(current.copyWith(alertMessage: e.toString()));

        // IMPORTANT:
        // clear snackbar state
        // so future messages can trigger again

        emit(current.copyWith(clearSnackbar: true));

        return;
      }

      // ------------------------------------------------------
      // FATAL ERROR
      // ------------------------------------------------------

      emit(PatientTasksError(e.toString()));
    }
  }

  // =========================================================
  // LOCAL FILTER
  // =========================================================

  List<PatientTasks> _filterTasks(List<PatientTasks> tasks, String query) {
    if (query.isEmpty) {
      return tasks;
    }

    final lower = query.toLowerCase();

    return tasks.where((task) {
      return task.title.toLowerCase().contains(lower) ||
          task.patientReference.toLowerCase().contains(lower) ||
          task.status.name.toLowerCase().contains(lower);
    }).toList();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  Future<void> close() async {
    await _tasksSubscription?.cancel();

    return super.close();
  }
}
