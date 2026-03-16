// lib/widgets/pinyin_text.dart
// 漢字の上に拼音を表示するウィジェット
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/translation_service.dart';
import '../providers/app_provider.dart';
import '../models/vocabulary_entry.dart';
import 'package:provider/provider.dart';

class PinyinTextWidget extends StatelessWidget {
  final String chineseText;
  final String pinyinText;
  final double fontSize;
  final bool showWordColors;

  const PinyinTextWidget({
    super.key,
    required this.chineseText,
    required this.pinyinText,
    this.fontSize = 22,
    this.showWordColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final pinyinParts = pinyinText.split(' ');
    final chars = chineseText.split('');

    // 漢字と拼音をペアリング
    List<Widget> charWidgets = [];
    int pinyinIndex = 0;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(char);
      String py = '';
      if (isChinese && pinyinIndex < pinyinParts.length) {
        py = pinyinParts[pinyinIndex];
        pinyinIndex++;
      }

      Color charColor = AppTheme.textPrimary;
      if (showWordColors) {
        final provider = context.read<AppProvider>();
        final status = provider.getWordStatus(char);
        if (status == VocabStatus.newWord) {
          charColor = AppTheme.wordNew;
        } else if (status == VocabStatus.learning) {
          charColor = AppTheme.wordLearning;
        } else if (status == VocabStatus.mastered) {
          charColor = AppTheme.wordMastered;
        }
      }

      charWidgets.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              py.isNotEmpty ? py : ' ',
              style: TextStyle(
                fontSize: fontSize * 0.45,
                color: AppTheme.accent,
                height: 1.2,
              ),
            ),
            Text(
              char,
              style: TextStyle(
                fontSize: fontSize,
                color: charColor,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 2,
      runSpacing: 4,
      children: charWidgets,
    );
  }
}

/// 差分ハイライト付きテキスト
class DiffTextWidget extends StatelessWidget {
  final String originalText;
  final String comparedText;
  final double fontSize;

  const DiffTextWidget({
    super.key,
    required this.originalText,
    required this.comparedText,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final diffs = TranslationService.computeDiff(originalText, comparedText);

    return RichText(
      text: TextSpan(
        children: diffs.map((diff) {
          final text = diff.$1;
          final isDiff = diff.$2;
          return TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              color: isDiff ? AppTheme.accent : AppTheme.textPrimary,
              backgroundColor: isDiff
                  ? AppTheme.wordHighlight
                  : Colors.transparent,
              fontWeight: isDiff ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }
}
