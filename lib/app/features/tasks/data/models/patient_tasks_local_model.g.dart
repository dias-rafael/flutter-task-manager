// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_tasks_local_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientTasksLocalModelAdapter
    extends TypeAdapter<PatientTasksLocalModel> {
  @override
  final int typeId = 0;

  @override
  PatientTasksLocalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientTasksLocalModel(
      id: fields[0] as String,
      version: fields[1] as int,
      title: fields[2] as String,
      status: fields[3] as String,
      priority: fields[4] as String,
      patientReference: fields[5] as String,
      lastModified: fields[6] as DateTime,
      dueDate: fields[7] as DateTime?,
      assignee: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PatientTasksLocalModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.version)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.patientReference)
      ..writeByte(6)
      ..write(obj.lastModified)
      ..writeByte(7)
      ..write(obj.dueDate)
      ..writeByte(8)
      ..write(obj.assignee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientTasksLocalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
