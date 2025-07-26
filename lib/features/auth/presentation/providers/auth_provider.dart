import 'package:flutter/foundation.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecase.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/app_logger.dart';

/// 認証状態プロバイダー
/// 
/// Clean Architectureのプレゼンテーション層
class AuthProvider extends ChangeNotifier {
  final AuthUseCase _authUseCase;

  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authUseCase) {
    // 認証状態の変化を監視
    _authUseCase.authStateChanges.listen(
      (user) {
        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        AppLogger.auth('authStateChanges', error: error);
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// 現在のユーザー
  UserEntity? get currentUser => _currentUser;

  /// ローディング状態
  bool get isLoading => _isLoading;

  /// エラーメッセージ
  String? get errorMessage => _errorMessage;

  /// ログイン状態
  bool get isLoggedIn => _authUseCase.isLoggedIn;

  /// エラークリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ログイン処理
  /// 
  /// [email] メールアドレス
  /// [password] パスワード
  /// 戻り値: 成功時はtrue、失敗時はfalse
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authUseCase.signIn(
        email: email,
        password: password,
      );

      _currentUser = user;
      AppLogger.auth('signIn', userId: user.id);
      return true;

    } on AuthException catch (e) {
      _setError(e.message);
      AppLogger.auth('signIn', error: e);
      return false;

    } catch (e) {
      _setError('ログインに失敗しました');
      AppLogger.auth('signIn', error: e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// アカウント作成処理
  /// 
  /// [email] メールアドレス
  /// [password] パスワード
  /// [displayName] 表示名（オプション）
  /// 戻り値: 成功時はtrue、失敗時はfalse
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authUseCase.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      _currentUser = user;
      AppLogger.auth('signUp', userId: user.id);
      return true;

    } on AuthException catch (e) {
      _setError(e.message);
      AppLogger.auth('signUp', error: e);
      return false;

    } catch (e) {
      _setError('アカウント作成に失敗しました');
      AppLogger.auth('signUp', error: e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// サインアウト処理
  /// 
  /// 戻り値: 成功時はtrue、失敗時はfalse
  Future<bool> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authUseCase.signOut();
      _currentUser = null;
      AppLogger.auth('signOut');
      return true;

    } on AuthException catch (e) {
      _setError(e.message);
      AppLogger.auth('signOut', error: e);
      return false;

    } catch (e) {
      _setError('ログアウトに失敗しました');
      AppLogger.auth('signOut', error: e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// パスワードリセット処理
  /// 
  /// [email] メールアドレス
  /// 戻り値: 成功時はtrue、失敗時はfalse
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authUseCase.resetPassword(email);
      AppLogger.auth('resetPassword');
      return true;

    } on AuthException catch (e) {
      _setError(e.message);
      AppLogger.auth('resetPassword', error: e);
      return false;

    } catch (e) {
      _setError('パスワードリセットに失敗しました');
      AppLogger.auth('resetPassword', error: e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// メール確認メール送信
  /// 
  /// 戻り値: 成功時はtrue、失敗時はfalse
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _clearError();

    try {
      await _authUseCase.sendEmailVerification();
      AppLogger.auth('sendEmailVerification');
      return true;

    } on AuthException catch (e) {
      _setError(e.message);
      AppLogger.auth('sendEmailVerification', error: e);
      return false;

    } catch (e) {
      _setError('確認メールの送信に失敗しました');
      AppLogger.auth('sendEmailVerification', error: e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// プロフィール更新
  /// 
  /// [displayName] 表示名
  /// [photoUrl] プロフィール画像URL
  /// 戻り値: 成功時はtrue、失敗時はfalse
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authUseCase.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      // 更新後の情報を反映（現在のユーザーを更新）
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          displayName: displayName ?? _currentUser!.displayName,
          photoUrl: photoUrl ?? _currentUser!.photoUrl,
        );
      }

      AppLogger.auth('updateProfile');
      return true;

    } on AuthException catch (e) {
      _setError(e.message);
      AppLogger.auth('updateProfile', error: e);
      return false;

    } catch (e) {
      _setError('プロフィール更新に失敗しました');
      AppLogger.auth('updateProfile', error: e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// アカウント削除
  /// 
  /// 戻り値: 成功時はtrue、失敗時はfalse
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _authUseCase.deleteAccount();
      _currentUser = null;
      AppLogger.auth('deleteAccount');
      return true;

    } on AuthException catch (e) {
      _setError(e.message);
      AppLogger.auth('deleteAccount', error: e);
      return false;

    } catch (e) {
      _setError('アカウント削除に失敗しました');
      AppLogger.auth('deleteAccount', error: e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// ローディング状態の設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// エラー設定
  void _setError(String error) {
    _errorMessage = error;
  }

  /// エラークリア
  void _clearError() {
    _errorMessage = null;
  }

  /// 現在のユーザーを設定（Firebase Authからの直接設定用）
  void setCurrentUser(dynamic firebaseUser) {
    if (firebaseUser != null) {
      _currentUser = UserEntity(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
        isEmailVerified: firebaseUser.emailVerified,
        createdAt: firebaseUser.metadata?.creationTime ?? DateTime.now(),
      );
      notifyListeners();
    }
  }
}