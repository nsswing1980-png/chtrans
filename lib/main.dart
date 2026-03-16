// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/tts_service.dart';
import 'screens/translate_screen.dart';
import 'screens/vocabulary_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/app_theme.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.initialize();
  await TtsService.initialize();
  runApp(const LanguageTutorApp());
}

class LanguageTutorApp extends StatelessWidget {
  const LanguageTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Language Tutor',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const _AppRoot(),
      ),
    );
  }
}

/// 認証状態に応じてログイン画面 or メイン画面を表示するルートウィジェット
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final provider = context.read<AppProvider>();
    await provider.initAuth();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // スプラッシュ
      return Scaffold(
        backgroundColor: AppTheme.primary,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '中',
                style: TextStyle(
                  fontSize: 72,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    final provider = context.watch<AppProvider>();
    if (!provider.isLoggedIn) {
      return const LoginScreen();
    }
    if (!provider.onboardingDone) {
      return const OnboardingScreen();
    }
    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TranslateScreen(),
    VocabularyScreen(),
    StatisticsScreen(),
    HistoryScreen(),
  ];

  final List<String> _titles = ['翻訳', '単語帳', '統計', '履歴'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<AppProvider>().loadVocabulary();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('単語帳を更新しました'), duration: Duration(seconds: 1)),
                );
              },
              tooltip: '更新',
            ),
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<AppProvider>().loadHistory(),
              tooltip: '更新',
            ),
          // ユーザーアカウントメニュー
          _buildAccountButton(context, user),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          final p = context.read<AppProvider>();
          if (index == 1) p.loadVocabulary();
          if (index == 2) p.loadVocabulary();
          if (index == 3) p.loadHistory();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            activeIcon: Icon(Icons.translate),
            label: '翻訳',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: '単語帳',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: '統計',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: '履歴',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountButton(BuildContext context, UserProfile? user) {
    if (user == null) return const SizedBox.shrink();

    Color providerColor;
    IconData providerIcon;
    switch (user.provider) {
      case AuthProvider.google:
        providerColor = const Color(0xFF4285F4);
        providerIcon = Icons.g_mobiledata;
        break;
      case AuthProvider.apple:
        providerColor = Colors.black87;
        providerIcon = Icons.apple;
        break;
      case AuthProvider.email:
        providerColor = const Color(0xFF4A9B8E);
        providerIcon = Icons.email_outlined;
        break;
      case AuthProvider.guest:
        providerColor = Colors.grey;
        providerIcon = Icons.person;
        break;
    }

    return PopupMenuButton<String>(
      tooltip: 'アカウント',
      offset: const Offset(0, 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: user.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoUrl!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(providerIcon, size: 16, color: Colors.white),
                      ),
                    )
                  : Icon(providerIcon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: providerColor.withValues(alpha: 0.15),
                    child: Icon(providerIcon, color: providerColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          user.provider.label,
                          style: TextStyle(fontSize: 11, color: providerColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'switch',
          child: const Row(
            children: [
              Icon(Icons.swap_horiz, size: 18, color: Colors.black54),
              SizedBox(width: 8),
              Text('アカウント切り替え'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: const Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('ログアウト', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('ログアウト'),
              content: const Text('ログアウトしますか？\nデータはこの端末に保存されています。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('ログアウト'),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await context.read<AppProvider>().logout();
          }
        } else if (value == 'switch') {
          // ログイン画面に移動
          if (context.mounted) {
            await context.read<AppProvider>().logout();
          }
        }
      },
    );
  }
}
