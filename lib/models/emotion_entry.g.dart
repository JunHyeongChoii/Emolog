// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmotionEntryAdapter extends TypeAdapter<EmotionEntry> {
  @override
  final int typeId = 0;

  @override
  EmotionEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmotionEntry()
      ..date = fields[0] as String
      ..score = fields[1] as int
      ..emoji = fields[2] as String
      ..memo = fields[3] as String
      ..createdAt = fields[4] as String;
  }

  @override
  void write(BinaryWriter writer, EmotionEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.memo)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
