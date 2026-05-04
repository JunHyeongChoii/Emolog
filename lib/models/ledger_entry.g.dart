// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerEntryAdapter extends TypeAdapter<LedgerEntry> {
  @override
  final int typeId = 2;

  @override
  LedgerEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerEntry()
      ..date = fields[0] as String
      ..amount = fields[1] as int
      ..type = fields[2] as String
      ..category = fields[3] as String
      ..categoryEmoji = fields[4] as String
      ..memo = fields[5] as String
      ..createdAt = fields[6] as String;
  }

  @override
  void write(BinaryWriter writer, LedgerEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.categoryEmoji)
      ..writeByte(5)
      ..write(obj.memo)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
