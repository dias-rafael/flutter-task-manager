import '../../domain/domain.dart';

class PatientTaskModel extends PatientTask {
  const PatientTaskModel({
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

  factory PatientTaskModel.fromJson(Map<String, dynamic> json) {
    return PatientTaskModel(
      id: json['id'] as String,
      version: json['version'] as int,
      title: json['title'] as String,
      status: TaskStatus.values.firstWhere((e) => e == json['status']),
      priority: TaskPriority.values.firstWhere((e) => e == json['priority']),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'])
          : null,
      patientReference: json['patientReference'] as String,
      assignee: json['assignee'],
      lastModified: DateTime.parse(json['lastModified']),
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

  PatientTask toEntity() {
    return PatientTask(
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
