// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncOperationLocalModelAdapter
    extends TypeAdapter<SyncOperationLocalModel> {
  @override
  final int typeId = 1;

  @override
  SyncOperationLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncOperationLocalModel(
      id: fields[0] as String,
      taskId: fields[1] as String,
      payload: (fields[2] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperationLocalModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.payload);
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
