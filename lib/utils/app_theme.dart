// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // カラーパレット（スタイルA：セージグリーン×コーラル）
  static const Color primary = Color(0xFF4A9B8E);       // ミュートティール
  static const Color primaryLight = Color(0xFF7BBFB5);
  static const Color primaryDark = Color(0xFF2D7A6E);
  static const Color accent = Color(0xFFE8856A);         // ソフトコーラル
  static const Color accentLight = Color(0xFFF2AA94);
  static const Color background = Color(0xFFFFF8F0);     // クリームホワイト
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF5F0EA);
  static const Color textPrimary = Color(0xFF2C3E35);    // ダークチャコール
  static const Color textSecondary = Color(0xFF6B7C76);
  static const Color textHint = Color(0xFFAAB8B3);

  // 単語ステータスカラー
  static const Color wordNew = Color(0xFFE53935);        // 赤（新出単語）
  static const Color wordLearning = Color(0xFFF9A825);   // 黄（学習中）
  static const Color wordMastered = Color(0xFF9E9E9E);   // グレー（習得済み）
  static const Color wordHighlight = Color(0xFFFFE0B2);  // 差分ハイライト

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: surface,
          background: background,
        ),
        scaffoldBackgroundColor: background,
        fontFamily: 'sans-serif',
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primary.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardBg,
          selectedColor: primary,
          labelStyle: const TextStyle(fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}
