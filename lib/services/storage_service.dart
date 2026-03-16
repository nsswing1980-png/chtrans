// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vocabulary_entry.dart';
import '../models/translation_record.dart';

class StorageService {
  static const String _vocabBoxPrefix = 'vocabulary_';
  static const String _historyBoxPrefix = 'history_';

  static String _currentUserKey = 'guest_local'; // デフォルトはゲスト

  static Box<VocabularyEntry>? _vocabBox;
  static Box<TranslationRecord>? _historyBox;

  /// 現在のユーザーキー
  static String get currentUserKey => _currentUserKey;

  /// 初期化（アダプター登録）
  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(VocabularyEntryAdapter());
    Hive.registerAdapter(TranslationRecordAdapter());
    // ゲストボックスを開く
    await _openBoxes(_currentUserKey);
  }

  /// ユーザー切り替え時：対象ユーザーのボックスを開く
  static Future<void> switchUser(String userKey) async {
    if (_currentUserKey == userKey &&
        _vocabBox != null &&
        _vocabBox!.isOpen) {
      return; // 既に開いている
    }

    // 現在のボックスを閉じる（他ユーザーへ切替時）
    await _vocabBox?.close();
    await _historyBox?.close();

    _currentUserKey = userKey;
    await _openBoxes(userKey);
  }

  static Future<void> _openBoxes(String userKey) async {
    final safeKey = userKey.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    _vocabBox = await Hive.openBox<VocabularyEntry>(
      '$_vocabBoxPrefix$safeKey',
    );
    _historyBox = await Hive.openBox<TranslationRecord>(
      '$_historyBoxPrefix$safeKey',
    );
  }

  static Box<VocabularyEntry> get _vBox {
    assert(_vocabBox != null && _vocabBox!.isOpen, 'VocabBox not initialized');
    return _vocabBox!;
  }

  static Box<TranslationRecord> get _hBox {
    assert(_historyBox != null && _historyBox!.isOpen, 'HistoryBox not initialized');
    return _historyBox!;
  }

  // ========== 単語帳操作 ==========

  static List<VocabularyEntry> getAllVocabulary() {
    return _vBox.values.toList();
  }

  static VocabularyEntry? findWord(String word) {
    try {
      return _vBox.values.firstWhere((e) => e.word == word);
    } catch (_) {
      return null;
    }
  }

  static Future<void> recordWordFromInput(
    String word,
    String pinyin,
    String meaning,
  ) async {
    final existing = findWord(word);
    if (existing != null) {
      existing.inputFrequency++;
      existing.lastSeen = DateTime.now();
      await existing.save();
    } else {
      final entry = VocabularyEntry(
        word: word,
        pinyin: pinyin,
        meaning: meaning,
        statusIndex: VocabStatus.newWord.index,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
        inputFrequency: 1,
        translationFrequency: 0,
      );
      await _vBox.add(entry);
    }
  }

  static Future<void> recordWordFromTranslation(
    String word,
    String pinyin,
    String meaning,
  ) async {
    final existing = findWord(word);
    if (existing != null) {
      existing.translationFrequency++;
      existing.lastSeen = DateTime.now();
      await existing.save();
    } else {
      final entry = VocabularyEntry(
        word: word,
        pinyin: pinyin,
        meaning: meaning,
        statusIndex: VocabStatus.newWord.index,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
        inputFrequency: 0,
        translationFrequency: 1,
      );
      await _vBox.add(entry);
    }
  }

  static Future<void> updateWordStatus(String word, VocabStatus status) async {
    final existing = findWord(word);
    if (existing != null) {
      existing.statusIndex = status.index;
      await existing.save();
    }
  }

  static List<VocabularyEntry> getVocabularyByStatus(VocabStatus status) {
    return _vBox.values
        .where((e) => e.statusIndex == status.index)
        .toList();
  }

  static List<VocabularyEntry> getInputRanking({int limit = 20}) {
    final list = _vBox.values.toList();
    list.sort((a, b) => b.inputFrequency.compareTo(a.inputFrequency));
    return list.take(limit).toList();
  }

  static List<VocabularyEntry> getTranslationRanking({int limit = 20}) {
    final list = _vBox.values.toList();
    list.sort((a, b) => b.translationFrequency.compareTo(a.translationFrequency));
    return list.take(limit).toList();
  }

  static List<VocabularyEntry> getTotalRanking({int limit = 20}) {
    final list = _vBox.values.toList();
    list.sort((a, b) =>
        (b.inputFrequency + b.translationFrequency)
            .compareTo(a.inputFrequency + a.translationFrequency));
    return list.take(limit).toList();
  }

  // ========== 翻訳履歴操作 ==========

  static Future<void> saveTranslation(TranslationRecord record) async {
    await _hBox.add(record);
  }

  static List<TranslationRecord> getAllHistory() {
    final list = _hBox.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  static List<TranslationRecord> getHistoryByLang(String lang) {
    final list = _hBox.values
        .where((r) => r.inputLang == lang)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  static Map<String, int> getStatistics() {
    return {
      'totalTranslations': _hBox.length,
      'totalVocabulary': _vBox.length,
      'newWords': getVocabularyByStatus(VocabStatus.newWord).length,
      'learningWords': getVocabularyByStatus(VocabStatus.learning).length,
      'masteredWords': getVocabularyByStatus(VocabStatus.mastered).length,
      'jaToZhCount': getHistoryByLang('ja').length,
      'zhToJaCount': getHistoryByLang('zh').length,
    };
  }

  static Future<void> deleteHistory(int index) async {
    await _hBox.deleteAt(index);
  }

  /// timestamp の ISO文字列リストに合致する履歴を削除
  static Future<void> deleteHistoryByTimestamps(List<String> ids) async {
    final toDelete = _hBox.values
        .where((r) => ids.contains(r.timestamp.toIso8601String()))
        .toList();
    for (final record in toDelete) {
      await record.delete();
    }
  }

  static Future<void> deleteVocabulary(String word) async {
    final entry = findWord(word);
    if (entry != null) await entry.delete();
  }
}
