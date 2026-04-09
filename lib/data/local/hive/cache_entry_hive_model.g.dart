// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_entry_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheEntryHiveModelAdapter extends TypeAdapter<CacheEntryHiveModel> {
  @override
  final int typeId = 1;

  @override
  CacheEntryHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheEntryHiveModel(
      cacheKey: fields[0] as String,
      jsonData: fields[1] as String,
      expiresAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CacheEntryHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.cacheKey)
      ..writeByte(1)
      ..write(obj.jsonData)
      ..writeByte(2)
      ..write(obj.expiresAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheEntryHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
