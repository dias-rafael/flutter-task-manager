import 'package:hive/hive.dart';

part 'sync_operation_local_model.g.dart';

@HiveType(typeId: 1)
class SyncOperationLocalModel extends HiveObject {
  SyncOperationLocalModel({
    required this.id,
    required this.taskId,
    required this.payload,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  Map<String, dynamic> payload;
}
