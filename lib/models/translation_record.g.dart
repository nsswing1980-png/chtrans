// GENERATED CODE - DO NOT MODIFY BY HAND
// lib/models/translation_record.g.dart

part of 'translation_record.dart';

class TranslationRecordAdapter extends TypeAdapter<TranslationRecord> {
  @override
  final int typeId = 1;

  @override
  TranslationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranslationRecord(
      inputText: fields[0] as String,
      inputLang: fields[1] as String,
      outputText: fields[2] as String,
      pinyin: fields[3] as String? ?? '',
      backTranslation: fields[4] as String? ?? '',
      englishTranslation: fields[5] as String? ?? '',
      hskLevel: fields[6] as int,
      age: fields[7] as int,
      gender: fields[8] as String,
      timestamp: fields[9] as DateTime,
      newWordsFound: (fields[10] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, TranslationRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.inputText)
      ..writeByte(1)
      ..write(obj.inputLang)
      ..writeByte(2)
      ..write(obj.outputText)
      ..writeByte(3)
      ..write(obj.pinyin)
      ..writeByte(4)
      ..write(obj.backTranslation)
      ..writeByte(5)
      ..write(obj.englishTranslation)
      ..writeByte(6)
      ..write(obj.hskLevel)
      ..writeByte(7)
      ..write(obj.age)
      ..writeByte(8)
      ..write(obj.gender)
      ..writeByte(9)
      ..write(obj.timestamp)
      ..writeByte(10)
      ..write(obj.newWordsFound);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
