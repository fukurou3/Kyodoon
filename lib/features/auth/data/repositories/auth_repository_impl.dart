import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/app_logger.dart';

/// 認証リポジトリの実装
/// 
/// Firebase Authと連携し、ドメインエンティティとの変換を行う
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _mapFirebaseUserToEntity(user);
    });
  }

  @override
  UserEntity? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    
    // 非同期でユーザーデータを取得できないため、基本情報のみ返す
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  @override
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  @override
  Future<UserEntity?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return await _mapFirebaseUserToEntity(userCredential.user!);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      AppLogger.auth('signIn', error: e);
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.auth('signIn', error: e);
      throw AuthException('ログインに失敗しました');
    }
  }

  @override
  Future<UserEntity?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // 表示名を設定
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
          await user.reload();
        }

        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'displayName': displayName ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        return await _mapFirebaseUserToEntity(user);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      AppLogger.auth('signUp', error: e);
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.auth('signUp', error: e);
      throw AuthException('アカウント作成に失敗しました');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      AppLogger.auth('signOut', error: e);
      if (e is AuthException) rethrow;
      throw AuthException('ログアウトに失敗しました');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      AppLogger.auth('sendPasswordResetEmail', error: e);
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.auth('sendPasswordResetEmail', error: e);
      throw AuthException('パスワードリセットメールの送信に失敗しました');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      AppLogger.auth('sendEmailVerification', error: e);
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.auth('sendEmailVerification', error: e);
      throw AuthException('確認メールの送信に失敗しました');
    }
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Firestoreのユーザー情報も更新
      final updates = <String, dynamic>{};
      if (displayName != null) updates['name'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

    } on FirebaseAuthException catch (e) {
      AppLogger.auth('updateProfile', error: e);
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.auth('updateProfile', error: e);
      throw AuthException('プロフィールの更新に失敗しました');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      // Firestoreからユーザーデータを削除
      await _firestore.collection('users').doc(user.uid).delete();

      // Firebase Authからアカウントを削除
      await user.delete();

    } on FirebaseAuthException catch (e) {
      AppLogger.auth('deleteAccount', error: e);
      throw AuthException(_getAuthErrorMessage(e));
    } catch (e) {
      AppLogger.auth('deleteAccount', error: e);
      throw AuthException('アカウントの削除に失敗しました');
    }
  }

  /// Firebase UserをUserEntityに変換
  Future<UserEntity> _mapFirebaseUserToEntity(User user) async {
    try {
      // Firestoreからユーザーの追加情報を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      return UserEntity(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? userData?['name'],
        photoUrl: user.photoURL ?? userData?['photoUrl'],
        isEmailVerified: user.emailVerified,
        createdAt: user.metadata.creationTime ?? 
                   (userData?['createdAt'] as Timestamp?)?.toDate() ?? 
                   DateTime.now(),
        lastLoginAt: user.metadata.lastSignInTime,
      );
    } catch (e) {
      // Firestoreの取得に失敗した場合はFirebase Authの情報のみ使用
      return UserEntity(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: user.metadata.lastSignInTime,
      );
    }
  }

  /// Firebase Authのエラーメッセージをユーザーフレンドリーなメッセージに変換
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'ユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが正しくありません';
      case 'invalid-email':
        return '無効なメールアドレスです';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく待ってから再試行してください';
      case 'operation-not-allowed':
        return 'この操作は許可されていません';
      case 'weak-password':
        return 'パスワードが弱すぎます';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'invalid-credential':
        return '認証情報が無効です';
      case 'account-exists-with-different-credential':
        return '別の認証方法で同じメールアドレスのアカウントが存在します';
      case 'requires-recent-login':
        return '再度ログインが必要です';
      default:
        return e.message ?? '認証エラーが発生しました';
    }
  }
}