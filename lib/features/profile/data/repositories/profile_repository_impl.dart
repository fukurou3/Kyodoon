import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_model.dart';
import '../models/user_preferences_model.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/security_validator.dart';

/// プロフィールリポジトリの実装
/// 
/// Firestore、Firebase Storage と連携し、ドメインエンティティとの変換を行う
class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _storage;

  ProfileRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<ProfileEntity?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      final profileModel = ProfileModel.fromFirestore(doc);
      return profileModel.toEntity();
    } catch (e) {
      AppLogger.error('Failed to get profile: $userId', e);
      throw DataException('プロフィールの取得に失敗しました');
    }
  }

  @override
  Future<ProfileEntity?> getCurrentUserProfile() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }

      return await getProfile(user.uid);
    } catch (e) {
      AppLogger.error('Failed to get current user profile', e);
      throw DataException('現在のユーザープロフィールの取得に失敗しました');
    }
  }

  @override
  Future<void> updateProfile(ProfileEntity profile) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (profile.userId != user.uid) {
        throw PermissionException('他のユーザーのプロフィールは編集できません');
      }

      final profileModel = ProfileModel.fromEntity(profile);
      await _firestore.collection('users').doc(profile.userId).update(profileModel.toFirestore());
      
      AppLogger.info('Profile updated successfully: ${profile.userId}');
    } catch (e) {
      AppLogger.error('Failed to update profile: ${profile.userId}', e);
      if (e is AuthException || e is PermissionException) rethrow;
      throw DataException('プロフィールの更新に失敗しました');
    }
  }

  @override
  Future<String> updateProfileImage(String userId, List<int> imageData) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (userId != user.uid) {
        throw PermissionException('他のユーザーのプロフィール画像は編集できません');
      }

      // Firebase Storageに画像をアップロード
      final ref = _storage.ref().child('profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putData(Uint8List.fromList(imageData));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // プロフィールドキュメントの画像URLを更新
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Profile image updated successfully: $userId');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Failed to update profile image: $userId', e);
      if (e is AuthException || e is PermissionException) rethrow;
      throw DataException('プロフィール画像の更新に失敗しました');
    }
  }

  @override
  Future<void> deleteProfileImage(String userId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (userId != user.uid) {
        throw PermissionException('他のユーザーのプロフィール画像は削除できません');
      }

      // プロフィールドキュメントの画像URLを削除
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Storage上の画像ファイルも削除（エラーが発生しても続行）
      try {
        final profileDoc = await _firestore.collection('users').doc(userId).get();
        final photoUrl = profileDoc.data()?['photoUrl'] as String?;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          final ref = _storage.refFromURL(photoUrl);
          await ref.delete();
        }
      } catch (storageError) {
        AppLogger.warning('Failed to delete image file from storage', storageError);
        // Storageの削除失敗は致命的ではないので続行
      }

      AppLogger.info('Profile image deleted successfully: $userId');
    } catch (e) {
      AppLogger.error('Failed to delete profile image: $userId', e);
      if (e is AuthException || e is PermissionException) rethrow;
      throw DataException('プロフィール画像の削除に失敗しました');
    }
  }

  @override
  Future<void> updatePostsCount(String userId, int increment) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (userDoc.exists) {
          final currentCount = userDoc.data()?['postsCount'] ?? 0;
          final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
          transaction.update(userRef, {
            'postsCount': newCount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      AppLogger.info('Posts count updated: $userId by $increment');
    } catch (e) {
      AppLogger.error('Failed to update posts count: $userId', e);
      // カウント更新の失敗は致命的ではないので例外を再スローしない
    }
  }

  @override
  Future<void> updateLikesCount(String userId, {int? givenIncrement, int? receivedIncrement}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (userDoc.exists) {
          final updates = <String, dynamic>{
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (givenIncrement != null) {
            final currentGiven = userDoc.data()?['likesGivenCount'] ?? 0;
            final newGiven = (currentGiven + givenIncrement).clamp(0, double.infinity).toInt();
            updates['likesGivenCount'] = newGiven;
          }

          if (receivedIncrement != null) {
            final currentReceived = userDoc.data()?['likesReceivedCount'] ?? 0;
            final newReceived = (currentReceived + receivedIncrement).clamp(0, double.infinity).toInt();
            updates['likesReceivedCount'] = newReceived;
          }

          transaction.update(userRef, updates);
        }
      });
      
      AppLogger.info('Likes count updated: $userId (given: $givenIncrement, received: $receivedIncrement)');
    } catch (e) {
      AppLogger.error('Failed to update likes count: $userId', e);
      // カウント更新の失敗は致命的ではないので例外を再スローしない
    }
  }

  @override
  Future<UserPreferencesEntity> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('user_preferences').doc(userId).get();
      
      UserPreferencesModel preferencesModel;
      if (doc.exists) {
        preferencesModel = UserPreferencesModel.fromFirestore(doc);
      } else {
        // デフォルト設定を作成
        preferencesModel = UserPreferencesModel.defaultSettings(userId);
      }

      return preferencesModel.toEntity();
    } catch (e) {
      AppLogger.error('Failed to get user preferences: $userId', e);
      throw DataException('ユーザー設定の取得に失敗しました');
    }
  }

  @override
  Future<void> updateUserPreferences(UserPreferencesEntity preferences) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (preferences.userId != user.uid) {
        throw PermissionException('他のユーザーの設定は編集できません');
      }

      // セキュリティ検証：ブロックユーザーリスト
      final blockedUsersValidation = SecurityValidator.validateBlockedUsersList(preferences.blockedUsers);
      if (!blockedUsersValidation.isValid) {
        throw ValidationException('ブロックユーザーリストの検証エラー: ${blockedUsersValidation.errorMessage}');
      }

      // セキュリティ検証：ミュートキーワードリスト
      final mutedKeywordsValidation = SecurityValidator.validateMutedKeywordsList(preferences.mutedKeywords);
      if (!mutedKeywordsValidation.isValid) {
        throw ValidationException('ミュートキーワードリストの検証エラー: ${mutedKeywordsValidation.errorMessage}');
      }

      // セキュリティ検証：プライバシー設定
      final privacyValidation = SecurityValidator.validatePrivacySettings(preferences.privacy);
      if (!privacyValidation.isValid) {
        throw ValidationException('プライバシー設定の検証エラー: ${privacyValidation.errorMessage}');
      }

      final preferencesModel = UserPreferencesModel.fromEntity(preferences);
      await _firestore.collection('user_preferences').doc(preferences.userId).set(
        preferencesModel.toFirestore(),
        SetOptions(merge: true),
      );
      
      AppLogger.info('User preferences updated successfully: ${preferences.userId}');
    } catch (e) {
      AppLogger.error('Failed to update user preferences: ${preferences.userId}', e);
      if (e is AuthException || e is PermissionException || e is ValidationException) rethrow;
      throw DataException('ユーザー設定の更新に失敗しました');
    }
  }

  @override
  Future<List<ProfileEntity>> searchUsers(String query, {int limit = 20}) async {
    try {
      // 表示名での検索
      final nameQuery = await _firestore
          .collection('users')
          .where('isPublic', isEqualTo: true)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(limit)
          .get();

      // 自治体での検索（名前検索の結果と重複する可能性があるが簡単のため）
      final municipalityQuery = await _firestore
          .collection('users')
          .where('isPublic', isEqualTo: true)
          .where('municipality', isGreaterThanOrEqualTo: query)
          .where('municipality', isLessThan: '${query}z')
          .limit(limit)
          .get();

      final profiles = <ProfileEntity>[];
      final seenUserIds = <String>{};

      // 名前検索の結果を追加
      for (final doc in nameQuery.docs) {
        if (!seenUserIds.contains(doc.id)) {
          try {
            final profile = ProfileModel.fromFirestore(doc).toEntity();
            profiles.add(profile);
            seenUserIds.add(doc.id);
          } catch (e) {
            AppLogger.error('Failed to parse user profile: ${doc.id}', e);
          }
        }
      }

      // 自治体検索の結果を追加（重複を除く）
      for (final doc in municipalityQuery.docs) {
        if (!seenUserIds.contains(doc.id) && profiles.length < limit) {
          try {
            final profile = ProfileModel.fromFirestore(doc).toEntity();
            profiles.add(profile);
            seenUserIds.add(doc.id);
          } catch (e) {
            AppLogger.error('Failed to parse user profile: ${doc.id}', e);
          }
        }
      }

      return profiles.take(limit).toList();
    } catch (e) {
      AppLogger.error('Failed to search users: $query', e);
      throw DataException('ユーザー検索に失敗しました');
    }
  }

  @override
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (currentUserId != user.uid) {
        throw PermissionException('権限がありません');
      }

      // 自分自身をブロックしようとした場合のチェック
      if (currentUserId == targetUserId) {
        throw ValidationException('自分自身をブロックすることはできません');
      }

      // ターゲットユーザーIDのバリデーション
      final userIdValidation = SecurityValidator.validateUserIdForBlocking(targetUserId);
      if (!userIdValidation.isValid) {
        throw ValidationException('無効なユーザーID: ${userIdValidation.errorMessage}');
      }

      await _firestore.runTransaction((transaction) async {
        final preferencesRef = _firestore.collection('user_preferences').doc(currentUserId);
        final preferencesDoc = await transaction.get(preferencesRef);

        List<String> blockedUsers;
        if (preferencesDoc.exists) {
          blockedUsers = List<String>.from(preferencesDoc.data()?['blockedUsers'] ?? []);
        } else {
          blockedUsers = [];
        }

        // ブロックリストの上限チェック
        if (blockedUsers.length >= 1000) {
          throw ValidationException('ブロックユーザー数が上限に達しています（最大1000ユーザー）');
        }

        if (!blockedUsers.contains(targetUserId)) {
          blockedUsers.add(targetUserId);
          
          // セキュリティ検証：更新後のリスト全体をチェック
          final validation = SecurityValidator.validateBlockedUsersList(blockedUsers);
          if (!validation.isValid) {
            throw ValidationException('ブロックリストの検証エラー: ${validation.errorMessage}');
          }

          transaction.set(preferencesRef, {
            'blockedUsers': blockedUsers,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
      
      AppLogger.info('User blocked: $targetUserId by $currentUserId');
    } catch (e) {
      AppLogger.error('Failed to block user: $targetUserId', e);
      if (e is AuthException || e is PermissionException || e is ValidationException) rethrow;
      throw DataException('ユーザーのブロックに失敗しました');
    }
  }

  @override
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (currentUserId != user.uid) {
        throw PermissionException('権限がありません');
      }

      // ターゲットユーザーIDのバリデーション
      final userIdValidation = SecurityValidator.validateUserIdForBlocking(targetUserId);
      if (!userIdValidation.isValid) {
        throw ValidationException('無効なユーザーID: ${userIdValidation.errorMessage}');
      }

      await _firestore.runTransaction((transaction) async {
        final preferencesRef = _firestore.collection('user_preferences').doc(currentUserId);
        final preferencesDoc = await transaction.get(preferencesRef);

        if (preferencesDoc.exists) {
          final blockedUsers = List<String>.from(preferencesDoc.data()?['blockedUsers'] ?? []);
          
          // ユーザーが実際にブロックリストに存在するかチェック
          if (blockedUsers.contains(targetUserId)) {
            blockedUsers.remove(targetUserId);
            
            // セキュリティ検証：更新後のリスト全体をチェック
            final validation = SecurityValidator.validateBlockedUsersList(blockedUsers);
            if (!validation.isValid) {
              throw ValidationException('ブロックリストの検証エラー: ${validation.errorMessage}');
            }
            
            transaction.update(preferencesRef, {
              'blockedUsers': blockedUsers,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });
      
      AppLogger.info('User unblocked: $targetUserId by $currentUserId');
    } catch (e) {
      AppLogger.error('Failed to unblock user: $targetUserId', e);
      if (e is AuthException || e is PermissionException || e is ValidationException) rethrow;
      throw DataException('ユーザーのブロック解除に失敗しました');
    }
  }

  @override
  Future<List<ProfileEntity>> getBlockedUsers(String userId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (userId != user.uid) {
        throw PermissionException('権限がありません');
      }

      final preferencesDoc = await _firestore.collection('user_preferences').doc(userId).get();
      if (!preferencesDoc.exists) {
        return [];
      }

      final blockedUserIds = List<String>.from(preferencesDoc.data()?['blockedUsers'] ?? []);
      if (blockedUserIds.isEmpty) {
        return [];
      }

      // ブロックされたユーザーのプロフィールを取得
      final profiles = <ProfileEntity>[];
      for (final blockedUserId in blockedUserIds) {
        try {
          final profile = await getProfile(blockedUserId);
          if (profile != null) {
            profiles.add(profile);
          }
        } catch (e) {
          AppLogger.warning('Failed to get blocked user profile: $blockedUserId', e);
          // 個別のプロフィール取得失敗は続行
        }
      }

      return profiles;
    } catch (e) {
      AppLogger.error('Failed to get blocked users: $userId', e);
      if (e is AuthException || e is PermissionException) rethrow;
      throw DataException('ブロックユーザー一覧の取得に失敗しました');
    }
  }

  @override
  Future<void> refreshProfileStats(String userId) async {
    try {
      // 投稿数を集計
      final postsQuery = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();
      final postsCount = postsQuery.docs.length;

      // 与えたいいね数を集計（簡略化のため省略、実際の実装では必要）
      // 受け取ったいいね数を集計（簡略化のため省略、実際の実装では必要）

      // プロフィールを更新
      await _firestore.collection('users').doc(userId).update({
        'postsCount': postsCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Profile stats refreshed: $userId');
    } catch (e) {
      AppLogger.error('Failed to refresh profile stats: $userId', e);
      throw DataException('プロフィール統計の更新に失敗しました');
    }
  }

  @override
  Future<void> deleteAccount(String userId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      if (userId != user.uid) {
        throw PermissionException('権限がありません');
      }

      // バッチ処理でプロフィールと設定を削除
      final batch = _firestore.batch();
      
      batch.delete(_firestore.collection('users').doc(userId));
      batch.delete(_firestore.collection('user_preferences').doc(userId));
      
      await batch.commit();
      
      AppLogger.info('Account deleted: $userId');
    } catch (e) {
      AppLogger.error('Failed to delete account: $userId', e);
      if (e is AuthException || e is PermissionException) rethrow;
      throw DataException('アカウントの削除に失敗しました');
    }
  }
}