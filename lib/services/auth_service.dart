// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  // Google Sign-In 設定
  // Web プレビュー用：clientId は実際のプロジェクトでは Firebase Console から取得
  // 本実装では Web でも Google サインインを試みるが、
  // clientId 未設定環境ではゲストモードへフォールバックする
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ========== 初期化・セッション復元 ==========

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserProfile.fromJson(map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ========== Google サインイン ==========

  Future<UserProfile?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      GoogleSignInAccount? account;
      if (kIsWeb) {
        // Web: popup サインイン
        account = await _googleSignIn.signInSilently();
        account ??= await _googleSignIn.signIn();
      } else {
        account = await _googleSignIn.signIn();
      }

      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final profile = UserProfile(
        uid: 'google_${account.id}',
        displayName: account.displayName ?? account.email,
        email: account.email,
        photoUrl: account.photoUrl,
        provider: AuthProvider.google,
      );

      await _saveSession(profile);
      _currentUser = profile;
      _isLoading = false;
      notifyListeners();
      return profile;
    } catch (e) {
      if (kDebugMode) debugPrint('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ========== Apple サインイン ==========

  Future<UserProfile?> signInWithApple() async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final uid = 'apple_${credential.userIdentifier ?? DateTime.now().millisecondsSinceEpoch}';
      final name = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      final profile = UserProfile(
        uid: uid,
        displayName: name.isNotEmpty ? name : (credential.email ?? 'Appleユーザー'),
        email: credential.email,
        provider: AuthProvider.apple,
      );

      await _saveSession(profile);
      _currentUser = profile;
      _isLoading = false;
      notifyListeners();
      return profile;
    } catch (e) {
      if (kDebugMode) debugPrint('Apple Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ========== LINE サインイン (OAuth 2.0) ==========
  // LINE Login はブラウザ経由のため、簡易モックで「疑似ログイン」する。
  // 本番実装では LINE Login API のコールバックを処理する必要がある。

  Future<UserProfile?> signInWithLine() async {
    _isLoading = true;
    notifyListeners();

    try {
      // LINE Login URL を開く（実際の LINE チャネルIDが必要）
      // ここでは LINE OAuth 2.0 エンドポイントに誘導するデモフローを実装
      const lineClientId = 'YOUR_LINE_CHANNEL_ID'; // 本番では置き換え
      const redirectUri = 'https://language-tutor.app/line-callback';
      const state = 'random_state_string';
      final lineUrl = Uri.parse(
        'https://access.line.me/oauth2/v2.1/authorize'
        '?response_type=code'
        '&client_id=$lineClientId'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&state=$state'
        '&scope=profile%20openid%20email',
      );

      // このアプリではデモとして仮のLINEユーザーでログイン
      // （実際の OAuth フローはアプリ側でコールバック URI ハンドリングが必要）
      if (lineClientId == 'YOUR_LINE_CHANNEL_ID') {
        // デモ：疑似LINEユーザーを作成
        final profile = await _createDemoSocialUser(
          AuthProvider.line,
          '疑似LINEユーザー',
        );
        await _saveSession(profile);
        _currentUser = profile;
        _isLoading = false;
        notifyListeners();
        return profile;
      }

      // 本番実装：外部ブラウザでLINE OAuth を開く
      if (await canLaunchUrl(lineUrl)) {
        await launchUrl(lineUrl, mode: LaunchMode.externalApplication);
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('LINE Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ========== WeChat サインイン (OAuth 2.0) ==========

  Future<UserProfile?> signInWithWeChat() async {
    _isLoading = true;
    notifyListeners();

    try {
      const wechatAppId = 'YOUR_WECHAT_APP_ID'; // 本番では置き換え

      if (wechatAppId == 'YOUR_WECHAT_APP_ID') {
        // デモ：疑似WeChatユーザーを作成
        final profile = await _createDemoSocialUser(
          AuthProvider.wechat,
          '疑似WeChatユーザー',
        );
        await _saveSession(profile);
        _currentUser = profile;
        _isLoading = false;
        notifyListeners();
        return profile;
      }

      // 本番実装：WeChatアプリ or ブラウザでOAuthを開く
      final wechatUrl = Uri.parse(
        'https://open.weixin.qq.com/connect/qrconnect'
        '?appid=$wechatAppId'
        '&scope=snsapi_login'
        '&redirect_uri=${Uri.encodeComponent("https://language-tutor.app/wechat-callback")}'
        '&state=random_state'
        '#wechat_redirect',
      );

      if (await canLaunchUrl(wechatUrl)) {
        await launchUrl(wechatUrl, mode: LaunchMode.externalApplication);
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('WeChat Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ========== ゲストモード ==========

  Future<UserProfile> continueAsGuest() async {
    _currentUser = UserProfile.guest;
    await _saveSession(UserProfile.guest);
    notifyListeners();
    return UserProfile.guest;
  }

  // ========== サインアウト ==========

  Future<void> signOut() async {
    try {
      if (_currentUser?.provider == AuthProvider.google) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Sign out error: $e');
    }
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    notifyListeners();
  }

  // ========== ユーザー切り替え ==========

  Future<void> switchAccount(UserProfile profile) async {
    _currentUser = profile;
    await _saveSession(profile);
    notifyListeners();
  }

  // ========== 保存済みアカウント一覧 ==========

  Future<List<UserProfile>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('saved_accounts');
    if (accountsJson == null) return [];
    try {
      final list = jsonDecode(accountsJson) as List;
      return list
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ========== 内部ユーティリティ ==========

  Future<void> _saveSession(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(profile.toJson()));

    // アカウント一覧に追加（重複防止）
    final accounts = await getSavedAccounts();
    final existingIndex = accounts.indexWhere((a) => a.uid == profile.uid);
    if (existingIndex >= 0) {
      accounts[existingIndex] = profile;
    } else {
      accounts.add(profile);
    }
    await prefs.setString(
      'saved_accounts',
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  Future<UserProfile> _createDemoSocialUser(
      AuthProvider provider, String defaultName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return UserProfile(
      uid: '${provider.name}_demo_$timestamp',
      displayName: defaultName,
      provider: provider,
    );
  }
}
