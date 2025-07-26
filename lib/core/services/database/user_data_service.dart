import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_base_service.dart';
import '../../../features/profile/domain/entities/profile_entity.dart';
import '../../../features/profile/domain/entities/user_preferences_entity.dart';
import '../../../features/profile/data/models/profile_model.dart';
import '../../../features/profile/data/models/user_preferences_model.dart';
import '../../../utils/app_logger.dart';

/// ユーザーデータサービス
/// 
/// ユーザー情報に関するFirestore操作に特化したサービス
class UserDataService extends FirestoreBaseService {
  static const String _usersCollection = 'users';
  static const String _userPreferencesCollection = 'user_preferences';

  UserDataService({
    super.firestore,
    super.firebaseAuth,
  });

  /// ユーザープロフィールを取得
  Future<ProfileEntity?> getUserProfile(String userId) async {
    try {
      final doc = await safeDocumentReference(_usersCollection, userId).get();
      
      if (!doc.exists) {
        return null;
      }

      return ProfileModel.fromFirestore(doc).toEntity();
    } catch (e) {
      handleFirestoreError(e, 'ユーザープロフィールの取得');
    }
  }

  /// 現在のユーザープロフィールを取得
  Future<ProfileEntity?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      return null;
    }
    return await getUserProfile(userId);
  }

  /// ユーザープロフィールを作成
  Future<void> createUserProfile(ProfileEntity profile) async {
    try {
      final profileModel = ProfileModel.fromEntity(profile);
      await safeDocumentReference(_usersCollection, profile.userId)
          .set(profileModel.toFirestore());
      
      AppLogger.info('User profile created: ${profile.userId}');
    } catch (e) {
      handleFirestoreError(e, 'ユーザープロフィールの作成');
    }
  }

  /// ユーザープロフィールを更新
  Future<void> updateUserProfile(ProfileEntity profile) async {
    try {
      final profileModel = ProfileModel.fromEntity(profile);
      await safeDocumentReference(_usersCollection, profile.userId)
          .update(profileModel.toFirestore());
      
      AppLogger.info('User profile updated: ${profile.userId}');
    } catch (e) {
      handleFirestoreError(e, 'ユーザープロフィールの更新');
    }
  }

  /// ユーザープロフィールを削除
  Future<void> deleteUserProfile(String userId) async {
    try {
      await safeDocumentReference(_usersCollection, userId).delete();
      AppLogger.info('User profile deleted: $userId');
    } catch (e) {
      handleFirestoreError(e, 'ユーザープロフィールの削除');
    }
  }

  /// ユーザー設定を取得
  Future<UserPreferencesEntity> getUserPreferences(String userId) async {
    try {
      final doc = await safeDocumentReference(_userPreferencesCollection, userId).get();
      
      UserPreferencesModel preferencesModel;
      if (doc.exists) {
        preferencesModel = UserPreferencesModel.fromFirestore(doc);
      } else {
        preferencesModel = UserPreferencesModel.defaultSettings(userId);
      }

      return preferencesModel.toEntity();
    } catch (e) {
      handleFirestoreError(e, 'ユーザー設定の取得');
    }
  }

  /// ユーザー設定を更新
  Future<void> updateUserPreferences(UserPreferencesEntity preferences) async {
    try {
      final preferencesModel = UserPreferencesModel.fromEntity(preferences);
      await safeDocumentReference(_userPreferencesCollection, preferences.userId)
          .set(preferencesModel.toFirestore(), SetOptions(merge: true));
      
      AppLogger.info('User preferences updated: ${preferences.userId}');
    } catch (e) {
      handleFirestoreError(e, 'ユーザー設定の更新');
    }
  }

  /// ユーザー設定を削除
  Future<void> deleteUserPreferences(String userId) async {
    try {
      await safeDocumentReference(_userPreferencesCollection, userId).delete();
      AppLogger.info('User preferences deleted: $userId');
    } catch (e) {
      handleFirestoreError(e, 'ユーザー設定の削除');
    }
  }

  /// ユーザーを検索
  Future<List<ProfileEntity>> searchUsers(String query, {int limit = 20}) async {
    try {
      // 表示名での検索
      final nameQuery = await firestore
          .collection(_usersCollection)
          .where('isPublic', isEqualTo: true)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(limit)
          .get();

      // 自治体での検索
      final municipalityQuery = await firestore
          .collection(_usersCollection)
          .where('isPublic', isEqualTo: true)
          .where('municipality', isGreaterThanOrEqualTo: query)
          .where('municipality', isLessThan: '${query}z')
          .limit(limit)
          .get();

      final profiles = <ProfileEntity>[];
      final seenUserIds = <String>{};

      // 結果をマージ（重複除去）
      for (final doc in [...nameQuery.docs, ...municipalityQuery.docs]) {
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

      return profiles;
    } catch (e) {
      handleFirestoreError(e, 'ユーザー検索');
    }
  }

  /// ユーザーの統計情報を更新
  Future<void> updateUserStats(String userId, {
    int? postsIncrement,
    int? likesGivenIncrement,
    int? likesReceivedIncrement,
  }) async {
    try {
      await executeTransaction((transaction) async {
        final userRef = safeDocumentReference(_usersCollection, userId);
        final userDoc = await transaction.get(userRef);
        
        if (userDoc.exists) {
          final updates = <String, dynamic>{
            'updatedAt': serverTimestamp,
          };

          if (postsIncrement != null) {
            final currentPosts = userDoc.data()?['postsCount'] ?? 0;
            final newPosts = (currentPosts + postsIncrement).clamp(0, double.infinity).toInt();
            updates['postsCount'] = newPosts;
          }

          if (likesGivenIncrement != null) {
            final currentGiven = userDoc.data()?['likesGivenCount'] ?? 0;
            final newGiven = (currentGiven + likesGivenIncrement).clamp(0, double.infinity).toInt();
            updates['likesGivenCount'] = newGiven;
          }

          if (likesReceivedIncrement != null) {
            final currentReceived = userDoc.data()?['likesReceivedCount'] ?? 0;
            final newReceived = (currentReceived + likesReceivedIncrement).clamp(0, double.infinity).toInt();
            updates['likesReceivedCount'] = newReceived;
          }

          transaction.update(userRef, updates);
        }
      });
      
      AppLogger.info('User stats updated: $userId');
    } catch (e) {
      AppLogger.error('Failed to update user stats: $userId', e);
      // 統計更新の失敗は致命的ではないので例外を再スローしない
    }
  }

  /// ユーザーの実際の統計を集計して更新
  Future<void> refreshUserStats(String userId) async {
    try {
      // 投稿数を集計
      final postsCount = await getCollectionCount(
        'posts',
        query: firestore
            .collection('posts')
            .where('authorId', isEqualTo: userId)
            .where('isDeleted', isEqualTo: false),
      );

      // プロフィールを更新
      await safeDocumentReference(_usersCollection, userId).update({
        'postsCount': postsCount,
        'updatedAt': serverTimestamp,
      });
      
      AppLogger.info('User stats refreshed: $userId');
    } catch (e) {
      handleFirestoreError(e, 'ユーザー統計の更新');
    }
  }

  /// ユーザーの全データを削除（アカウント削除時）
  Future<void> deleteAllUserData(String userId) async {
    try {
      await executeBatch((batch) {
        batch.delete(safeDocumentReference(_usersCollection, userId));
        batch.delete(safeDocumentReference(_userPreferencesCollection, userId));
      });
      
      AppLogger.info('All user data deleted: $userId');
    } catch (e) {
      handleFirestoreError(e, 'ユーザーデータの削除');
    }
  }

  /// ユーザーが存在するかチェック
  Future<bool> userExists(String userId) async {
    return await documentExists(_usersCollection, userId);
  }

  /// 公開プロフィールの一覧を取得
  Future<List<ProfileEntity>> getPublicProfiles({int limit = 50}) async {
    try {
      final snapshot = await firestore
          .collection(_usersCollection)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        try {
          return ProfileModel.fromFirestore(doc).toEntity();
        } catch (e) {
          AppLogger.error('Failed to parse public profile: ${doc.id}', e);
          return null;
        }
      }).where((profile) => profile != null).cast<ProfileEntity>().toList();
    } catch (e) {
      handleFirestoreError(e, '公開プロフィール一覧の取得');
    }
  }

  /// アクティブユーザー数を取得
  Future<int> getActiveUsersCount() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      return await getCollectionCount(
        _usersCollection,
        query: firestore
            .collection(_usersCollection)
            .where('lastLoginAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo)),
      );
    } catch (e) {
      AppLogger.error('Failed to get active users count', e);
      return 0;
    }
  }
}