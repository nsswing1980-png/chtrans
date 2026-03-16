// lib/screens/login_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isProcessing = false;

  Future<void> _handleLogin(
    BuildContext ctx,
    Future<UserProfile?> Function() loginFn,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final profile = await loginFn();
      if (profile != null && ctx.mounted) {
        // AppProviderにユーザーをセット→ストレージ切り替え→メイン画面へ
        await ctx.read<AppProvider>().onLogin(profile);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('ログインエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // アプリロゴ
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '中',
                      style: TextStyle(
                        fontSize: 46,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Language Tutor',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '中国語・日本語 翻訳学習',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'アカウントでログイン',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Google ボタン
                _SocialLoginButton(
                  label: 'Googleでログイン',
                  icon: Icons.g_mobiledata,
                  iconColor: const Color(0xFF4285F4),
                  borderColor: const Color(0xFF4285F4),
                  onPressed: (auth.isLoading || _isProcessing)
                      ? null
                      : () => _handleLogin(
                            context,
                            () => AuthService().signInWithGoogle(),
                          ),
                ),
                const SizedBox(height: 10),
                // Apple ボタン（iOS/macOS/Web のみ表示）
                if (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS ||
                    kIsWeb)
                  _SocialLoginButton(
                    label: 'Appleでログイン',
                    icon: Icons.apple,
                    iconColor: Colors.black87,
                    borderColor: Colors.black54,
                    onPressed: (auth.isLoading || _isProcessing)
                        ? null
                        : () => _handleLogin(
                              context,
                              () => AuthService().signInWithApple(),
                            ),
                  ),
                if (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS ||
                    kIsWeb)
                  const SizedBox(height: 10),
                // LINE ボタン
                _SocialLoginButton(
                  label: 'LINEでログイン',
                  icon: Icons.chat_bubble,
                  iconColor: const Color(0xFF06C755),
                  borderColor: const Color(0xFF06C755),
                  onPressed: (auth.isLoading || _isProcessing)
                      ? null
                      : () => _handleLogin(
                            context,
                            () => AuthService().signInWithLine(),
                          ),
                ),
                const SizedBox(height: 10),
                // WeChat ボタン
                _SocialLoginButton(
                  label: 'WeChatでログイン',
                  icon: Icons.wechat,
                  iconColor: const Color(0xFF07C160),
                  borderColor: const Color(0xFF07C160),
                  onPressed: (auth.isLoading || _isProcessing)
                      ? null
                      : () => _handleLogin(
                            context,
                            () => AuthService().signInWithWeChat(),
                          ),
                ),
                const SizedBox(height: 28),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('または'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                // ゲストモード
                OutlinedButton(
                  onPressed: (auth.isLoading || _isProcessing)
                      ? null
                      : () => _handleLogin(
                            context,
                            () async => AuthService().continueAsGuest(),
                          ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('ゲストとして続ける（データはこの端末のみ保存）'),
                ),
                const SizedBox(height: 24),
                // ローディングインジケーター
                if (auth.isLoading || _isProcessing)
                  const CircularProgressIndicator(),
                const SizedBox(height: 16),
                // 保存済みアカウント一覧
                _SavedAccountsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== ソーシャルログインボタン ==========
class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor, size: 22),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: borderColor, width: 1.5),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ========== 保存済みアカウント ==========
class _SavedAccountsList extends StatefulWidget {
  @override
  State<_SavedAccountsList> createState() => _SavedAccountsListState();
}

class _SavedAccountsListState extends State<_SavedAccountsList> {
  List<UserProfile> _accounts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await AuthService().getSavedAccounts();
    if (mounted) {
      setState(() => _accounts = accounts.where((a) => a.uid != 'guest_local').toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '以前使用したアカウント',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._accounts.map((account) => _buildAccountTile(context, account)),
      ],
    );
  }

  Widget _buildAccountTile(BuildContext context, UserProfile account) {
    final providerColor = _providerColor(account.provider);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: providerColor.withValues(alpha: 0.15),
          child: Icon(
            _providerIcon(account.provider),
            color: providerColor,
            size: 20,
          ),
        ),
        title: Text(
          account.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${account.provider.label}${account.email != null ? " · ${account.email}" : ""}',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () async {
          await context.read<AppProvider>().onLogin(account);
        },
      ),
    );
  }

  Color _providerColor(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return const Color(0xFF4285F4);
      case AuthProvider.apple:
        return Colors.black87;
      case AuthProvider.line:
        return const Color(0xFF06C755);
      case AuthProvider.wechat:
        return const Color(0xFF07C160);
      case AuthProvider.guest:
        return AppTheme.primary;
    }
  }

  IconData _providerIcon(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return Icons.g_mobiledata;
      case AuthProvider.apple:
        return Icons.apple;
      case AuthProvider.line:
        return Icons.chat_bubble;
      case AuthProvider.wechat:
        return Icons.wechat;
      case AuthProvider.guest:
        return Icons.person;
    }
  }
}
