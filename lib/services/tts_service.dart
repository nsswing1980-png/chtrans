// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('TTS init error: $e');
    }
  }

  /// 中国語テキストを読み上げ
  static Future<void> speakChinese(String text) async {
    if (!_isInitialized) await initialize();
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.speak(text);
    } catch (e) {
      if (kDebugMode) debugPrint('TTS speak error: $e');
    }
  }

  /// 読み上げを停止
  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('TTS stop error: $e');
    }
  }

  static bool get isSupported => _isInitialized;
}
