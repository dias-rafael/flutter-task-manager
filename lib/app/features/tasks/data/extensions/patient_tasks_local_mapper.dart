import '../../domain/domain.dart';
import '../data.dart';

extension PatientTaskDtoMapper on PatientTasksModel {
  PatientTasks toEntity() {
    return PatientTasks(
      id: id,
      version: version,
      title: title,
      status: _mapStatus(status),
      priority: _mapPriority(priority),
      patientReference: patientReference,
      lastModified: lastModified,
      dueDate: dueDate,
      assignee: assignee,
    );
  }

  TaskStatus _mapStatus(String value) {
    switch (value) {
      case 'requested':
        return TaskStatus.requested;

      case 'in_progress':
        return TaskStatus.inProgress;

      case 'on_hold':
        return TaskStatus.onHold;

      case 'completed':
        return TaskStatus.completed;

      case 'cancelled':
        return TaskStatus.cancelled;

      default:
        return TaskStatus.requested;
    }
  }

  TaskPriority _mapPriority(String value) {
    switch (value) {
      case 'routine':
        return TaskPriority.routine;

      case 'urgent':
        return TaskPriority.urgent;

      case 'asap':
        return TaskPriority.asap;

      case 'stat':
        return TaskPriority.stat;

      default:
        return TaskPriority.routine;
    }
  }
}
