import '../enums/enums.dart';
import 'invalid_task_transition_exception.dart';

class PatientTasks {
  const PatientTasks({
    required this.id,
    required this.version,
    required this.title,
    required this.status,
    required this.priority,
    required this.patientReference,
    required this.lastModified,
    this.dueDate,
    this.assignee,
  });
  final String id;
  final int version;
  final String title;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String patientReference;
  final String? assignee;
  final DateTime lastModified;

  bool canTransitionTo(TaskStatus next) {
    switch (status) {
      case TaskStatus.requested:
        return [TaskStatus.inProgress, TaskStatus.cancelled].contains(next);

      case TaskStatus.inProgress:
        return [
          TaskStatus.onHold,
          TaskStatus.completed,
          TaskStatus.cancelled,
        ].contains(next);

      case TaskStatus.onHold:
        return [TaskStatus.inProgress, TaskStatus.cancelled].contains(next);

      case TaskStatus.completed:
      case TaskStatus.cancelled:
      case TaskStatus.unknown:
        return false;
    }
  }

  PatientTasks transitionTo(TaskStatus next) {
    if (!canTransitionTo(next)) {
      throw InvalidTaskTransitionException(current: status, attempted: next);
    }

    return copyWith(
      status: next,
      version: version + 1,
      lastModified: DateTime.now(),
    );
  }

  bool get isOverdue {
    if (dueDate == null) {
      return false;
    }

    return dueDate!.isBefore(DateTime.now()) && status != TaskStatus.completed;
  }

  bool get isAssigned {
    return assignee != null;
  }

  PatientTasks copyWith({
    int? version,
    String? title,
    TaskStatus? status,
    TaskPriority? priority,
    String? patientReference,
    DateTime? lastModified,
    DateTime? dueDate,
    String? assignee,
  }) {
    return PatientTasks(
      id: id,
      version: version ?? this.version,
      title: title ?? this.title,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      patientReference: patientReference ?? this.patientReference,
      lastModified: lastModified ?? this.lastModified,
      dueDate: dueDate ?? this.dueDate,
      assignee: assignee ?? this.assignee,
    );
  }
}
