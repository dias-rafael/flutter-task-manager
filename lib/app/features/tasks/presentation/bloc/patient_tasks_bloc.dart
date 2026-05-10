import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    on<RollbackMessageReceived>(_onRollbackMessageReceived);

    on<FilterChanged>(_onFilterChanged);
  }

  final PatientTasksRepository repository;
  StreamSubscription<List<PatientTasks>>? _tasksSubscription;
  String _currentQuery = '';
  List<PatientTasks> _allTasks = [];
  TaskFilter _currentFilter = TaskFilter.all;

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

    final filtered = _applyFilters(_allTasks);

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
        filter: _currentFilter,
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

    final filtered = _applyFilters(_allTasks);

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
      // ------------------------------------------------------
      // TRANSIENT MESSAGE
      // ------------------------------------------------------

      emit(PatientTasksUiMessage(alertMessage: e.toString()));

      // ------------------------------------------------------
      // RESTORE SCREEN STATE
      // ------------------------------------------------------

      final filtered = _applyFilters(_allTasks);

      emit(
        PatientTasksLoaded(
          tasks: filtered,
          query: _currentQuery,
          page: 0,
          isLoadingMore: false,
          filter: _currentFilter,
        ),
      );
    }
  }

  // =========================================================
  // LOCAL FILTER
  // =========================================================

  // List<PatientTasks> _filterTasks(List<PatientTasks> tasks, String query) {
  //   if (query.isEmpty) {
  //     return tasks;
  //   }

  //   final lower = query.toLowerCase();

  //   return tasks.where((task) {
  //     return task.title.toLowerCase().contains(lower) ||
  //         task.patientReference.toLowerCase().contains(lower) ||
  //         task.status.name.toLowerCase().contains(lower);
  //   }).toList();
  // }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  Future<void> close() async {
    await _tasksSubscription?.cancel();

    return super.close();
  }

  Future<void> _onRollbackMessageReceived(
    RollbackMessageReceived event,
    Emitter<PatientTasksState> emit,
  ) async {
    // ------------------------------------------------------
    // EMIT TRANSIENT MESSAGE
    // ------------------------------------------------------

    emit(PatientTasksUiMessage(alertMessage: event.message));

    // ------------------------------------------------------
    // RESTORE CURRENT SCREEN STATE
    // ------------------------------------------------------

    await Future.microtask(() {});

    if (emit.isDone) {
      return;
    }

    final filtered = _applyFilters(_allTasks);

    emit(
      PatientTasksLoaded(
        tasks: filtered,
        query: _currentQuery,
        page: 0,
        isLoadingMore: false,
        filter: _currentFilter,
      ),
    );
  }

  void notifyRollbackMessage(String message) {
    add(RollbackMessageReceived(message));
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<PatientTasksState> emit,
  ) async {
    _currentFilter = event.filter;

    final filtered = _applyFilters(_allTasks);

    emit(
      PatientTasksLoaded(
        tasks: filtered,
        query: _currentQuery,
        filter: _currentFilter,
        page: 0,
        isLoadingMore: false,
      ),
    );
  }

  List<PatientTasks> _applyFilters(List<PatientTasks> tasks) {
    // ------------------------------------------------------
    // SEARCH FILTER
    // ------------------------------------------------------

    final searchFiltered = tasks.where((task) {
      final query = _currentQuery.toLowerCase();

      return task.title.toLowerCase().contains(query);
    }).toList();

    // ------------------------------------------------------
    // STATUS FILTER
    // ------------------------------------------------------

    switch (_currentFilter) {
      case TaskFilter.all:
        return searchFiltered;

      case TaskFilter.pending:
        return searchFiltered
            .where(
              (task) =>
                  task.status != TaskStatus.completed &&
                  task.status != TaskStatus.cancelled,
            )
            .toList();

      case TaskFilter.completed:
        return searchFiltered
            .where((task) => task.status == TaskStatus.completed)
            .toList();

      case TaskFilter.cancelled:
        return searchFiltered
            .where((task) => task.status == TaskStatus.cancelled)
            .toList();
    }
  }
}
