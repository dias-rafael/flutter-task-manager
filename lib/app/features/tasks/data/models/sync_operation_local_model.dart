import 'dart:convert';

import 'package:hive/hive.dart';

part 'sync_operation_local_model.g.dart';

@HiveType(typeId: 99)
class SyncOperationLocalModel extends HiveObject {
  SyncOperationLocalModel({
    required this.id,
    required this.taskId,
    required this.type,
    required this.payloadJson,
    required this.retryCount,
    required this.createdAt,
    required this.nextRetryAt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String type;

  @HiveField(3)
  String payloadJson;

  @HiveField(4)
  int retryCount;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime nextRetryAt;

  Map<String, dynamic> get payload {
    return jsonDecode(payloadJson) as Map<String, dynamic>;
  }

  SyncOperationLocalModel copyWith({
    String? id,
    String? taskId,
    String? type,
    String? payloadJson,
    int? retryCount,
    DateTime? createdAt,
    DateTime? nextRetryAt,
  }) {
    return SyncOperationLocalModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      type: type ?? this.type,
      payloadJson: payloadJson ?? this.payloadJson,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return '''
SyncOperationLocalModel(
  id: $id,
  taskId: $taskId,
  type: $type,
  retryCount: $retryCount,
  createdAt: $createdAt,
  nextRetryAt: $nextRetryAt,
  payload: $payload
)
''';
  }
}
