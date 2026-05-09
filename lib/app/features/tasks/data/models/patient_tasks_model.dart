import '../../domain/domain.dart';

class PatientTasksModel {
  PatientTasksModel({
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

  factory PatientTasksModel.fromJson(Map<String, dynamic> json) {
    return PatientTasksModel(
      id: json['id'] as String,
      version: json['version'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      patientReference: json['reference'] as String,
      lastModified: DateTime.parse(json['last_update'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      assignee: json['assignee'] as String?,
    );
  }

  final String id;
  final int version;
  final String title;
  final String status;
  final String priority;
  final String patientReference;
  final DateTime lastModified;
  final DateTime? dueDate;
  final String? assignee;

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
}
