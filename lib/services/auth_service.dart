// lib/services/auth_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      final uid =
          'apple_${credential.userIdentifier ?? DateTime.now().millisecondsSinceEpoch}';
      final name = [credential.givenName, credential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      final profile = UserProfile(
        uid: uid,
        displayName:
            name.isNotEmpty ? name : (credential.email ?? 'Appleユーザー'),
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

  // ========== メール + パスワード認証（端末ローカル保存） ==========

  /// 新規登録
  Future<({bool success, String? error})> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final emailKey = _emailStorageKey(email);

      // 既存アカウント確認
      final existing = prefs.getString('email_account_$emailKey');
      if (existing != null) {
        _isLoading = false;
        notifyListeners();
        return (success: false, error: 'このメールアドレスは既に登録済みです');
      }

      // パスワードをハッシュ化して保存
      final hashedPw = _hashPassword(password);
      final accountData = jsonEncode({
        'email': email,
        'passwordHash': hashedPw,
        'displayName': displayName,
      });
      await prefs.setString('email_account_$emailKey', accountData);

      final uid = 'email_${emailKey}';
      final profile = UserProfile(
        uid: uid,
        displayName: displayName,
        email: email,
        provider: AuthProvider.email,
      );

      await _saveSession(profile);
      _currentUser = profile;
      _isLoading = false;
      notifyListeners();
      return (success: true, error: null);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return (success: false, error: '登録に失敗しました: $e');
    }
  }

  /// ログイン
  Future<({bool success, String? error})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final emailKey = _emailStorageKey(email);
      final accountJson = prefs.getString('email_account_$emailKey');

      if (accountJson == null) {
        _isLoading = false;
        notifyListeners();
        return (success: false, error: 'アカウントが見つかりません');
      }

      final accountData = jsonDecode(accountJson) as Map<String, dynamic>;
      final storedHash = accountData['passwordHash'] as String;
      final hashedPw = _hashPassword(password);

      if (storedHash != hashedPw) {
        _isLoading = false;
        notifyListeners();
        return (success: false, error: 'パスワードが正しくありません');
      }

      final profile = UserProfile(
        uid: 'email_$emailKey',
        displayName: accountData['displayName'] as String,
        email: email,
        provider: AuthProvider.email,
      );

      await _saveSession(profile);
      _currentUser = profile;
      _isLoading = false;
      notifyListeners();
      return (success: true, error: null);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return (success: false, error: 'ログインに失敗しました: $e');
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

  /// メールアドレスをストレージキー用に安全な文字列へ変換
  String _emailStorageKey(String email) =>
      email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  /// パスワードのSHA-256ハッシュ（ソルト付き）
  String _hashPassword(String password) {
    const salt = 'language_tutor_salt_2024';
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }
}
