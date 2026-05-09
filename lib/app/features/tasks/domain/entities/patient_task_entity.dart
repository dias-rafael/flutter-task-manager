import 'package:equatable/equatable.dart';

import '../enums/enums.dart';

class PatientTasks with EquatableMixin {
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

  @override
  List<Object?> get props => [
    id,
    version,
    title,
    status,
    priority,
    dueDate,
    patientReference,
    assignee,
    lastModified,
  ];
}
