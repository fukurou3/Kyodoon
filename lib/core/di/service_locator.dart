import 'package:get_it/get_it.dart';
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

/// GetItベースのサービスロケーター
/// 
/// 依存性注入を管理し、Clean Architectureの原則に従う
final GetIt sl = GetIt.instance;

/// 依存性の初期化
/// 
/// GetItコンテナに全ての依存性を登録する
/// 二重初期化を防ぐため、AppInitializer経由でのみ呼び出すこと
Future<void> setupServiceLocator() async {
  // 二重初期化チェック
  if (sl.isRegistered<FirebaseAuth>()) {
    return; // 既に初期化済み
  }
  // External Dependencies
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  
  sl.registerLazySingleton<SecureNotificationService>(
    () => SecureNotificationService(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // Auth Feature
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  
  sl.registerLazySingleton<AuthUseCase>(
    () => AuthUseCase(sl<AuthRepository>()),
  );
  
  sl.registerFactory<auth.AuthProvider>(
    () => auth.AuthProvider(sl<AuthUseCase>()),
  );

  // Posts Feature
  sl.registerLazySingleton<PostsRepository>(
    () => PostsRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      notificationService: sl<SecureNotificationService>(),
    ),
  );
  
  sl.registerLazySingleton<PostsUseCase>(
    () => PostsUseCase(sl<PostsRepository>()),
  );
  
  sl.registerFactory<PostsProvider>(
    () => PostsProvider(sl<PostsUseCase>()),
  );
  
  sl.registerFactory<PostDetailProvider>(
    () => PostDetailProvider(sl<PostsUseCase>()),
  );

  // Profile Feature
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      storage: sl<FirebaseStorage>(),
    ),
  );
  
  sl.registerLazySingleton<ProfileUseCase>(
    () => ProfileUseCase(sl<ProfileRepository>()),
  );
  
  sl.registerFactory<ProfileProvider>(
    () => ProfileProvider(sl<ProfileUseCase>()),
  );
}