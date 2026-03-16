// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/vocabulary_entry.dart';
import '../services/tts_service.dart';
import '../utils/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final stats = provider.statistics;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== サマリーカード =====
              _buildSummaryCards(stats),
              const SizedBox(height: 20),

              // ===== 単語ステータス分布 =====
              _buildStatusDistribution(stats),
              const SizedBox(height: 20),

              // ===== ランキングセクション =====
              _buildRankingSection(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '学習サマリー',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _statCard('総翻訳回数', '${stats['totalTranslations']}回',
                Icons.translate, AppTheme.primary),
            _statCard('学習単語数', '${stats['totalVocabulary']}語',
                Icons.menu_book, AppTheme.accent),
            _statCard('日→中翻訳', '${stats['jaToZhCount']}回',
                Icons.arrow_forward, const Color(0xFF4CAF50)),
            _statCard('中→日翻訳', '${stats['zhToJaCount']}回',
                Icons.arrow_back, const Color(0xFF2196F3)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution(Map<String, int> stats) {
    final newCount = stats['newWords'] ?? 0;
    final learningCount = stats['learningWords'] ?? 0;
    final masteredCount = stats['masteredWords'] ?? 0;
    final total = newCount + learningCount + masteredCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            '単語習得状況',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Center(
              child: Text(
                'まだデータがありません',
                style: TextStyle(color: AppTheme.textHint),
              ),
            )
          else ...[
            // プログレスバー
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (newCount > 0)
                    Expanded(
                      flex: newCount,
                      child: Container(
                        height: 20,
                        color: AppTheme.wordNew,
                      ),
                    ),
                  if (learningCount > 0)
                    Expanded(
                      flex: learningCount,
                      child: Container(
                        height: 20,
                        color: AppTheme.wordLearning,
                      ),
                    ),
                  if (masteredCount > 0)
                    Expanded(
                      flex: masteredCount,
                      child: Container(
                        height: 20,
                        color: AppTheme.wordMastered,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusLegend(AppTheme.wordNew, '新出', newCount, total),
                _statusLegend(AppTheme.wordLearning, '学習中', learningCount, total),
                _statusLegend(AppTheme.wordMastered, '習得済み', masteredCount, total),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusLegend(Color color, String label, int count, int total) {
    final percent = total > 0 ? (count / total * 100).round() : 0;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        Text(
          '$count語 ($percent%)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingSection(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '単語ランキング',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        // タブ
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textHint,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: '合計'),
              Tab(text: '入力'),
              Tab(text: '翻訳結果'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRankingList(provider.totalRanking, 'total'),
              _buildRankingList(provider.inputRanking, 'input'),
              _buildRankingList(provider.translationRanking, 'translation'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList(List<VocabularyEntry> words, String type) {
    if (words.isEmpty) {
      return Center(
        child: Text('データがありません', style: TextStyle(color: AppTheme.textHint)),
      );
    }

    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        final count = type == 'input'
            ? word.inputFrequency
            : type == 'translation'
                ? word.translationFrequency
                : word.inputFrequency + word.translationFrequency;

        Color rankColor;
        Widget rankWidget;
        if (index == 0) {
          rankColor = const Color(0xFFFFD700);
          rankWidget = const Text('🥇', style: TextStyle(fontSize: 20));
        } else if (index == 1) {
          rankColor = const Color(0xFFC0C0C0);
          rankWidget = const Text('🥈', style: TextStyle(fontSize: 20));
        } else if (index == 2) {
          rankColor = const Color(0xFFCD7F32);
          rankWidget = const Text('🥉', style: TextStyle(fontSize: 20));
        } else {
          rankColor = AppTheme.textHint;
          rankWidget = Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: rankColor,
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              SizedBox(width: 32, child: Center(child: rankWidget)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (word.pinyin.isNotEmpty)
                      Text(
                        word.pinyin.length > 15
                            ? '${word.pinyin.substring(0, 15)}...'
                            : word.pinyin,
                        style: TextStyle(fontSize: 12, color: AppTheme.accent),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 18),
                color: AppTheme.primary,
                onPressed: () => TtsService.speakChinese(word.word),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count回',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
