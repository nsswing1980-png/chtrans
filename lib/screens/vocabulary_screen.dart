// lib/screens/vocabulary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/vocabulary_entry.dart';
import '../services/tts_service.dart';
import '../utils/app_theme.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadVocabulary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // タブバー
            Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textHint,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.wordNew, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('新出 (${provider.newWords.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.wordLearning, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('学習中 (${provider.learningWords.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.wordMastered, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('習得済み (${provider.masteredWords.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // タブコンテンツ
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWordList(provider.newWords, VocabStatus.newWord, provider),
                  _buildWordList(provider.learningWords, VocabStatus.learning, provider),
                  _buildWordList(provider.masteredWords, VocabStatus.mastered, provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordList(
    List<VocabularyEntry> words,
    VocabStatus currentStatus,
    AppProvider provider,
  ) {
    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: AppTheme.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              '単語がありません',
              style: TextStyle(color: AppTheme.textHint, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '翻訳すると自動的に記録されます',
              style: TextStyle(color: AppTheme.textHint, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return _buildWordCard(word, currentStatus, provider);
      },
    );
  }

  Widget _buildWordCard(
    VocabularyEntry word,
    VocabStatus currentStatus,
    AppProvider provider,
  ) {
    Color statusColor;
    Color statusBgColor;
    switch (currentStatus) {
      case VocabStatus.newWord:
        statusColor = AppTheme.wordNew;
        statusBgColor = AppTheme.wordNew.withValues(alpha: 0.08);
        break;
      case VocabStatus.learning:
        statusColor = AppTheme.wordLearning;
        statusBgColor = AppTheme.wordLearning.withValues(alpha: 0.08);
        break;
      case VocabStatus.mastered:
        statusColor = AppTheme.wordMastered;
        statusBgColor = AppTheme.wordMastered.withValues(alpha: 0.05);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusBgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              word.word.length > 2 ? word.word.substring(0, 2) : word.word,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              word.word,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            if (word.pinyin.isNotEmpty)
              Text(
                word.pinyin.length > 20 ? '${word.pinyin.substring(0, 20)}...' : word.pinyin,
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (word.meaning.isNotEmpty)
              Text(word.meaning, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.input, size: 12, color: AppTheme.textHint),
                const SizedBox(width: 2),
                Text('入力: ${word.inputFrequency}回', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                const SizedBox(width: 10),
                Icon(Icons.translate, size: 12, color: AppTheme.textHint),
                const SizedBox(width: 2),
                Text('翻訳: ${word.translationFrequency}回', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 読み上げボタン
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20),
              color: AppTheme.primary,
              onPressed: () => TtsService.speakChinese(word.word),
              tooltip: '読み上げ',
            ),
            // ワンタップ循環ステータス切り替えボタン
            GestureDetector(
              onTap: () {
                // 循環: 新出 → 学習中 → 習得済み → 新出
                final nextStatus = _nextStatus(currentStatus);
                provider.updateWordStatus(word.word, nextStatus);
              },
              child: Tooltip(
                message: 'タップでステータス変更（${_nextStatus(currentStatus).label}へ）',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        currentStatus.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.chevron_right, size: 14, color: statusColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // 削除ボタン（長押しメニューから単独ボタンに変更）
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('削除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  provider.deleteWord(word.word);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 循環: 新出 → 学習中 → 習得済み → 新出
  VocabStatus _nextStatus(VocabStatus current) {
    switch (current) {
      case VocabStatus.newWord:
        return VocabStatus.learning;
      case VocabStatus.learning:
        return VocabStatus.mastered;
      case VocabStatus.mastered:
        return VocabStatus.newWord;
    }
  }
}

extension VocabStatusLabel on VocabStatus {
  String get label {
    switch (this) {
      case VocabStatus.newWord:
        return '新出';
      case VocabStatus.learning:
        return '学習中';
      case VocabStatus.mastered:
        return '習得済み';
    }
  }
}
