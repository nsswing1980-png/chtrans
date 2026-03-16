// lib/models/translation_record.dart
import 'package:hive/hive.dart';

part 'translation_record.g.dart';

@HiveType(typeId: 1)
class TranslationRecord extends HiveObject {
  @HiveField(0)
  String inputText;

  @HiveField(1)
  String inputLang; // 'ja' or 'zh'

  @HiveField(2)
  String outputText; // 翻訳結果（中国語または日本語）

  @HiveField(3)
  String pinyin; // 拼音（中国語の場合）

  @HiveField(4)
  String backTranslation; // 逆翻訳テキスト

  @HiveField(5)
  String englishTranslation; // 英語翻訳

  @HiveField(6)
  int hskLevel;

  @HiveField(7)
  int age;

  @HiveField(8)
  String gender; // 'male' or 'female'

  @HiveField(9)
  DateTime timestamp;

  @HiveField(10)
  List<String> newWordsFound; // この翻訳で見つかった新出単語

  TranslationRecord({
    required this.inputText,
    required this.inputLang,
    required this.outputText,
    this.pinyin = '',
    this.backTranslation = '',
    this.englishTranslation = '',
    required this.hskLevel,
    required this.age,
    required this.gender,
    required this.timestamp,
    this.newWordsFound = const [],
  });
}
