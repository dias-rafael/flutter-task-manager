import 'dart:async';

import '../../models/patient_tasks_model.dart';

class MockPatientTaskApi {
  MockPatientTaskApi();

  final _controller = StreamController<PatientTasksModel>.broadcast();

  // ----------------------------------------------------------
  // REALTIME STREAM
  // ----------------------------------------------------------

  Stream<PatientTasksModel> taskUpdates() {
    return _controller.stream;
  }

  // ----------------------------------------------------------
  // EMIT SERVER UPDATE
  // ----------------------------------------------------------

  void emitUpdate(PatientTasksModel task) {
    _controller.add(task);
  }

  // ----------------------------------------------------------
  // CLEANUP
  // ----------------------------------------------------------

  Future<void> dispose() async {
    await _controller.close();
  }
}
