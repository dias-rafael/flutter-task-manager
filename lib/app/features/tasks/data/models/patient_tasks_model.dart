import '../../domain/domain.dart';

class PatientTasksModel extends PatientTasks {
  const PatientTasksModel({
    required super.id,
    required super.version,
    required super.title,
    required super.status,
    required super.priority,
    required super.patientReference,
    required super.lastModified,
    super.dueDate,
    super.assignee,
  });

  factory PatientTasksModel.fromJson(Map<String, dynamic> json) {
    TaskStatus parseStatus(String? value) {
      if (value == null) {
        return TaskStatus.unknown;
      }
      return TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == value,
        orElse: () => TaskStatus.unknown,
      );
    }

    TaskPriority parsePriority(String? value) {
      if (value == null) {
        return TaskPriority.unknown;
      }
      return TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == value,
        orElse: () => TaskPriority.unknown,
      );
    }

    return PatientTasksModel(
      id: json['id'] as String,
      version: json['version'] as int,
      title: json['title'] as String,
      status: parseStatus(json['status'] as String?),
      priority: parsePriority(json['priority'] as String?),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      patientReference: json['reference'] as String,
      assignee: json['assignee'] as String?,
      lastModified: DateTime.parse(json['last_update'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'title': title,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'patientReference': patientReference,
      'assignee': assignee,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  PatientTasks toEntity() {
    return PatientTasks(
      id: id,
      version: version,
      title: title,
      status: status,
      priority: priority,
      dueDate: dueDate,
      patientReference: patientReference,
      assignee: assignee,
      lastModified: lastModified,
    );
  }
}
