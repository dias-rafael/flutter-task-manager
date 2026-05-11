import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/app/features/tasks/data/data.dart';
import 'package:task_manager_app/app/features/tasks/data/data_sources/mock_api/mock_patient_task_api.dart';
import 'package:task_manager_app/core/network/network.dart';
import 'package:task_manager_app/core/network/network_types.dart';

class MockNetwork extends Mock implements Network {}

class MockRealtimeApi extends Mock implements MockPatientTaskApi {}

void main() {
  late Network network;
  late MockPatientTaskApi realtimeApi;
  late PatientTasksRemoteDataSource datasource;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    network = MockNetwork();
    realtimeApi = MockRealtimeApi();
    datasource = PatientTasksRemoteDataSourceImpl(network, realtimeApi);
  });

  group('PatientTasksRemoteDataSource', () {
    test(
      '''
fetchTasks maps
response correctly
''',
      () async {
        when(
          () => network.get<Map<String, dynamic>>(
            any(),

            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),

            data: {
              'patient_tasks': [
                {
                  'id': '1',
                  'version': 1,
                  'title': 'Task 1',
                  'status': 'pending',
                  'priority': 'medium',
                  'reference': 'patient-1',
                  'last_modified': DateTime.now().toIso8601String(),
                  'due_date': null,
                  'assignee': null,
                },
              ],
              'total': 1,
            },
          ),
        );

        final result = await datasource.fetchTasks();

        expect(result.length, 1);
        expect(result.first.title, 'Task 1');
      },
    );

    test(
      '''
patchStatus sends
correct payload
''',
      () async {
        when(
          () => network.patch<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {
              'id': '1',
              'version': 2,
              'title': 'Task 1',
              'status': 'completed',
              'priority': 'medium',
              'reference': 'patient-1',
              'last_modified': DateTime.now().toIso8601String(),
              'due_date': null,
              'assignee': null,
            },
          ),
        );

        await datasource.patchStatus(
          taskId: '1',
          version: 2,
          status: 'completed',
        );

        verify(
          () => network.patch<Map<String, dynamic>>(
            '/tasks/1',
            data: {'version': 2, 'status': 'completed'},
            headers: any(named: 'headers'),
          ),
        ).called(1);
      },
    );

    test(
      '''
fetchTask maps
response correctly
''',
      () async {
        when(() => network.get<Map<String, dynamic>>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {
              'id': '1',
              'version': 1,
              'title': 'Task 1',
              'status': 'pending',
              'priority': 'medium',
              'reference': 'patient-1',
              'last_modified': DateTime.now().toIso8601String(),
              'due_date': null,
              'assignee': null,
            },
          ),
        );

        final result = await datasource.fetchTask('1');

        expect(result.id, '1');
        expect(result.title, 'Task 1');
      },
    );

    test(
      '''
patchStatus throws
ConflictException
on 409
''',
      () async {
        when(
          () => network.patch<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 409,
            ),
          ),
        );

        expect(
          () => datasource.patchStatus(
            taskId: '1',
            version: 1,
            status: 'completed',
          ),
          throwsA(isA<ConflictException>()),
        );
      },
    );

    test(
      '''
patchStatus throws
ValidationException
on 422
''',
      () async {
        when(
          () => network.patch<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 422,
            ),
          ),
        );

        expect(
          () => datasource.patchStatus(
            taskId: '1',
            version: 1,
            status: 'completed',
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  });
}
