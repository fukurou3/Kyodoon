import '../entities/user_entity.dart';

/// 認証リポジトリインターフェース
/// 
/// 認証に関するデータ操作の抽象化
abstract class AuthRepository {
  /// 認証状態の変化を監視するストリーム
  Stream<UserEntity?> get authStateChanges;

  /// 現在のユーザーを取得
  UserEntity? get currentUser;

  /// 現在のユーザーエンティティを非同期で取得（Firestore連携込み）
  Future<UserEntity?> getCurrentUserEntity();

  /// ログイン状態の確認
  bool get isLoggedIn;

  /// メールアドレスとパスワードでサインイン
  /// 
  /// [email] メールアドレス
  /// [password] パスワード
  /// 戻り値: 成功時はUserEntity、失敗時はnull
  Future<UserEntity?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// メールアドレスとパスワードでアカウント作成
  /// 
  /// [email] メールアドレス
  /// [password] パスワード
  /// [displayName] 表示名（オプション）
  /// 戻り値: 成功時はUserEntity、失敗時はnull
  Future<UserEntity?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// サインアウト
  Future<void> signOut();

  /// パスワードリセットメール送信
  /// 
  /// [email] メールアドレス
  Future<void> sendPasswordResetEmail(String email);

  /// メール確認メール送信
  Future<void> sendEmailVerification();

  /// プロフィール更新
  /// 
  /// [displayName] 表示名
  /// [photoUrl] プロフィール画像URL
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// アカウント削除
  Future<void> deleteAccount();
}