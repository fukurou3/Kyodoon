import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/security_validator.dart';

/// 認証ユースケース
/// 
/// 認証に関するビジネスロジックを管理
class AuthUseCase {
  final AuthRepository _repository;

  AuthUseCase(this._repository);

  /// 認証状態の変化を監視
  Stream<UserEntity?> get authStateChanges => _repository.authStateChanges;

  /// 現在のユーザー
  UserEntity? get currentUser => _repository.currentUser;

  /// ログイン状態
  bool get isLoggedIn => _repository.isLoggedIn;

  /// ログイン処理
  /// 
  /// [email] メールアドレス
  /// [password] パスワード
  /// 戻り値: 成功時はUserEntity
  /// 例外: 失敗時はAuthExceptionをスロー
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    // 入力検証
    final emailValidation = SecurityValidator.validateEmail(email);
    if (!emailValidation.isValid) {
      throw AuthException(emailValidation.errorMessage!);
    }

    if (password.isEmpty) {
      throw AuthException('パスワードを入力してください');
    }

    if (password.length < 6) {
      throw AuthException('パスワードは6文字以上で入力してください');
    }

    // 認証実行
    final user = await _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (user == null) {
      throw AuthException('メールアドレスまたはパスワードが正しくありません');
    }

    return user;
  }

  /// アカウント作成処理
  /// 
  /// [email] メールアドレス
  /// [password] パスワード
  /// [displayName] 表示名（オプション）
  /// 戻り値: 成功時はUserEntity
  /// 例外: 失敗時はAuthExceptionをスロー
  Future<UserEntity> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    // 入力検証
    final emailValidation = SecurityValidator.validateEmail(email);
    if (!emailValidation.isValid) {
      throw AuthException(emailValidation.errorMessage!);
    }

    if (password.isEmpty) {
      throw AuthException('パスワードを入力してください');
    }

    if (password.length < 6) {
      throw AuthException('パスワードは6文字以上で入力してください');
    }

    // 表示名の検証（設定されている場合）
    if (displayName != null && displayName.isNotEmpty) {
      final nameValidation = SecurityValidator.validateUsername(displayName);
      if (!nameValidation.isValid) {
        throw AuthException(nameValidation.errorMessage!);
      }
    }

    // アカウント作成実行
    final user = await _repository.createUserWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );

    if (user == null) {
      throw AuthException('アカウントの作成に失敗しました');
    }

    return user;
  }

  /// サインアウト処理
  Future<void> signOut() async {
    await _repository.signOut();
  }

  /// パスワードリセット処理
  /// 
  /// [email] メールアドレス
  /// 例外: 失敗時はAuthExceptionをスロー
  Future<void> resetPassword(String email) async {
    // 入力検証
    final emailValidation = SecurityValidator.validateEmail(email);
    if (!emailValidation.isValid) {
      throw AuthException(emailValidation.errorMessage!);
    }

    await _repository.sendPasswordResetEmail(email);
  }

  /// メール確認メール送信
  /// 
  /// 例外: 失敗時はAuthExceptionをスロー
  Future<void> sendEmailVerification() async {
    if (!isLoggedIn) {
      throw AuthException('ログインが必要です');
    }

    await _repository.sendEmailVerification();
  }

  /// プロフィール更新
  /// 
  /// [displayName] 表示名
  /// [photoUrl] プロフィール画像URL
  /// 例外: 失敗時はAuthExceptionをスロー
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (!isLoggedIn) {
      throw AuthException('ログインが必要です');
    }

    // 表示名の検証（設定されている場合）
    if (displayName != null && displayName.isNotEmpty) {
      final nameValidation = SecurityValidator.validateUsername(displayName);
      if (!nameValidation.isValid) {
        throw AuthException(nameValidation.errorMessage!);
      }
    }

    await _repository.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  /// アカウント削除
  /// 
  /// 例外: 失敗時はAuthExceptionをスロー
  Future<void> deleteAccount() async {
    if (!isLoggedIn) {
      throw AuthException('ログインが必要です');
    }

    await _repository.deleteAccount();
  }
}