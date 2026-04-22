// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoEntryAdapter extends TypeAdapter<TodoEntry> {
  @override
  final int typeId = 1;

  @override
  TodoEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoEntry()
      ..title = fields[0] as String
      ..isDone = fields[1] as bool
      ..date = fields[2] as String
      ..createdAt = fields[3] as String
      ..repeatType = fields[4] as String
      ..repeatDays = (fields[5] as List).cast<int>()
      ..repeatDay = fields[6] as int;
  }

  @override
  void write(BinaryWriter writer, TodoEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.isDone)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.repeatType)
      ..writeByte(5)
      ..write(obj.repeatDays)
      ..writeByte(6)
      ..write(obj.repeatDay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
