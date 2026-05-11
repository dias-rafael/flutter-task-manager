import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/app/features/tasks/domain/domain.dart';
import 'package:task_manager_app/app/features/tasks/presentation/bloc/patient_tasks_bloc.dart';
import 'package:task_manager_app/app/features/tasks/presentation/pages/patient_tasks_page.dart';

class MockPatientTasksRepository extends Mock
    implements PatientTasksRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(TaskStatus.inProgress);
  });

  group('PatientTasksPage', () {
    late MockPatientTasksRepository repository;
    late PatientTasksBloc bloc;

    setUp(() {
      repository = MockPatientTasksRepository();

      when(() => repository.watchTasks()).thenAnswer(
        (_) => const Stream.empty(),
      );

      when(() => repository.watchPendingSyncCount()).thenAnswer(
        (_) => Stream<int>.value(0),
      );

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

      bloc = PatientTasksBloc(repository: repository);
    });

    tearDown(() async {
      await bloc.close();
    });

    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PatientTasksPage(blocForTesting: bloc),
        ),
      );

      await tester.pump();

      expect(find.text('Patient Tasks'), findsOneWidget);
    });

    testWidgets('exposes PatientTasksBloc under BlocProvider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PatientTasksPage(blocForTesting: bloc),
        ),
      );

      await tester.pump();

      expect(find.byType(BlocProvider<PatientTasksBloc>), findsOneWidget);
    });
  });
}
