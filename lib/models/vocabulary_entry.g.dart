// GENERATED CODE - DO NOT MODIFY BY HAND
// lib/models/vocabulary_entry.g.dart

part of 'vocabulary_entry.dart';

class VocabularyEntryAdapter extends TypeAdapter<VocabularyEntry> {
  @override
  final int typeId = 0;

  @override
  VocabularyEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabularyEntry(
      word: fields[0] as String,
      pinyin: fields[1] as String,
      meaning: fields[2] as String,
      statusIndex: fields[3] as int,
      firstSeen: fields[4] as DateTime,
      lastSeen: fields[5] as DateTime,
      inputFrequency: fields[6] as int,
      translationFrequency: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VocabularyEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.pinyin)
      ..writeByte(2)
      ..write(obj.meaning)
      ..writeByte(3)
      ..write(obj.statusIndex)
      ..writeByte(4)
      ..write(obj.firstSeen)
      ..writeByte(5)
      ..write(obj.lastSeen)
      ..writeByte(6)
      ..write(obj.inputFrequency)
      ..writeByte(7)
      ..write(obj.translationFrequency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
