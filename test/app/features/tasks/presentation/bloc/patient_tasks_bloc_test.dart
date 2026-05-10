import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/app/features/tasks/domain/domain.dart';
import 'package:task_manager_app/app/features/tasks/presentation/bloc/patient_tasks_bloc.dart';

import 'test_helpers.dart';

class MockPatientTasksRepository extends Mock
    implements PatientTasksRepository {}

void main() {
  // ======================================================
  // MOCKTAIL FALLBACKS
  // ======================================================

  setUpAll(() {
    registerFallbackValue(TaskStatus.inProgress);
  });

  group('PatientTasksBloc', () {
    late MockPatientTasksRepository repository;

    late PatientTasksBloc bloc;

    late List<PatientTasks> mockTasks;

    late StreamController<List<PatientTasks>> tasksController;

    setUp(() {
      repository = MockPatientTasksRepository();

      tasksController = StreamController<List<PatientTasks>>.broadcast();

      // ===================================================
      // WATCH TASKS
      // ===================================================

      when(
        () => repository.watchTasks(),
      ).thenAnswer((_) => tasksController.stream);

      // ===================================================
      // SEARCH TASKS
      // ===================================================

      when(
        () => repository.searchTasks(
          query: any(named: 'query'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async {});

      // ===================================================
      // UPDATE STATUS
      // ===================================================

      when(
        () => repository.updateStatus(
          taskId: any(named: 'taskId'),
          next: any(named: 'next'),
        ),
      ).thenAnswer((_) async {});

      bloc = PatientTasksBloc(repository: repository);

      mockTasks = [
        makeTask(title: 'Task 1'),

        makeTask(id: '2', title: 'Task 2', status: TaskStatus.inProgress),
      ];
    });

    tearDown(() async {
      await bloc.close();

      await tasksController.close();
    });

    // ======================================================
    // INITIAL STATE
    // ======================================================

    test('initial state is PatientTasksInitial', () {
      expect(bloc.state, isA<PatientTasksInitial>());
    });

    // ======================================================
    // LOAD TASKS
    // ======================================================

    test('emits loaded state on LoadTasks', () async {
      final emittedStates = <PatientTasksState>[];

      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(LoadTasks());

      // IMPORTANT:
      // allow stream subscription
      // to initialize

      await Future<void>.delayed(const Duration(milliseconds: 50));

      tasksController.add(mockTasks);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emittedStates.isNotEmpty, true);

      expect(emittedStates.last, isA<PatientTasksLoaded>());

      final loaded = emittedStates.last as PatientTasksLoaded;

      expect(loaded.tasks.length, 2);

      await subscription.cancel();
    });

    // ======================================================
    // UPDATE STATUS
    // ======================================================

    test('calls repository on UpdateTaskStatus', () async {
      bloc.add(UpdateTaskStatus(taskId: '1', status: TaskStatus.inProgress));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(
        () => repository.updateStatus(taskId: '1', next: TaskStatus.inProgress),
      ).called(1);
    });

    // ======================================================
    // ROLLBACK / ERROR UI
    // ======================================================

    test(
      '''
emits PatientTasksUiMessage
when update fails
''',
      () async {
        when(
          () =>
              repository.updateStatus(taskId: '1', next: TaskStatus.completed),
        ).thenThrow(Exception('conflict'));

        final emittedStates = <PatientTasksState>[];

        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(UpdateTaskStatus(taskId: '1', status: TaskStatus.completed));

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          emittedStates.any((state) => state is PatientTasksUiMessage),
          true,
        );

        await subscription.cancel();
      },
    );

    // ======================================================
    // ORDER PRESERVATION
    // ======================================================

    test('rapid toggling preserves ordering', () async {
      bloc
        ..add(UpdateTaskStatus(taskId: '1', status: TaskStatus.inProgress))
        ..add(UpdateTaskStatus(taskId: '2', status: TaskStatus.completed));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verifyInOrder([
        () => repository.updateStatus(taskId: '1', next: TaskStatus.inProgress),

        () => repository.updateStatus(taskId: '2', next: TaskStatus.completed),
      ]);
    });

    // ======================================================
    // SEARCH DEBOUNCE
    // ======================================================

    test(
      '''
search debounce keeps
latest query only
''',
      () async {
        final emittedStates = <PatientTasksState>[];

        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(LoadTasks());

        await Future<void>.delayed(const Duration(milliseconds: 100));

        tasksController.add(mockTasks);

        await Future<void>.delayed(const Duration(milliseconds: 300));

        bloc
          ..add(SearchTasks('Task 1'))
          ..add(SearchTasks('Task 2'));

        await Future<void>.delayed(const Duration(milliseconds: 500));

        final loadedStates = emittedStates
            .whereType<PatientTasksLoaded>()
            .toList();

        expect(loadedStates.isNotEmpty, true);

        final latest = loadedStates.last;

        expect(latest.tasks.length, 1);

        expect(latest.tasks.first.title, 'Task 2');

        await subscription.cancel();
      },
    );

    // ======================================================
    // FILTERS
    // ======================================================

    test(
      '''
FilterChanged emits only
completed tasks
''',
      () async {
        final emittedStates = <PatientTasksState>[];

        final subscription = bloc.stream.listen(emittedStates.add);

        // --------------------------------------------------
        // LOAD INITIAL TASKS
        // --------------------------------------------------

        bloc.add(LoadTasks());

        await Future<void>.delayed(const Duration(milliseconds: 100));

        tasksController.add([
          makeTask(title: 'Pending Task', status: TaskStatus.onHold),

          makeTask(
            id: '2',
            title: 'Completed Task',
            status: TaskStatus.completed,
          ),

          makeTask(
            id: '3',
            title: 'Cancelled Task',
            status: TaskStatus.cancelled,
          ),
        ]);

        await Future<void>.delayed(const Duration(milliseconds: 200));

        // --------------------------------------------------
        // APPLY FILTER
        // --------------------------------------------------

        bloc.add(FilterChanged(TaskFilter.completed));

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // --------------------------------------------------
        // ASSERT
        // --------------------------------------------------

        final loadedStates = emittedStates
            .whereType<PatientTasksLoaded>()
            .toList();

        expect(loadedStates.isNotEmpty, true);

        final latest = loadedStates.last;

        expect(latest.filter, TaskFilter.completed);

        expect(latest.tasks.length, 1);

        expect(latest.tasks.first.title, 'Completed Task');

        await subscription.cancel();
      },
    );
  });
}
