import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/app/features/tasks/domain/domain.dart';
import 'package:task_manager_app/app/features/tasks/presentation/bloc/patient_tasks_bloc.dart';

import 'test_helpers.dart';

class MockPatientTasksRepository extends Mock
    implements PatientTasksRepository {}

void main() {
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

      when(
        () => repository.watchTasks(),
      ).thenAnswer((_) => tasksController.stream);

      when(
        () => repository.searchTasks(
          query: any(named: 'query'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => repository.updateStatus(
          taskId: any(named: 'taskId'),
          next: any(named: 'next'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => repository.watchPendingSyncCount(),
      ).thenAnswer((_) => Stream<int>.value(0));

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

    test('initial state is PatientTasksInitial', () {
      expect(bloc.state, isA<PatientTasksInitial>());
    });

    test('LoadTasks subscribes and triggers initial remote search', () async {
      bloc.add(LoadTasks());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => repository.searchTasks(query: '', page: 0)).called(1);
    });

    test('emits loaded state on LoadTasks', () async {
      final emittedStates = <PatientTasksState>[];
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(LoadTasks());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      tasksController.add(mockTasks);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
        emittedStates.whereType<PatientTasksLoading>(),
        isNotEmpty,
      );
      expect(emittedStates.last, isA<PatientTasksLoaded>());

      final loaded = emittedStates.last as PatientTasksLoaded;

      expect(loaded.tasks.length, 2);

      await subscription.cancel();
    });

    test('calls repository on UpdateTaskStatus', () async {
      bloc.add(UpdateTaskStatus(taskId: '1', status: TaskStatus.inProgress));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(
        () => repository.updateStatus(taskId: '1', next: TaskStatus.inProgress),
      ).called(1);
    });

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

    test(
      '''
FilterChanged emits only
completed tasks
''',
      () async {
        final emittedStates = <PatientTasksState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

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

        bloc.add(FilterChanged(TaskFilter.completed));

        await Future<void>.delayed(const Duration(milliseconds: 100));

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

    test('LoadNextPage fetches next page and increments page', () async {
      final emittedStates = <PatientTasksState>[];
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(LoadTasks());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      tasksController.add(mockTasks);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      bloc.add(LoadNextPage());

      await Future<void>.delayed(const Duration(milliseconds: 150));

      verify(() => repository.searchTasks(query: '', page: 1)).called(1);

      final loadedStates = emittedStates
          .whereType<PatientTasksLoaded>()
          .toList();

      expect(loadedStates.last.page, 1);
      expect(loadedStates.last.isLoadingMore, false);

      await subscription.cancel();
    });

    test('LoadNextPage clears loading flag when search fails', () async {
      final emittedStates = <PatientTasksState>[];
      final subscription = bloc.stream.listen(emittedStates.add);

      when(
        () => repository.searchTasks(
          query: any(named: 'query'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((invocation) async {
        final page = invocation.namedArguments[const Symbol('page')] as int;
        if (page == 1) {
          throw Exception('offline');
        }
      });

      bloc.add(LoadTasks());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      tasksController.add(mockTasks);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      bloc.add(LoadNextPage());

      await Future<void>.delayed(const Duration(milliseconds: 150));

      final loadedStates = emittedStates
          .whereType<PatientTasksLoaded>()
          .toList();

      expect(loadedStates.last.page, 0);
      expect(loadedStates.last.isLoadingMore, false);

      await subscription.cancel();
    });

    test(
      'notifyRollbackMessage emits alert then restores loaded state',
      () async {
        final emittedStates = <PatientTasksState>[];
        final subscription = bloc.stream.listen(emittedStates.add);

        bloc.add(LoadTasks());

        await Future<void>.delayed(const Duration(milliseconds: 50));

        tasksController.add(mockTasks);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        bloc.notifyRollbackMessage('sync rolled back');

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final uiMessages = emittedStates
            .whereType<PatientTasksUiMessage>()
            .toList();

        expect(uiMessages.single.alertMessage, 'sync rolled back');

        expect(emittedStates.last, isA<PatientTasksLoaded>());

        await subscription.cancel();
      },
    );
  });
}
