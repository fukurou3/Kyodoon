import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/domain/usecases/auth_usecase.dart';

/// 認証状態の定義
enum AuthStateType {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// 認証状態クラス
class AuthState {
  final AuthStateType type;
  final UserEntity? user;
  final String? errorMessage;
  final Object? error;

  const AuthState._({
    required this.type,
    this.user,
    this.errorMessage,
    this.error,
  });

  const AuthState.initial() : this._(type: AuthStateType.initial);
  const AuthState.loading() : this._(type: AuthStateType.loading);
  const AuthState.authenticated(UserEntity user) : this._(type: AuthStateType.authenticated, user: user);
  const AuthState.unauthenticated() : this._(type: AuthStateType.unauthenticated);
  const AuthState.error(String message, [Object? error]) : this._(type: AuthStateType.error, errorMessage: message, error: error);

  /// When pattern matching helper
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(UserEntity user) authenticated,
    required T Function() unauthenticated,
    required T Function(String message, Object? error) error,
  }) {
    switch (type) {
      case AuthStateType.initial:
        return initial();
      case AuthStateType.loading:
        return loading();
      case AuthStateType.authenticated:
        return authenticated(user!);
      case AuthStateType.unauthenticated:
        return unauthenticated();
      case AuthStateType.error:
        return error(errorMessage!, this.error);
    }
  }

  /// MaybeWhen pattern matching helper
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(UserEntity user)? authenticated,
    T Function()? unauthenticated,
    T Function(String message, Object? error)? error,
    required T Function() orElse,
  }) {
    switch (type) {
      case AuthStateType.initial:
        return initial?.call() ?? orElse();
      case AuthStateType.loading:
        return loading?.call() ?? orElse();
      case AuthStateType.authenticated:
        return authenticated?.call(user!) ?? orElse();
      case AuthStateType.unauthenticated:
        return unauthenticated?.call() ?? orElse();
      case AuthStateType.error:
        return error?.call(errorMessage!, this.error) ?? orElse();
    }
  }
}

/// 認証状態管理の中心となるNotifier
/// 
/// 単一責任原則：認証状態の管理のみを担当
/// - Firebase User → UserEntity変換
/// - 認証状態の監視とキャッシュ
/// - エラーハンドリング
/// - パフォーマンス最適化
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthUseCase _authUseCase;
  final FirebaseAuth _firebaseAuth;
  
  /// キャッシュされたUserEntity（パフォーマンス最適化）
  UserEntity? _cachedUser;
  
  /// Firebase認証状態の監視
  late final StreamSubscription<User?> _authStateSubscription;
  
  AuthStateNotifier({
    required AuthUseCase authUseCase,
    required FirebaseAuth firebaseAuth,
  }) : _authUseCase = authUseCase,
       _firebaseAuth = firebaseAuth,
       super(const AuthState.initial()) {
    
    _initializeAuthState();
  }

  /// 認証状態の初期化と監視開始
  void _initializeAuthState() {
    state = const AuthState.loading();
    
    // Firebase Auth状態変更の監視
    _authStateSubscription = _firebaseAuth.authStateChanges().listen(
      _handleAuthStateChange,
      onError: (error) {
        state = AuthState.error(
          '認証状態の監視でエラーが発生しました',
          error,
        );
      },
    );
  }

  /// Firebase認証状態変更のハンドリング
  Future<void> _handleAuthStateChange(User? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        // ログアウト状態
        _cachedUser = null;
        state = const AuthState.unauthenticated();
        return;
      }

      // Firebase User → UserEntity変換
      final userEntity = await _convertFirebaseUserToUserEntity(firebaseUser);
      
      if (userEntity != null) {
        _cachedUser = userEntity;
        state = AuthState.authenticated(userEntity);
      } else {
        // 変換に失敗した場合
        state = const AuthState.error('ユーザー情報の取得に失敗しました');
      }
    } catch (error) {
      state = AuthState.error(
        'ユーザー情報の処理中にエラーが発生しました',
        error,
      );
    }
  }

  /// Firebase User → UserEntity変換
  /// 
  /// パフォーマンス最適化：キャッシュを使用して重複変換を避ける
  Future<UserEntity?> _convertFirebaseUserToUserEntity(User firebaseUser) async {
    try {
      // キャッシュチェック（UIDが同じ場合は再利用）
      if (_cachedUser?.id == firebaseUser.uid) {
        return _cachedUser;
      }

      // UseCase経由でUserEntityを取得
      final userEntity = await _authUseCase.getCurrentUserEntity();
      
      if (userEntity != null) {
        return userEntity;
      }

      // Firestoreにユーザー情報が無い場合、Firebase Userから作成
      return UserEntity(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        isEmailVerified: firebaseUser.emailVerified,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: firebaseUser.metadata.lastSignInTime,
      );
    } catch (error) {
      // ログ記録（本番環境では適切なログサービスを使用）
      // TODO: Replace with proper logging service in production
      // AppLogger.error('UserEntity変換エラー', error: error);
      return null;
    }
  }

  /// ログイン処理
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (state == const AuthState.loading()) return;
    
    state = const AuthState.loading();
    
    try {
      await _authUseCase.signIn(email: email, password: password);
      // 状態変更はauthStateChangesで自動的に処理される
    } catch (error) {
      state = AuthState.error(
        'ログインに失敗しました',
        error,
      );
    }
  }

  /// サインアップ処理
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (state == const AuthState.loading()) return;
    
    state = const AuthState.loading();
    
    try {
      await _authUseCase.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      // 状態変更はauthStateChangesで自動的に処理される
    } catch (error) {
      state = AuthState.error(
        'アカウント作成に失敗しました',
        error,
      );
    }
  }

  /// ログアウト処理
  Future<void> signOut() async {
    try {
      await _authUseCase.signOut();
      // 状態変更はauthStateChangesで自動的に処理される
    } catch (error) {
      state = AuthState.error(
        'ログアウトに失敗しました',
        error,
      );
    }
  }

  /// パスワードリセット
  Future<void> resetPassword(String email) async {
    try {
      await _authUseCase.resetPassword(email);
    } catch (error) {
      state = AuthState.error(
        'パスワードリセットに失敗しました',
        error,
      );
    }
  }

  /// プロフィール更新
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await _authUseCase.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      
      // プロフィール更新後、状態を強制的に更新
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _handleAuthStateChange(currentUser);
      }
    } catch (error) {
      state = AuthState.error(
        'プロフィール更新に失敗しました',
        error,
      );
    }
  }

  /// メール確認送信
  Future<void> sendEmailVerification() async {
    try {
      await _authUseCase.sendEmailVerification();
    } catch (error) {
      state = AuthState.error(
        'メール確認の送信に失敗しました',
        error,
      );
    }
  }

  /// エラー状態をクリア
  void clearError() {
    if (state.type == AuthStateType.error) {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null && _cachedUser != null) {
        state = AuthState.authenticated(_cachedUser!);
      } else {
        state = const AuthState.unauthenticated();
      }
    }
  }

  /// 認証状態を強制的に更新
  Future<void> refreshAuthState() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      await _handleAuthStateChange(_firebaseAuth.currentUser);
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}

/// 便利なゲッター拡張
extension AuthStateX on AuthState {
  /// 認証済みユーザーを取得
  UserEntity? get user => maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );

  /// 認証済みかどうか
  bool get isAuthenticated => maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );

  /// ローディング中かどうか
  bool get isLoading => maybeWhen(
    loading: () => true,
    orElse: () => false,
  );

  /// エラー状態かどうか
  bool get hasError => maybeWhen(
    error: (_, __) => true,
    orElse: () => false,
  );

  /// エラーメッセージを取得
  String? get errorMessage => maybeWhen(
    error: (message, _) => message,
    orElse: () => null,
  );
}