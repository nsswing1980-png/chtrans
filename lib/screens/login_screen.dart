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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;

  // メールフォーム用
  final _emailLoginKey = GlobalKey<FormState>();
  final _emailRegisterKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  bool _loginPasswordVisible = false;
  bool _regPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmCtrl.dispose();
    _regNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSocialLogin(
      BuildContext ctx, Future<UserProfile?> Function() loginFn) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final profile = await loginFn();
      if (profile != null && ctx.mounted) {
        await ctx.read<AppProvider>().onLogin(profile);
      } else if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('ログインがキャンセルされました'),
            duration: Duration(seconds: 2),
          ),
        );
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

  Future<void> _handleEmailLogin() async {
    if (!_emailLoginKey.currentState!.validate()) return;
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final result = await AuthService().signInWithEmail(
      email: _loginEmailCtrl.text.trim(),
      password: _loginPasswordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      final user = AuthService().currentUser;
      if (user != null && mounted) {
        await context.read<AppProvider>().onLogin(user);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'ログインに失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleEmailRegister() async {
    if (!_emailRegisterKey.currentState!.validate()) return;
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final result = await AuthService().registerWithEmail(
      email: _regEmailCtrl.text.trim(),
      password: _regPasswordCtrl.text,
      displayName: _regNameCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      final user = AuthService().currentUser;
      if (user != null && mounted) {
        await context.read<AppProvider>().onLogin(user);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? '登録に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // ── アプリロゴ ──
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('中',
                      style: TextStyle(
                          fontSize: 42,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Language Tutor',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text('中国語・日本語 翻訳学習',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 28),

              // ── ソーシャルログイン ──
              _SocialButton(
                label: 'Googleでログイン',
                icon: Icons.g_mobiledata,
                iconColor: const Color(0xFF4285F4),
                borderColor: const Color(0xFF4285F4),
                loading: auth.isLoading || _isProcessing,
                onPressed: () => _handleSocialLogin(
                    context, () => AuthService().signInWithGoogle()),
              ),
              const SizedBox(height: 10),
              if (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS ||
                  kIsWeb) ...[
                _SocialButton(
                  label: 'Appleでログイン',
                  icon: Icons.apple,
                  iconColor: Colors.black87,
                  borderColor: Colors.black54,
                  loading: auth.isLoading || _isProcessing,
                  onPressed: () => _handleSocialLogin(
                      context, () => AuthService().signInWithApple()),
                ),
                const SizedBox(height: 10),
              ],

              // ── OR 区切り ──
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('または',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 14),

              // ── メール認証タブ ──
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textHint,
                      indicatorColor: AppTheme.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'ログイン'),
                        Tab(text: '新規登録'),
                      ],
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 320,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLoginForm(),
                          _buildRegisterForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── ゲストモード ──
              OutlinedButton(
                onPressed: (auth.isLoading || _isProcessing)
                    ? null
                    : () => _handleSocialLogin(
                        context, () async => AuthService().continueAsGuest()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('ゲストとして続ける（データはこの端末のみ）',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ),

              if (auth.isLoading || _isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),

              const SizedBox(height: 16),
              _SavedAccountsList(),
            ],
          ),
        ),
      ),
    );
  }

  // ── ログインフォーム ──
  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Form(
        key: _emailLoginKey,
        child: Column(
          children: [
            TextFormField(
              controller: _loginEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                prefixIcon: Icon(Icons.email_outlined),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? '有効なメールアドレスを入力してください' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _loginPasswordCtrl,
              obscureText: !_loginPasswordVisible,
              decoration: InputDecoration(
                labelText: 'パスワード',
                prefixIcon: const Icon(Icons.lock_outline),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(_loginPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _loginPasswordVisible = !_loginPasswordVisible),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? '6文字以上で入力してください' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleEmailLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('ログイン',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 新規登録フォーム ──
  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Form(
        key: _emailRegisterKey,
        child: Column(
          children: [
            TextFormField(
              controller: _regNameCtrl,
              decoration: const InputDecoration(
                labelText: '表示名',
                prefixIcon: Icon(Icons.person_outline),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '表示名を入力してください' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                prefixIcon: Icon(Icons.email_outlined),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? '有効なメールアドレスを入力してください' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regPasswordCtrl,
              obscureText: !_regPasswordVisible,
              decoration: InputDecoration(
                labelText: 'パスワード（6文字以上）',
                prefixIcon: const Icon(Icons.lock_outline),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: IconButton(
                  icon: Icon(_regPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _regPasswordVisible = !_regPasswordVisible),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? '6文字以上で入力してください' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regConfirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'パスワード確認',
                prefixIcon: Icon(Icons.lock_outline),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (v) => v != _regPasswordCtrl.text ? 'パスワードが一致しません' : null,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleEmailRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('アカウント作成',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ソーシャルログインボタン ──
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: Icon(icon, color: iconColor, size: 22),
      label: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: borderColor, width: 1.5),
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── 保存済みアカウント一覧 ──
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
      setState(() =>
          _accounts = accounts.where((a) => a.uid != 'guest_local').toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accounts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('以前使用したアカウント',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        ..._accounts.map((a) => _AccountTile(account: a)),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});
  final UserProfile account;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _providerStyle(account.provider);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(account.displayName,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${account.provider.label}'
          '${account.email != null ? " · ${account.email}" : ""}',
          style:
              TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () async {
          await context.read<AppProvider>().onLogin(account);
        },
      ),
    );
  }

  (Color, IconData) _providerStyle(AuthProvider p) {
    switch (p) {
      case AuthProvider.google:
        return (const Color(0xFF4285F4), Icons.g_mobiledata);
      case AuthProvider.apple:
        return (Colors.black87, Icons.apple);
      case AuthProvider.email:
        return (AppTheme.primary, Icons.email_outlined);
      case AuthProvider.guest:
        return (Colors.grey, Icons.person);
    }
  }
}
