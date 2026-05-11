import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/app/features/tasks/data/data.dart';
import 'package:task_manager_app/app/features/tasks/data/data_sources/mock_api/mock_patient_task_api.dart';

void main() {
  late MockPatientTaskApi api;

  setUp(() {
    api = MockPatientTaskApi();
  });

  tearDown(() async {
    await api.dispose();
  });

  group('MockPatientTaskApi', () {
    test(
      '''
emitUpdate emits
task updates
''',
      () async {
        final emitted = <PatientTasksModel>[];
        final subscription = api.taskUpdates().listen(emitted.add);
        final task = PatientTasksModel(
          id: '1',
          version: 1,
          title: 'Task 1',
          status: 'pending',
          priority: 'medium',
          patientReference: 'patient-1',
          lastModified: DateTime.now(),
        );

        api.emitUpdate(task);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(emitted.length, 1);
        expect(emitted.first.id, '1');
        expect(emitted.first.title, 'Task 1');

        await subscription.cancel();
      },
    );

    test(
      '''
multiple listeners receive
same emitted update
''',
      () async {
        final emittedA = <PatientTasksModel>[];
        final emittedB = <PatientTasksModel>[];
        final subscriptionA = api.taskUpdates().listen(emittedA.add);
        final subscriptionB = api.taskUpdates().listen(emittedB.add);
        final task = PatientTasksModel(
          id: '1',
          version: 1,
          title: 'Task 1',
          status: 'pending',
          priority: 'medium',
          patientReference: 'patient-1',
          lastModified: DateTime.now(),
        );

        api.emitUpdate(task);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(emittedA.length, 1);
        expect(emittedB.length, 1);
        expect(emittedA.first.id, '1');
        expect(emittedB.first.id, '1');

        await subscriptionA.cancel();
        await subscriptionB.cancel();
      },
    );

    test(
      '''
dispose closes
stream controller
''',
      () async {
        await api.dispose();

        expect(api.taskUpdates(), emitsDone);
      },
    );
  });
}
