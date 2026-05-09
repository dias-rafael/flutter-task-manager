import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

class SyncManager {
  SyncManager({required this.repository});

  final PatientTasksRepository repository;

  Future<void> start() async {
    try {
      await repository.refresh();
    } catch (e, stackTrace) {
      debugPrint('Initial sync failed: $e');
    }
  }
}
