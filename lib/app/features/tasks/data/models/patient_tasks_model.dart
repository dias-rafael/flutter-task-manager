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
      lastModified: _parseDate(json['last_modified']) ?? DateTime.now(),
      dueDate: _parseDate(json['due_date']),
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
      status: TaskStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == status.toLowerCase(),
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name.toLowerCase() == priority.toLowerCase(),
      ),
      patientReference: patientReference,
      lastModified: lastModified,
      dueDate: dueDate,
      assignee: assignee,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final string = value.toString().trim();

    if (string.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(string);
    } catch (_) {
      return null;
    }
  }
}
