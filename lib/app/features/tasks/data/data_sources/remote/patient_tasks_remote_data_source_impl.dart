import 'package:dio/dio.dart';

import '../../../../../../core/network/network.dart';
import '../../../../../../core/network/network_types.dart';
import '../../../domain/domain.dart';
import '../../models/patient_tasks_model.dart';
import '../mock_api/mock_patient_task_api.dart';
import 'patient_tasks_remote_data_source.dart';

const String tasksEndPoint = '/tasks';

class PatientTasksRemoteDataSourceImpl implements PatientTasksRemoteDataSource {
  PatientTasksRemoteDataSourceImpl(this._client, this._realtimeApi);

  final Network _client;

  final MockPatientTaskApi _realtimeApi;

  CancelToken? _searchCancelToken;

  // ----------------------------------------------------------
  // FETCH TASKS
  // ----------------------------------------------------------

  @override
  Future<List<PatientTasks>> fetchTasks({
    String query = '',
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      CancelToken? cancelToken;

      // only searchable requests
      // should be cancellable

      if (query.isNotEmpty) {
        _searchCancelToken?.cancel();

        _searchCancelToken = CancelToken();

        cancelToken = _searchCancelToken;
      }

      final response = await _client.get<Map<String, dynamic>>(
        tasksEndPoint,

        queryParameters: {'query': query, 'page': page, 'page_size': pageSize},

        cancelToken: cancelToken,
      );

      final data = response.data!['patient_tasks'] as List<dynamic>;

      return data
          .map(
            (json) => PatientTasksModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return [];
      }

      rethrow;
    }
  }
  // ----------------------------------------------------------
  // PATCH STATUS
  // ----------------------------------------------------------

  @override
  Future<void> patchStatus({
    required String taskId,
    required int version,
    required String status,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/tasks/$taskId',

        data: {'version': version, 'status': status},

        // TEMPORARY:
        // used to simulate conflicts
        // in Mockoon
        headers: {
          // remove later if desired
          // 'x-force-conflict': 'true',
        },
      );

      // IMPORTANT:
      // simulate realtime push

      if (response.data != null) {
        final updated = PatientTasksModel.fromJson(response.data!);

        _realtimeApi.emitUpdate(updated);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      // ------------------------------------------------------
      // CONFLICT
      // ------------------------------------------------------

      if (statusCode == 409) {
        throw ConflictException(message: 'Conflict detected');
      }

      // ------------------------------------------------------
      // PERMANENT REJECTION
      // ------------------------------------------------------

      if (statusCode == 400 || statusCode == 403 || statusCode == 422) {
        throw ValidationException(
          message:
              e.response?.data?['message']?.toString() ?? 'Invalid mutation',
        );
      }

      // ------------------------------------------------------
      // TRANSIENT FAILURE
      // ------------------------------------------------------

      rethrow;
    }
  }

  // ----------------------------------------------------------
  // REALTIME UPDATES
  // ----------------------------------------------------------

  @override
  Stream<PatientTasks> watchTaskUpdates() {
    return _realtimeApi.taskUpdates().map((dto) => dto.toEntity());
  }

  // ----------------------------------------------------------
  // FETCH SINGLE TASK
  // ----------------------------------------------------------

  @override
  Future<PatientTasks> fetchTask(String taskId) async {
    final response = await _client.get<Map<String, dynamic>>('/tasks/$taskId');

    return PatientTasksModel.fromJson(response.data!).toEntity();
  }
}
