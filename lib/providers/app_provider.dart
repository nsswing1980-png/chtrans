// lib/providers/app_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/vocabulary_entry.dart';
import '../models/translation_record.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

enum TranslationState { idle, loading, success, error }

class AppProvider extends ChangeNotifier {
  // ========== 認証状態 ==========
  UserProfile? _currentUser;
  bool _isAuthChecked = false; // 起動時の認証復元が完了したか

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAuthChecked => _isAuthChecked;

  /// アプリ起動時に AuthService を初期化して前回ログイン状態を復元
  Future<void> initAuth() async {
    final auth = AuthService();
    await auth.initialize();
    if (auth.currentUser != null) {
      _currentUser = auth.currentUser;
      await StorageService.switchUser(_currentUser!.storageKey);
      await checkOnboarding();
      loadVocabulary();
      loadHistory();
    }
    _isAuthChecked = true;
    notifyListeners();
  }

  /// ログイン成功後に呼ぶ
  Future<void> onLogin(UserProfile profile) async {
    _currentUser = profile;
    await AuthService().switchAccount(profile);
    await StorageService.switchUser(profile.storageKey);
    await checkOnboarding();
    // 新しいユーザーのデータを読み込み
    loadVocabulary();
    loadHistory();
    resetTranslation();
    notifyListeners();
  }

  /// ログアウト
  Future<void> logout() async {
    await AuthService().signOut();
    _currentUser = null;
    await StorageService.switchUser('guest_local');
    loadVocabulary();
    loadHistory();
    resetTranslation();
    notifyListeners();
  }

  // ========== オンボーディング ==========
  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;

  /// オンボーディング完了済みかをチェック（ユーザーごとに保存）
  Future<void> checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'onboarding_done_${_currentUser?.storageKey ?? "guest"}';
    _onboardingDone = prefs.getBool(key) ?? false;
    // 設定値も復元
    _age = prefs.getInt('age_${_currentUser?.storageKey ?? "guest"}') ?? 25;
    _gender = prefs.getString('gender_${_currentUser?.storageKey ?? "guest"}') ?? 'female';
    _hskLevel = prefs.getInt('hsk_${_currentUser?.storageKey ?? "guest"}') ?? 3;
    _toeicScore = prefs.getInt('toeic_${_currentUser?.storageKey ?? "guest"}') ?? 500;
    notifyListeners();
  }

  /// オンボーディング完了マーク
  Future<void> markOnboardingDone() async {
    _onboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    final key = 'onboarding_done_${_currentUser?.storageKey ?? "guest"}';
    await prefs.setBool(key, true);
    await _saveSettings();
    notifyListeners();
  }

  /// 設定を SharedPreferences に保存
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = _currentUser?.storageKey ?? 'guest';
    await prefs.setInt('age_$userKey', _age);
    await prefs.setString('gender_$userKey', _gender);
    await prefs.setInt('hsk_$userKey', _hskLevel);
    await prefs.setInt('toeic_$userKey', _toeicScore);
  }

  // ========== 設定 ==========
  int _hskLevel = 3;
  int _age = 25;
  String _gender = 'female'; // 'male' or 'female'
  int _toeicScore = 500;

  int get hskLevel => _hskLevel;
  int get age => _age;
  String get gender => _gender;
  int get toeicScore => _toeicScore;

  void setToeicScore(int score) {
    _toeicScore = score;
    _saveSettings();
    notifyListeners();
  }

  /// HSKレベルを変更し、翻訳済みなら自動再翻訳
  Future<void> setHskLevel(int level) async {
    if (_hskLevel == level) return;
    _hskLevel = level;
    _saveSettings();
    notifyListeners();
    // 翻訳結果が存在し、かつ日本語→中国語の翻訳の場合のみ再翻訳
    if (_state == TranslationState.success &&
        _inputText.isNotEmpty &&
        _detectedLang == 'ja') {
      await translate(_inputText);
    }
  }

  void setAge(int age) {
    _age = age;
    _saveSettings();
    notifyListeners();
  }

  void setGender(String gender) {
    _gender = gender;
    _saveSettings();
    notifyListeners();
  }

  // ========== 翻訳状態 ==========
  TranslationState _state = TranslationState.idle;
  TranslationResult? _result;
  String _detectedLang = 'ja';
  String _inputText = '';
  String _errorMessage = '';

  TranslationState get state => _state;
  TranslationResult? get result => _result;
  String get detectedLang => _detectedLang;
  String get inputText => _inputText;
  String get errorMessage => _errorMessage;

  /// 翻訳実行
  Future<void> translate(String text) async {
    if (text.trim().isEmpty) return;

    _inputText = text.trim();
    _detectedLang = TranslationService.detectLanguage(_inputText);
    _state = TranslationState.loading;
    _result = null;
    notifyListeners();

    try {
      TranslationResult result;
      if (_detectedLang == 'ja') {
        result = await TranslationService.translateJaToZh(
          text: _inputText,
          hskLevel: _hskLevel,
          age: _age,
          gender: _gender,
          toeicScore: _toeicScore,
        );
      } else {
        result = await TranslationService.translateZhToJa(
          text: _inputText,
          toeicScore: _toeicScore,
        );
      }

      _result = result;
      _state = TranslationState.success;

      // 履歴保存
      final record = TranslationRecord(
        inputText: _inputText,
        inputLang: _detectedLang,
        outputText: result.translatedText,
        pinyin: result.pinyin,
        backTranslation: result.backTranslation,
        englishTranslation: result.englishTranslation,
        hskLevel: _hskLevel,
        age: _age,
        gender: _gender,
        timestamp: DateTime.now(),
        newWordsFound: [],
      );
      await StorageService.saveTranslation(record);

      // 単語を記録
      await _recordWords(result.chineseWords, result.pinyin, isInput: _detectedLang == 'zh');
    } catch (e) {
      _errorMessage = '翻訳に失敗しました: $e';
      _state = TranslationState.error;
    }

    notifyListeners();
  }

  /// 単語を記録（入力 or 翻訳結果として）
  Future<void> _recordWords(List<String> words, String pinyinStr, {required bool isInput}) async {
    for (final word in words) {
      if (word.length < 1) continue;
      final pinyin = _extractPinyin(word, pinyinStr);
      if (isInput) {
        await StorageService.recordWordFromInput(word, pinyin, '');
      } else {
        await StorageService.recordWordFromTranslation(word, pinyin, '');
      }
    }
    notifyListeners();
  }

  String _extractPinyin(String word, String fullPinyin) {
    // 簡易：拼音文字列から対応部分を抽出
    return fullPinyin.length > 10 ? fullPinyin.substring(0, 10) : fullPinyin;
  }

  void resetTranslation() {
    _state = TranslationState.idle;
    _result = null;
    _inputText = '';
    notifyListeners();
  }

  // ========== 単語帳 ==========
  List<VocabularyEntry> _vocabulary = [];

  List<VocabularyEntry> get vocabulary => _vocabulary;

  List<VocabularyEntry> get newWords =>
      _vocabulary.where((v) => v.statusIndex == VocabStatus.newWord.index).toList();
  List<VocabularyEntry> get learningWords =>
      _vocabulary.where((v) => v.statusIndex == VocabStatus.learning.index).toList();
  List<VocabularyEntry> get masteredWords =>
      _vocabulary.where((v) => v.statusIndex == VocabStatus.mastered.index).toList();

  void loadVocabulary() {
    _vocabulary = StorageService.getAllVocabulary();
    notifyListeners();
  }

  Future<void> updateWordStatus(String word, VocabStatus status) async {
    await StorageService.updateWordStatus(word, status);
    loadVocabulary();
  }

  Future<void> deleteWord(String word) async {
    await StorageService.deleteVocabulary(word);
    loadVocabulary();
  }

  /// 単語のステータスを取得（翻訳結果の色分け用）
  VocabStatus? getWordStatus(String word) {
    final entry = StorageService.findWord(word);
    return entry?.status;
  }

  // ========== 履歴 ==========
  List<TranslationRecord> _history = [];
  List<TranslationRecord> get history => _history;
  List<TranslationRecord> get jaHistory => _history.where((r) => r.inputLang == 'ja').toList();
  List<TranslationRecord> get zhHistory => _history.where((r) => r.inputLang == 'zh').toList();

  void loadHistory() {
    _history = StorageService.getAllHistory();
    notifyListeners();
  }

  Future<void> deleteHistoryItem(int index) async {
    await StorageService.deleteHistory(index);
    loadHistory();
  }

  /// ID（timestamp の ISO文字列）で複数履歴を一括削除
  Future<void> deleteHistoryByIds(List<String> ids) async {
    await StorageService.deleteHistoryByTimestamps(ids);
    loadHistory();
  }

  // ========== 統計 ==========
  Map<String, int> get statistics => StorageService.getStatistics();

  List<VocabularyEntry> get inputRanking => StorageService.getInputRanking();
  List<VocabularyEntry> get translationRanking => StorageService.getTranslationRanking();
  List<VocabularyEntry> get totalRanking => StorageService.getTotalRanking();
}
