// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/translation_record.dart';
import '../services/tts_service.dart';
import '../utils/app_theme.dart';
import '../widgets/pinyin_text.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 選択モード
  bool _selectionMode = false;
  final Set<String> _selectedIds = {}; // record の timestamp.toString() をキーに使用

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<TranslationRecord> records) {
    setState(() {
      if (_selectedIds.length == records.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(records.map((r) => _recordId(r)));
      }
    });
  }

  String _recordId(TranslationRecord r) => r.timestamp.toIso8601String();

  Future<void> _deleteSelected(BuildContext ctx) async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('履歴を削除'),
        content: Text(
          '選択した ${_selectedIds.length} 件の履歴を削除しますか？\nこの操作は元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !ctx.mounted) return;

    final provider = ctx.read<AppProvider>();
    // 選択されたIDに対応するインデックスを収集して削除
    await provider.deleteHistoryByIds(_selectedIds.toList());

    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('削除しました'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // タブバー + 選択モードアクションバー
            Container(
              color: AppTheme.surface,
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textHint,
                    indicatorColor: AppTheme.primary,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇯🇵'),
                            const SizedBox(width: 4),
                            Text('日→中 (${provider.jaHistory.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇨🇳'),
                            const SizedBox(width: 4),
                            Text('中→日 (${provider.zhHistory.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 選択モードバー
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _selectionMode ? 48 : 0,
                    child: _selectionMode
                        ? _buildSelectionBar(context, provider)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryList(provider.jaHistory, provider),
                  _buildHistoryList(provider.zhHistory, provider),
                ],
              ),
            ),
          ],
        ),
      ),
      // フローティングアクションボタン（選択モード切替）
      floatingActionButton: provider.history.isNotEmpty
          ? FloatingActionButton.small(
              heroTag: 'history_select',
              onPressed: _toggleSelectionMode,
              backgroundColor: _selectionMode ? Colors.red : AppTheme.primary,
              foregroundColor: Colors.white,
              tooltip: _selectionMode ? '選択解除' : '選択して削除',
              child: Icon(_selectionMode ? Icons.close : Icons.checklist),
            )
          : null,
    );
  }

  Widget _buildSelectionBar(BuildContext ctx, AppProvider provider) {
    // 現在表示中タブのリスト
    final currentList = _tabController.index == 0
        ? provider.jaHistory
        : provider.zhHistory;
    final allSelected = _selectedIds.length == currentList.length &&
        currentList.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // 全選択チェックボックス
          GestureDetector(
            onTap: () => _selectAll(currentList),
            child: Row(
              children: [
                Icon(
                  allSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  allSelected ? '全解除' : '全選択',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_selectedIds.length}件選択中',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const Spacer(),
          // 削除ボタン
          TextButton.icon(
            onPressed:
                _selectedIds.isNotEmpty ? () => _deleteSelected(ctx) : null,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('削除'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              disabledForegroundColor: Colors.red.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
      List<TranslationRecord> records, AppProvider provider) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                size: 64, color: AppTheme.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('履歴がありません',
                style: TextStyle(color: AppTheme.textHint, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 72),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(records[index], provider);
      },
    );
  }

  Widget _buildHistoryCard(TranslationRecord record, AppProvider provider) {
    final isJa = record.inputLang == 'ja';
    final dateStr = _formatDate(record.timestamp);
    final id = _recordId(record);
    final isSelected = _selectedIds.contains(id);

    return GestureDetector(
      onTap: () {
        if (_selectionMode) {
          _toggleItem(id);
        } else {
          _showDetailDialog(context, record);
        }
      },
      onLongPress: () {
        if (!_selectionMode) {
          setState(() {
            _selectionMode = true;
            _selectedIds.add(id);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 選択チェックボックス（選択モード時のみ）
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 2),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppTheme.primary : AppTheme.textHint,
                  size: 22,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー行
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isJa
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isJa ? '日→中' : '中→日',
                          style: TextStyle(
                            fontSize: 11,
                            color: isJa ? AppTheme.primary : AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HSK ${record.hskLevel}',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textHint),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${record.age}歳 ${record.gender == 'male' ? '♂' : '♀'}',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textHint),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 入力テキスト
                  Text(
                    record.inputText,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_downward,
                            size: 14, color: AppTheme.textHint),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 翻訳結果
                  Row(
                    children: [
                      Expanded(
                        child: isJa
                            ? PinyinTextWidget(
                                chineseText: record.outputText,
                                pinyinText: record.pinyin,
                                fontSize: 18,
                              )
                            : Text(
                                record.outputText,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (!_selectionMode)
                        IconButton(
                          icon: const Icon(Icons.volume_up, size: 18),
                          color: AppTheme.primary,
                          onPressed: () {
                            final chinese =
                                isJa ? record.outputText : record.inputText;
                            TtsService.speakChinese(chinese);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, TranslationRecord record) {
    final isJa = record.inputLang == 'ja';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(record.timestamp),
                        style:
                            TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    const SizedBox(height: 12),
                    _detailSection('元のテキスト', record.inputText, null),
                    const SizedBox(height: 12),
                    _detailSection(
                      isJa ? '中国語訳（拼音付き）' : '日本語訳',
                      record.outputText,
                      isJa ? record.pinyin : null,
                    ),
                    const SizedBox(height: 12),
                    _detailSection(
                      isJa ? '逆翻訳（中→日）' : '逆翻訳（日→中）',
                      record.backTranslation,
                      null,
                    ),
                    const SizedBox(height: 12),
                    _detailSection('英語訳', record.englishTranslation, null),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String title, String content, String? pinyin) {
    final isChinese = pinyin != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textHint,
                  )),
              if (isChinese)
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 18),
                  color: AppTheme.primary,
                  onPressed: () => TtsService.speakChinese(content),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isChinese && pinyin.isNotEmpty)
            PinyinTextWidget(
              chineseText: content,
              pinyinText: pinyin,
              fontSize: 20,
            )
          else
            Text(
              content.isEmpty ? '—' : content,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
