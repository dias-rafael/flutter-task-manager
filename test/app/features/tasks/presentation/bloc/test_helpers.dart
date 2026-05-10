import 'package:task_manager_app/app/features/tasks/domain/domain.dart';

PatientTasks makeTask({
  String id = '1',
  String title = 'Task',
  TaskStatus status = TaskStatus.requested,
  TaskPriority priority = TaskPriority.routine,
  String patientReference = 'PatientA',
  DateTime? lastModified,
  DateTime? dueDate,
  String? assignee,
  int version = 1,
}) {
  return PatientTasks(
    id: id,
    version: version,
    title: title,
    status: status,
    priority: priority,
    patientReference: patientReference,
    lastModified: lastModified ?? DateTime.now(),
    dueDate: dueDate,
    assignee: assignee,
  );
}
