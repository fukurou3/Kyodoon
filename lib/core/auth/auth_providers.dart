import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/domain/usecases/auth_usecase.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import 'auth_state_notifier.dart';

/// Firebase Auth Provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.read(firebaseAuthProvider),
  );
});

/// Auth UseCase Provider
final authUseCaseProvider = Provider<AuthUseCase>((ref) {
  return AuthUseCase(ref.read(authRepositoryProvider));
});

/// 中心となる認証状態Provider
/// 
/// AuthStateNotifierを使用して認証状態を一元管理
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(
    authUseCase: ref.read(authUseCaseProvider),
    firebaseAuth: ref.read(firebaseAuthProvider),
  );
});

/// 認証済みユーザー取得
final authenticatedUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

/// ログイン状態
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

/// 認証ローディング状態
final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});

/// 認証エラー状態
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.errorMessage;
});

/// 認証操作Provider
/// 
/// AuthStateNotifier経由で認証操作を実行
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.read(authStateProvider.notifier));
});

/// 認証操作クラス
class AuthActions {
  final AuthStateNotifier _authStateNotifier;
  
  AuthActions(this._authStateNotifier);
  
  /// ログイン
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authStateNotifier.signIn(
      email: email,
      password: password,
    );
  }
  
  /// サインアップ
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _authStateNotifier.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
  
  /// ログアウト
  Future<void> signOut() async {
    await _authStateNotifier.signOut();
  }
  
  /// パスワードリセット
  Future<void> resetPassword(String email) async {
    await _authStateNotifier.resetPassword(email);
  }
  
  /// メール確認送信
  Future<void> sendEmailVerification() async {
    await _authStateNotifier.sendEmailVerification();
  }
  
  /// プロフィール更新
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    await _authStateNotifier.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
  
  /// エラークリア
  void clearError() {
    _authStateNotifier.clearError();
  }
  
  /// 認証状態を強制更新
  Future<void> refreshAuthState() async {
    await _authStateNotifier.refreshAuthState();
  }
}