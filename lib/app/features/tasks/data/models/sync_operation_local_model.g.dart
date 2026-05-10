// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncOperationLocalModelAdapter
    extends TypeAdapter<SyncOperationLocalModel> {
  @override
  final int typeId = 99;

  @override
  SyncOperationLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncOperationLocalModel(
      id: fields[0] as String,
      taskId: fields[1] as String,
      type: fields[2] as String,
      payloadJson: fields[3] as String,
      retryCount: fields[4] as int,
      createdAt: fields[5] as DateTime,
      nextRetryAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperationLocalModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.payloadJson)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.nextRetryAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
