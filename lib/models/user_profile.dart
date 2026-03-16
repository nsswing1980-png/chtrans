// lib/models/user_profile.dart
/// アカウント種別
enum AuthProvider { google, apple, email, guest }

extension AuthProviderLabel on AuthProvider {
  String get label {
    switch (this) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.email:
        return 'メール';
      case AuthProvider.guest:
        return 'ゲスト';
    }
  }

  String get iconAsset {
    switch (this) {
      case AuthProvider.google:
        return 'assets/icons/ic_google.png';
      case AuthProvider.apple:
        return 'assets/icons/ic_apple.png';
      case AuthProvider.email:
        return '';
      case AuthProvider.guest:
        return '';
    }
  }
}

/// ログイン中ユーザー情報
class UserProfile {
  final String uid;        // プロバイダー種別 + "_" + プロバイダーUID
  final String displayName;
  final String? email;
  final String? photoUrl;
  final AuthProvider provider;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.provider,
  });

  /// Hive ユーザー別 Box 名に使うキー（"@" など特殊文字除去）
  String get storageKey => uid.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'provider': provider.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // 旧データ互換: line/wechat → guest にフォールバック
    AuthProvider prov;
    try {
      prov = AuthProvider.values.firstWhere(
        (e) => e.name == json['provider'],
      );
    } catch (_) {
      prov = AuthProvider.guest;
    }
    return UserProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      provider: prov,
    );
  }

  /// ゲストユーザー
  static const UserProfile guest = UserProfile(
    uid: 'guest_local',
    displayName: 'ゲスト',
    provider: AuthProvider.guest,
  );
}
