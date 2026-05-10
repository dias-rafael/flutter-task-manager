import 'package:flutter/foundation.dart';

import '../../../../../../core/network/network.dart';
import '../../../domain/domain.dart';
import '../../models/patient_tasks_model.dart';
import 'patient_tasks_remote_data_source.dart';

const String tasksEndPoint = '/tasks';

class PatientTasksRemoteDataSourceImpl implements PatientTasksRemoteDataSource {
  PatientTasksRemoteDataSourceImpl(this._client);

  final Network _client;

  @override
  Future<List<PatientTasks>> fetchTasks() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(tasksEndPoint);

      final data = response.data!['patient_tasks'] as List<dynamic>;

      return data
          .map(
            (json) => PatientTasksModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      rethrow;
    }
  }

  @override
  Future<void> patchStatus({
    required String taskId,
    required int version,
    required String status,
  }) async {
    await _client.patch<void>(
      '/tasks/$taskId',
      data: {'version': version, 'status': status},
    );
  }

  @override
  Stream<PatientTasks> watchTaskUpdates() {
    return _client.taskUpdates().map((dto) => dto.toEntity());
  }

  @override
  Future<PatientTasks> fetchTask(String taskId) async {
    final response = await _client.get('/tasks/$taskId');

    return PatientTasksModel.fromJson(
      response.data as Map<String, dynamic>,
    ).toEntity();
  }
}
