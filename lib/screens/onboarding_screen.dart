// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 設定値
  int _age = 25;
  String _gender = 'female';
  int _hskLevel = 3;
  int _toeicScore = 500;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    final provider = context.read<AppProvider>();
    provider.setAge(_age);
    provider.setGender(_gender);
    await provider.setHskLevel(_hskLevel);
    provider.setToeicScore(_toeicScore);
    await provider.markOnboardingDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // プログレスバー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(4, (i) {
                  final active = i <= _currentPage;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ページコンテンツ
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildAgePage(),
                  _buildGenderPage(),
                  _buildHskPage(),
                  _buildToeicPage(),
                ],
              ),
            ),

            // ナビゲーションボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('戻る'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == 3 ? '始める' : '次へ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== ページ1: 年齢 =====
  Widget _buildAgePage() {
    return _PageWrapper(
      icon: Icons.cake_outlined,
      title: 'あなたの年齢は？',
      subtitle: '翻訳の言葉遣いを年齢に合わせて調整します',
      child: Column(
        children: [
          // 現在の年齢を大きく表示
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppTheme.primary, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_age',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const Text('歳', style: TextStyle(fontSize: 14, color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // スライダー
          Slider(
            value: _age.toDouble(),
            min: 10,
            max: 70,
            divisions: 60,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.primary.withValues(alpha: 0.2),
            onChanged: (v) => setState(() => _age = v.round()),
          ),
          // 目盛りラベル
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['10代', '20代', '30代', '40代', '50代', '60代以上']
                  .map((s) => Text(s,
                      style: TextStyle(fontSize: 11, color: AppTheme.textHint)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          // 年齢レンジチップ
          Wrap(
            spacing: 8,
            children: [10, 18, 25, 35, 45, 55, 65].map((v) {
              final selected = _age == v;
              return ChoiceChip(
                label: Text('$v歳'),
                selected: selected,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => _age = v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===== ページ2: 性別 =====
  Widget _buildGenderPage() {
    return _PageWrapper(
      icon: Icons.people_outline,
      title: '性別を選択',
      subtitle: '話し言葉のスタイルを性別に合わせます',
      child: Row(
        children: [
          _GenderCard(
            label: '女性',
            icon: '👩',
            selected: _gender == 'female',
            onTap: () => setState(() => _gender = 'female'),
          ),
          const SizedBox(width: 16),
          _GenderCard(
            label: '男性',
            icon: '👨',
            selected: _gender == 'male',
            onTap: () => setState(() => _gender = 'male'),
          ),
        ],
      ),
    );
  }

  // ===== ページ3: HSKレベル =====
  Widget _buildHskPage() {
    const descriptions = [
      '超基礎：150語程度',
      '基礎：300語程度',
      '中級：600語程度',
      '中上級：1200語程度',
      '上級：2500語程度',
      '最上級：5000語以上',
    ];

    return _PageWrapper(
      icon: Icons.school_outlined,
      title: 'HSKレベルを選択',
      subtitle: '中国語翻訳の語彙難易度を設定します',
      child: Column(
        children: List.generate(6, (i) {
          final level = i + 1;
          final selected = _hskLevel == level;
          return GestureDetector(
            onTap: () => setState(() => _hskLevel = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppTheme.primary
                      : AppTheme.primary.withValues(alpha: 0.15),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'HSK$level',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      descriptions[i],
                      style: TextStyle(
                        color: selected ? AppTheme.primary : AppTheme.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===== ページ4: TOEICスコア =====
  Widget _buildToeicPage() {
    final level = _getToeicLevel(_toeicScore);

    return _PageWrapper(
      icon: Icons.language,
      title: 'TOEICスコアは？',
      subtitle: '英語翻訳の語彙・表現レベルを自動調整します',
      child: Column(
        children: [
          // スコア表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: level.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: level.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_toeicScore',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: level.color,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '点',
                      style: TextStyle(fontSize: 20, color: level.color),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: level.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        level.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.description,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // スライダー
          Slider(
            value: _toeicScore.toDouble(),
            min: 10,
            max: 990,
            divisions: 98,
            activeColor: level.color,
            inactiveColor: level.color.withValues(alpha: 0.2),
            onChanged: (v) => setState(() => _toeicScore = (v / 10).round() * 10),
          ),
          // スコア範囲ラベル
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['10', '200', '400', '600', '800', '990']
                  .map((s) => Text(s, style: TextStyle(fontSize: 11, color: AppTheme.textHint)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          // クイック選択チップ
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ToeicChip(score: 300, label: '初級'),
              _ToeicChip(score: 500, label: '中級'),
              _ToeicChip(score: 700, label: '上級'),
              _ToeicChip(score: 860, label: '英検準1級相当'),
              _ToeicChip(score: 990, label: 'ネイティブ'),
            ].map((chip) {
              final selected = _toeicScore == chip.score;
              return ChoiceChip(
                label: Text('${chip.score} (${chip.label})'),
                selected: selected,
                selectedColor: level.color,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _toeicScore = chip.score),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  _ToeicLevelInfo _getToeicLevel(int score) {
    if (score < 220) {
      return _ToeicLevelInfo(
        label: 'A (初級)',
        description: '基本的な日常単語・中学英語レベルで表示',
        color: Colors.red.shade400,
      );
    } else if (score < 470) {
      return _ToeicLevelInfo(
        label: 'B (中初級)',
        description: '日常会話レベル・簡単な文法で表示',
        color: Colors.orange.shade400,
      );
    } else if (score < 600) {
      return _ToeicLevelInfo(
        label: 'C (中級)',
        description: '高校英語レベル・一般的な表現で表示',
        color: Colors.amber.shade600,
      );
    } else if (score < 730) {
      return _ToeicLevelInfo(
        label: 'D (中上級)',
        description: 'ビジネス英語基礎・幅広い語彙で表示',
        color: Colors.green.shade500,
      );
    } else if (score < 860) {
      return _ToeicLevelInfo(
        label: 'E (上級)',
        description: 'ビジネス英語・専門語彙も含む表示',
        color: Colors.blue.shade500,
      );
    } else {
      return _ToeicLevelInfo(
        label: 'F (最上級)',
        description: '高度な表現・慣用句・自然な英語で表示',
        color: Colors.purple.shade400,
      );
    }
  }
}

// ===== 共通ページラッパー =====
class _PageWrapper extends StatelessWidget {
  const _PageWrapper({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          child,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ===== 性別カード =====
class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 160,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : AppTheme.primary.withValues(alpha: 0.2),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(Icons.check_circle,
                      color: AppTheme.primary, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToeicLevelInfo {
  final String label;
  final String description;
  final Color color;
  const _ToeicLevelInfo(
      {required this.label, required this.description, required this.color});
}

class _ToeicChip {
  final int score;
  final String label;
  const _ToeicChip({required this.score, required this.label});
}
