import '../../../../../../core/network/network.dart';
import '../../models/patient_tasks_model.dart';
import 'patient_tasks_remote_data_source.dart';

const String tasksEndPoint = '/tasks';

class PatientTasksRemoteDataSourceImpl implements PatientTasksRemoteDataSource {
  PatientTasksRemoteDataSourceImpl(this._client);

  final Network _client;

  @override
  Future<List<PatientTasksModel>> fetchTasks() async {
    final response = await _client.get<Map<String, dynamic>>(tasksEndPoint);

    final result = response.data != null
        ? List<PatientTasksModel>.from(
            (response.data!['patient_tasks'] as List).map(
              (e) => PatientTasksModel.fromJson(e as Map<String, dynamic>),
            ),
          )
        : throw Exception('Failed to load tasks');

    return result;
  }
}
