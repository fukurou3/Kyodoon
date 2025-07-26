import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecase.dart';
import '../../features/auth/presentation/providers/auth_provider.dart' as auth;

import '../../features/posts/data/repositories/posts_repository_impl.dart';
import '../../features/posts/domain/repositories/posts_repository.dart';
import '../../features/posts/domain/usecases/posts_usecase.dart';
import '../../features/posts/presentation/providers/posts_provider.dart';

import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecase.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

import '../services/external/secure_notification_service.dart';

/// 依存性注入コンテナ
/// 
/// Clean Architectureの依存性を管理
class InjectionContainer {
  static InjectionContainer? _instance;
  static InjectionContainer get instance => _instance ??= InjectionContainer._();

  InjectionContainer._();

  // 依存性のマップ
  final Map<Type, Object> _dependencies = {};

  /// 依存性の初期化
  void initialize() {
    // External
    _dependencies[FirebaseAuth] = FirebaseAuth.instance;
    _dependencies[FirebaseFirestore] = FirebaseFirestore.instance;
    _dependencies[FirebaseStorage] = FirebaseStorage.instance;
    _dependencies[SecureNotificationService] = SecureNotificationService(
      firestore: get<FirebaseFirestore>(),
      auth: get<FirebaseAuth>(),
    );

    // Auth feature
    _dependencies[AuthRepository] = AuthRepositoryImpl(
      firebaseAuth: get<FirebaseAuth>(),
      firestore: get<FirebaseFirestore>(),
    );
    _dependencies[AuthUseCase] = AuthUseCase(
      get<AuthRepository>(),
    );
    _dependencies[auth.AuthProvider] = auth.AuthProvider(
      get<AuthUseCase>(),
    );

    // Posts feature
    _dependencies[PostsRepository] = PostsRepositoryImpl(
      firestore: get<FirebaseFirestore>(),
      firebaseAuth: get<FirebaseAuth>(),
      notificationService: get<SecureNotificationService>(),
    );
    _dependencies[PostsUseCase] = PostsUseCase(
      get<PostsRepository>(),
    );
    _dependencies[PostsProvider] = PostsProvider(
      get<PostsUseCase>(),
    );
    _dependencies[PostDetailProvider] = PostDetailProvider(
      get<PostsUseCase>(),
    );

    // Profile feature
    _dependencies[ProfileRepository] = ProfileRepositoryImpl(
      firestore: get<FirebaseFirestore>(),
      firebaseAuth: get<FirebaseAuth>(),
      storage: get<FirebaseStorage>(),
    );
    _dependencies[ProfileUseCase] = ProfileUseCase(
      get<ProfileRepository>(),
    );
    _dependencies[ProfileProvider] = ProfileProvider(
      get<ProfileUseCase>(),
    );
  }

  /// 依存性の取得
  T get<T>() {
    final dependency = _dependencies[T];
    if (dependency == null) {
      throw Exception('Dependency of type $T is not registered');
    }
    return dependency as T;
  }

  /// 依存性の登録
  void register<T>(T dependency) {
    _dependencies[T] = dependency as Object;
  }

  /// 依存性の削除
  void unregister<T>() {
    _dependencies.remove(T);
  }

  /// すべての依存性をクリア
  void clear() {
    _dependencies.clear();
  }

  /// 依存性が登録されているかチェック
  bool isRegistered<T>() {
    return _dependencies.containsKey(T);
  }
}