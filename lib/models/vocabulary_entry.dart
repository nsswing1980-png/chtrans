// lib/models/vocabulary_entry.dart
import 'package:hive/hive.dart';

part 'vocabulary_entry.g.dart';

/// 単語の習得ステータス
enum VocabStatus { newWord, learning, mastered }

@HiveType(typeId: 0)
class VocabularyEntry extends HiveObject {
  @HiveField(0)
  String word; // 中国語の単語

  @HiveField(1)
  String pinyin; // 拼音

  @HiveField(2)
  String meaning; // 日本語意味

  @HiveField(3)
  int statusIndex; // 0=new, 1=learning, 2=mastered

  @HiveField(4)
  DateTime firstSeen; // 初出現日時

  @HiveField(5)
  DateTime lastSeen; // 最終出現日時

  @HiveField(6)
  int inputFrequency; // 入力時の出現回数

  @HiveField(7)
  int translationFrequency; // 翻訳結果での出現回数

  VocabularyEntry({
    required this.word,
    required this.pinyin,
    required this.meaning,
    this.statusIndex = 0,
    required this.firstSeen,
    required this.lastSeen,
    this.inputFrequency = 0,
    this.translationFrequency = 0,
  });

  VocabStatus get status => VocabStatus.values[statusIndex];
  set status(VocabStatus s) => statusIndex = s.index;
}
