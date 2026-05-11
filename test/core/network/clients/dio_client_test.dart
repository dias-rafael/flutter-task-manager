import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/core/network/clients/dio_client.dart';
import 'package:task_manager_app/core/network/network_types.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late Dio dio;
  late DioClient client;

  setUpAll(() {
    registerFallbackValue(RequestOptions());
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    client = DioClient(dio);
  });

  group('DioClient', () {
    test(
      '''
get performs
request correctly
''',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {'success': true},
          ),
        );

        final result = await client.get<Map<String, dynamic>>('/tasks');

        expect(result.data?['success'], true);

        verify(
          () => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).called(1);
      },
    );

    test(
      '''
get uses custom
base url
''',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(requestOptions: RequestOptions(), data: {}),
        );

        await client.get<Map<String, dynamic>>(
          '/tasks',
          customBaseUrl: 'http://custom-api.com',
        );

        verify(
          () => dio.get<Map<String, dynamic>>(
            'http://custom-api.com/tasks',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).called(1);
      },
    );

    test(
      '''
patch performs
request correctly
''',
      () async {
        when(
          () => dio.patch<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {'success': true},
          ),
        );

        final result = await client.patch<Map<String, dynamic>>(
          '/tasks/1',
          data: {'status': 'completed'},
        );

        expect(result.data?['success'], true);

        verify(
          () => dio.patch<Map<String, dynamic>>(
            any(),
            data: {'status': 'completed'},
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).called(1);
      },
    );

    test(
      '''
get throws
NetworkException
''',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            message: 'Network error',
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 500,
            ),
          ),
        );

        expect(
          () => client.get<Map<String, dynamic>>('/tasks'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      '''
patch throws
NetworkException
''',
      () async {
        when(
          () => dio.patch<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            message: 'Patch error',
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 422,
            ),
          ),
        );

        expect(
          () => client.patch<Map<String, dynamic>>(
            '/tasks/1',
            data: {'status': 'completed'},
          ),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });
}
