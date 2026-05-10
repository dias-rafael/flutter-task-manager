import 'package:hive/hive.dart';

part 'sync_operation_local_model.g.dart';

@HiveType(typeId: 1)
class SyncOperationLocalModel extends HiveObject {
  SyncOperationLocalModel({
    required this.id,
    required this.taskId,
    required this.type,
    required this.payload,
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
  Map<String, dynamic> payload;

  @HiveField(4)
  int retryCount;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime nextRetryAt;
}
