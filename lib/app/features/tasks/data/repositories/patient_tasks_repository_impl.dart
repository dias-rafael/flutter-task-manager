import 'dart:async';

import '../../domain/domain.dart';
import '../data.dart';

class PatientTasksRepositoryImpl implements PatientTasksRepository {
  PatientTasksRepositoryImpl({required this.local, required this.remote});
  final PatientTasksLocalDataSource local;
  final PatientTasksRemoteDataSource remote;

  @override
  Future<List<PatientTasksModel>> fetchTasks() async {
    try {
      final remoteData = await remote.fetchTasks();
      return remoteData;
    } catch (e) {
      rethrow;
    }
  }
}
