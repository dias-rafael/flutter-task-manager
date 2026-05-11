import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../domain/domain.dart';
import '../utils/task_update_error_message.dart';

part 'patient_tasks_event.dart';
part 'patient_tasks_state.dart';

EventTransformer<T> debounceRestartable<T>(Duration duration) {
  return (events, mapper) {
    return restartable<T>().call(events.debounce(duration), mapper);
  };
}

class PatientTasksBloc extends Bloc<PatientTasksEvent, PatientTasksState> {
  PatientTasksBloc({required PatientTasksRepository repository})
    : _repository = repository,
      super(PatientTasksInitial()) {
    on<LoadTasks>(_onLoad, transformer: droppable());
    on<TasksUpdated>(_onTasksUpdated);
    on<SearchTasks>(
      _onSearch,
      transformer: debounceRestartable(const Duration(milliseconds: 300)),
    );
    on<LoadNextPage>(_onLoadNextPage, transformer: droppable());
    on<UpdateTaskStatus>(_onUpdateStatus, transformer: sequential());
    on<RollbackMessageReceived>(_onRollbackMessageReceived);
    on<FilterChanged>(_onFilterChanged);
  }

  final PatientTasksRepository _repository;

  StreamSubscription<List<PatientTasks>>? _tasksSubscription;
  String _currentQuery = '';
  List<PatientTasks> _allTasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  Stream<int> watchPendingSyncCount() => _repository.watchPendingSyncCount();

  Future<void> _onLoad(LoadTasks event, Emitter<PatientTasksState> emit) async {
    if (state is! PatientTasksLoaded) {
      emit(PatientTasksLoading());
    }

    await _tasksSubscription?.cancel();

    _tasksSubscription = _repository.watchTasks().listen((tasks) {
      add(TasksUpdated(tasks));
    });

    unawaited(_repository.searchTasks(query: _currentQuery, page: 0));
  }

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

      await _repository.searchTasks(query: _currentQuery, page: nextPage);

      emit(current.copyWith(page: nextPage, isLoadingMore: false));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateTaskStatus event,
    Emitter<PatientTasksState> emit,
  ) async {
    try {
      await _repository.updateStatus(taskId: event.taskId, next: event.status);
    } catch (e) {
      emit(PatientTasksUiMessage(alertMessage: taskUpdateErrorMessage(e)));

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

  @override
  Future<void> close() async {
    await _tasksSubscription?.cancel();

    return super.close();
  }

  Future<void> _onRollbackMessageReceived(
    RollbackMessageReceived event,
    Emitter<PatientTasksState> emit,
  ) async {
    emit(PatientTasksUiMessage(alertMessage: event.message));

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
    final searchFiltered = tasks.where((task) {
      final query = _currentQuery.toLowerCase();

      return task.title.toLowerCase().contains(query);
    }).toList();

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
