import 'package:hive/hive.dart';

import '../../domain/domain.dart';

part 'patient_tasks_local_model.g.dart';

@HiveType(typeId: 0)
class PatientTasksLocalModel extends HiveObject {
  PatientTasksLocalModel({
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

  @HiveField(0)
  String id;

  @HiveField(1)
  int version;

  @HiveField(2)
  String title;

  @HiveField(3)
  String status;

  @HiveField(4)
  String priority;

  @HiveField(5)
  String patientReference;

  @HiveField(6)
  DateTime lastModified;

  @HiveField(7)
  DateTime? dueDate;

  @HiveField(8)
  String? assignee;

  PatientTasks toEntity() {
    return PatientTasks(
      id: id,
      version: version,
      title: title,
      status: TaskStatus.values.firstWhere((e) => e.name == status),
      priority: TaskPriority.values.firstWhere((e) => e.name == priority),
      patientReference: patientReference,
      lastModified: lastModified,
      dueDate: dueDate,
      assignee: assignee,
    );
  }

  static PatientTasksLocalModel fromEntity(PatientTasks task) {
    return PatientTasksLocalModel(
      id: task.id,
      version: task.version,
      title: task.title,
      status: task.status.name,
      priority: task.priority.name,
      patientReference: task.patientReference,
      lastModified: task.lastModified,
      dueDate: task.dueDate,
      assignee: task.assignee,
    );
  }
}
