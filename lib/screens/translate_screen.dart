// lib/screens/translate_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../utils/app_theme.dart';
import '../widgets/pinyin_text.dart';
import '../models/vocabulary_entry.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _controller = TextEditingController();
  bool _isSpeaking = false;
  bool _isPasting = false;
  bool _showAgeSettings = false; // 年齢設定の表示フラグ（初期非表示）

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await TtsService.speakChinese(text);
    setState(() => _isSpeaking = false);
  }

  /// テキストをクリップボードにコピーしてSnackBarで通知
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$labelをコピーしました'),
            ],
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 小さなコピーボタンウィジェット
  Widget _buildCopyButton(String text, String label) {
    return IconButton(
      onPressed: () => _copyToClipboard(text, label),
      icon: const Icon(Icons.copy_rounded, size: 17),
      tooltip: '$labelをコピー',
      color: AppTheme.textSecondary,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// クリップボードから貼り付けて自動翻訳
  Future<void> _pasteAndTranslate(AppProvider provider) async {
    setState(() => _isPasting = true);
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('クリップボードにテキストがありません'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      // 既存の入力を消去して貼り付け
      _controller.text = text.trim();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      // 自動翻訳実行
      await provider.translate(text.trim());
    } finally {
      if (mounted) setState(() => _isPasting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 入力セクション =====
              _buildInputSection(provider),
              const SizedBox(height: 12),

              // ===== HSKレベル選択 =====
              _buildHskSelector(provider),
              const SizedBox(height: 12),

              // ===== 年齢・性別設定 =====
              _buildUserSettings(provider),
              const SizedBox(height: 16),

              // ===== 翻訳結果 =====
              if (provider.state == TranslationState.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),

              if (provider.state == TranslationState.error)
                _buildErrorCard(provider.errorMessage),

              if (provider.state == TranslationState.success && provider.result != null)
                _buildResultSection(provider),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 入力エリア =====
  Widget _buildInputSection(AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '日本語または中国語を入力',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              // クリップボード貼り付けボタン
              _isPasting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent,
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _pasteAndTranslate(provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.content_paste_rounded,
                                size: 15, color: AppTheme.accent),
                            const SizedBox(width: 4),
                            Text(
                              '貼り付けて翻訳',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'ここに入力...',
              hintStyle: TextStyle(color: AppTheme.textHint),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // クリアボタン
              if (_controller.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    _controller.clear();
                    provider.resetTranslation();
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('クリア'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              const SizedBox(width: 8),
              // 翻訳ボタン
              ElevatedButton.icon(
                onPressed: provider.state == TranslationState.loading
                    ? null
                    : () => provider.translate(_controller.text),
                icon: const Icon(Icons.translate, size: 18),
                label: const Text('翻訳'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== HSKレベル選択 =====
  Widget _buildHskSelector(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: AppTheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'HSKレベル',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'HSK ${provider.hskLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) {
              final level = i + 1;
              final isSelected = provider.hskLevel == level;
              return GestureDetector(
                onTap: () => provider.setHskLevel(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.textHint,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('初級', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              Text('上級', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  // ===== ユーザー設定（年齢・性別） =====
  Widget _buildUserSettings(AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== ヘッダー行（常に表示） =====
          InkWell(
            onTap: () => setState(() => _showAgeSettings = !_showAgeSettings),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '話者設定',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 現在の設定をコンパクト表示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${provider.age}歳 ${provider.gender == 'female' ? '♀' : '♂'}',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '翻訳スタイルに影響',
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _showAgeSettings ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: AppTheme.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ===== 展開コンテンツ =====
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showAgeSettings
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // 性別選択
                        Row(
                          children: [
                            Text('性別：',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(width: 8),
                            _genderChip('female', '女性', Icons.female, provider),
                            const SizedBox(width: 8),
                            _genderChip('male', '男性', Icons.male, provider),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 年齢スライダー
                        Row(
                          children: [
                            Text('年齢：',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${provider.age}歳',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: provider.age.toDouble(),
                          min: 10,
                          max: 70,
                          divisions: 12,
                          activeColor: AppTheme.primary,
                          inactiveColor:
                              AppTheme.primary.withValues(alpha: 0.2),
                          label: '${provider.age}歳',
                          onChanged: (v) => provider.setAge(v.round()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('10代',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textHint)),
                            Text('20代',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textHint)),
                            Text('30代',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textHint)),
                            Text('40代',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textHint)),
                            Text('50代+',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textHint)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // TOEICスコア設定
                        Row(
                          children: [
                            Icon(Icons.language, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text('TOEIC:',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _toeicColor(provider.toeicScore)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _toeicColor(provider.toeicScore)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '${provider.toeicScore}点 (${_toeicLevelLabel(provider.toeicScore)})',
                                style: TextStyle(
                                  color: _toeicColor(provider.toeicScore),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: provider.toeicScore.toDouble(),
                          min: 10,
                          max: 990,
                          divisions: 98,
                          activeColor: _toeicColor(provider.toeicScore),
                          inactiveColor: _toeicColor(provider.toeicScore)
                              .withValues(alpha: 0.2),
                          label: '${provider.toeicScore}点',
                          onChanged: (v) =>
                              provider.setToeicScore((v / 10).round() * 10),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Color _toeicColor(int score) {
    if (score < 220) return Colors.red.shade400;
    if (score < 470) return Colors.orange.shade400;
    if (score < 600) return Colors.amber.shade600;
    if (score < 730) return Colors.green.shade500;
    if (score < 860) return Colors.blue.shade500;
    return Colors.purple.shade400;
  }

  String _toeicLevelLabel(int score) {
    if (score < 220) return 'A';
    if (score < 470) return 'B';
    if (score < 600) return 'C';
    if (score < 730) return 'D';
    if (score < 860) return 'E';
    return 'F';
  }

  Widget _genderChip(String value, String label, IconData icon, AppProvider provider) {
    final isSelected = provider.gender == value;
    return GestureDetector(
      onTap: () => provider.setGender(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.textHint,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 翻訳結果表示 =====
  Widget _buildResultSection(AppProvider provider) {
    final result = provider.result!;
    final isJaInput = provider.detectedLang == 'ja';

    return Column(
      children: [
        // ===== メイン翻訳カード =====
        _buildMainTranslationCard(provider, result, isJaInput),
        const SizedBox(height: 12),

        // ===== 逆翻訳・差分カード =====
        _buildBackTranslationCard(provider, result, isJaInput),
        const SizedBox(height: 12),

        // ===== 英語翻訳カード =====
        _buildEnglishCard(result),
        const SizedBox(height: 12),

        // ===== 単語凡例 =====
        _buildWordLegend(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMainTranslationCard(AppProvider provider, result, bool isJaInput) {
    final String chineseText = isJaInput ? result.translatedText : provider.inputText;
    final String japaneseText = isJaInput ? provider.inputText : result.translatedText;
    final String pinyin = result.pinyin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isJaInput ? '日 → 中' : '中 → 日',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              // コピーボタン（中国語）
              _buildCopyButton(chineseText, '中国語'),
              const SizedBox(width: 4),
              // 読み上げボタン
              IconButton(
                onPressed: () => _speak(chineseText),
                icon: Icon(
                  _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                  color: AppTheme.accent,
                ),
                tooltip: '中国語を読み上げ',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 中国語 + 拼音
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('中国語', style: TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('拼音付き', style: TextStyle(fontSize: 11, color: AppTheme.accent)),
                  ],
                ),
                const SizedBox(height: 8),
                PinyinTextWidget(
                  chineseText: chineseText,
                  pinyinText: pinyin,
                  fontSize: 22,
                  showWordColors: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 日本語
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('日本語', style: TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _buildCopyButton(japaneseText, '日本語'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  japaneseText,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackTranslationCard(AppProvider provider, result, bool isJaInput) {
    final originalText = isJaInput ? provider.inputText : provider.inputText;
    final backText = result.backTranslation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isJaInput ? '逆翻訳（中→日）' : '逆翻訳（日→中）',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '※差分をハイライト表示',
                  style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                ),
              ),
              const Spacer(),
              _buildCopyButton(backText, '逆翻訳'),
            ],
          ),
          const SizedBox(height: 12),

          // 元のテキスト
          Text(
            '元テキスト：',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            originalText,
            style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
          ),
          const Divider(height: 20),

          // 逆翻訳（差分ハイライト）
          Text(
            '逆翻訳結果：',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          DiffTextWidget(
            originalText: originalText,
            comparedText: backText,
            fontSize: 15,
          ),

          // 中国語逆翻訳の場合は拼音も
          if (!isJaInput && result.backTranslation.isNotEmpty) ...[
            const SizedBox(height: 12),
            IconButton.filled(
              onPressed: () => _speak(result.backTranslation),
              icon: const Icon(Icons.volume_up, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                foregroundColor: AppTheme.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnglishCard(result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '英語',
              style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.englishTranslation,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
            ),
          ),
          _buildCopyButton(result.englishTranslation as String, '英語'),
        ],
      ),
    );
  }

  Widget _buildWordLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(AppTheme.wordNew, '新出単語'),
          _legendItem(AppTheme.wordLearning, '学習中'),
          _legendItem(AppTheme.wordMastered, '習得済み'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
