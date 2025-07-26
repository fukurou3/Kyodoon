import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/auth_usecase.dart';
import '../features/auth/domain/entities/user_entity.dart';

import '../features/posts/data/repositories/posts_repository_impl.dart';
import '../features/posts/domain/repositories/posts_repository.dart';
import '../features/posts/domain/usecases/posts_usecase.dart';
import '../features/posts/domain/entities/post_entity.dart';

import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/profile_usecase.dart';
import '../features/profile/domain/entities/profile_entity.dart';

import '../core/services/external/secure_notification_service.dart';
import '../themes/app_theme.dart';

// ========== External Dependencies ==========

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final secureNotificationServiceProvider = Provider<SecureNotificationService>((ref) {
  return SecureNotificationService(
    firestore: ref.read(firestoreProvider),
    auth: ref.read(firebaseAuthProvider),
  );
});

// ========== Auth Feature ==========

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.read(firebaseAuthProvider),
    firestore: ref.read(firestoreProvider),
  );
});

final authUseCaseProvider = Provider<AuthUseCase>((ref) {
  return AuthUseCase(ref.read(authRepositoryProvider));
});

// 認証状態の監視
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseAuthProvider).authStateChanges();
});

// 現在のユーザー情報（UserEntityとして取得）
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      
      // Firebase UserからUserEntityに変換
      final authUseCase = ref.read(authUseCaseProvider);
      return authUseCase.currentUser;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ログイン状態
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// 認証ローディング状態
final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});

// 認証エラー
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
});

// 認証操作
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.read(authUseCaseProvider));
});

/// 認証操作クラス
class AuthActions {
  final AuthUseCase _authUseCase;
  
  AuthActions(this._authUseCase);
  
  /// ログイン
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authUseCase.signIn(email: email, password: password);
    } catch (e) {
      // エラーを再スローして上位でハンドリング
      throw Exception('ログインに失敗しました: ${e.toString()}');
    }
  }
  
  /// サインアップ
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      await _authUseCase.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    } catch (e) {
      // エラーを再スローして上位でハンドリング
      throw Exception('アカウント作成に失敗しました: ${e.toString()}');
    }
  }
  
  /// ログアウト
  Future<void> signOut() async {
    await _authUseCase.signOut();
  }
  
  /// パスワードリセット
  Future<void> resetPassword(String email) async {
    await _authUseCase.resetPassword(email);
  }
  
  /// メール確認
  Future<void> sendEmailVerification() async {
    await _authUseCase.sendEmailVerification();
  }
  
  /// プロフィール更新
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    await _authUseCase.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}

// ========== Posts Feature ==========

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepositoryImpl(
    firestore: ref.read(firestoreProvider),
    firebaseAuth: ref.read(firebaseAuthProvider),
    notificationService: ref.read(secureNotificationServiceProvider),
  );
});

final postsUseCaseProvider = Provider<PostsUseCase>((ref) {
  return PostsUseCase(ref.read(postsRepositoryProvider));
});

// 投稿一覧の取得
final postsListProvider = StreamProvider<List<PostEntity>>((ref) {
  final postsUseCase = ref.read(postsUseCaseProvider);
  return postsUseCase.getPosts();
});

// カジュアル投稿一覧
final casualPostsProvider = StreamProvider<List<PostEntity>>((ref) {
  final postsUseCase = ref.read(postsUseCaseProvider);
  return postsUseCase.getPosts(type: PostType.casual);
});

// シリアス投稿一覧
final seriousPostsProvider = StreamProvider<List<PostEntity>>((ref) {
  final postsUseCase = ref.read(postsUseCaseProvider);
  return postsUseCase.getPosts(type: PostType.serious);
});

// 特定の投稿詳細
final postDetailProvider = FutureProvider.family<PostEntity?, String>((ref, postId) async {
  final postsUseCase = ref.read(postsUseCaseProvider);
  return await postsUseCase.getPost(postId);
});

// ========== Profile Feature ==========

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    firestore: ref.read(firestoreProvider),
    firebaseAuth: ref.read(firebaseAuthProvider),
    storage: ref.read(firebaseStorageProvider),
  );
});

final profileUseCaseProvider = Provider<ProfileUseCase>((ref) {
  return ProfileUseCase(ref.read(profileRepositoryProvider));
});

// 現在のユーザープロフィール
final currentProfileProvider = FutureProvider<ProfileEntity?>((ref) async {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  if (!isLoggedIn) return null;
  
  final profileUseCase = ref.read(profileUseCaseProvider);
  return await profileUseCase.getCurrentUserProfile();
});

// 特定ユーザーのプロフィール
final userProfileProvider = FutureProvider.family<ProfileEntity?, String>((ref, userId) async {
  final profileUseCase = ref.read(profileUseCaseProvider);
  return await profileUseCase.getProfile(userId);
});

// ========== Theme Management ==========

// テーマモードの状態管理
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.light);

  void toggleTheme() {
    state = state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
  }
}

// ========== Loading States ==========

// 各種ローディング状態の管理
final loadingStateProvider = StateNotifierProvider<LoadingStateNotifier, Map<String, bool>>((ref) {
  return LoadingStateNotifier();
});

class LoadingStateNotifier extends StateNotifier<Map<String, bool>> {
  LoadingStateNotifier() : super({});

  void setLoading(String key, bool isLoading) {
    state = {...state, key: isLoading};
  }

  bool isLoading(String key) {
    return state[key] ?? false;
  }
}

// ========== Error States ==========

// エラー状態の管理
final errorStateProvider = StateNotifierProvider<ErrorStateNotifier, Map<String, String?>>((ref) {
  return ErrorStateNotifier();
});

class ErrorStateNotifier extends StateNotifier<Map<String, String?>> {
  ErrorStateNotifier() : super({});

  void setError(String key, String? error) {
    state = {...state, key: error};
  }

  String? getError(String key) {
    return state[key];
  }

  void clearError(String key) {
    state = {...state, key: null};
  }

  void clearAllErrors() {
    state = {};
  }
}