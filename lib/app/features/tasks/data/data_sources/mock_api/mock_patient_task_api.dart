import 'dart:async';

import '../../models/patient_tasks_model.dart';

class MockPatientTaskApi {
  MockPatientTaskApi();

  final _controller = StreamController<PatientTasksModel>.broadcast();

  Stream<PatientTasksModel> taskUpdates() {
    return _controller.stream;
  }

  void emitUpdate(PatientTasksModel task) {
    _controller.add(task);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
