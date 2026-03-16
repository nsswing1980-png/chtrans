// lib/models/user_profile.dart
/// アカウント種別
enum AuthProvider { google, apple, line, wechat, guest }

extension AuthProviderLabel on AuthProvider {
  String get label {
    switch (this) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.line:
        return 'LINE';
      case AuthProvider.wechat:
        return 'WeChat';
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
      case AuthProvider.line:
        return 'assets/icons/ic_line.png';
      case AuthProvider.wechat:
        return 'assets/icons/ic_wechat.png';
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

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String,
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        provider: AuthProvider.values.firstWhere(
          (e) => e.name == json['provider'],
          orElse: () => AuthProvider.guest,
        ),
      );

  /// ゲストユーザー
  static const UserProfile guest = UserProfile(
    uid: 'guest_local',
    displayName: 'ゲスト',
    provider: AuthProvider.guest,
  );
}
