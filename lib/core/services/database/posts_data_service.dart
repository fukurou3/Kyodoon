import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_base_service.dart';
import '../../../features/posts/domain/entities/post_entity.dart';
import '../../../features/posts/data/models/post_model.dart';
import '../../../utils/app_logger.dart';

/// 投稿データサービス
/// 
/// 投稿に関するFirestore操作に特化したサービス
class PostsDataService extends FirestoreBaseService {
  static const String _postsCollection = 'posts';

  PostsDataService({
    super.firestore,
    super.firebaseAuth,
  });

  /// 投稿一覧をストリームで取得
  Stream<List<PostEntity>> getPostsStream({
    PostType? type,
    int limit = 50,
    String? municipality,
  }) {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      if (type != null) {
        final typeString = type == PostType.casual ? 'casual' : 'serious';
        query = query.where('type', isEqualTo: typeString);
      }

      if (municipality != null && municipality.isNotEmpty) {
        query = query.where('municipality', isEqualTo: municipality);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return PostModel.fromFirestore(doc).toEntity();
          } catch (e) {
            AppLogger.error('Failed to parse post document: ${doc.id}', e);
            return null;
          }
        }).where((post) => post != null).cast<PostEntity>().toList();
      });
    } catch (e) {
      AppLogger.error('Failed to get posts stream', e);
      return Stream.value([]);
    }
  }

  /// 特定の投稿を取得
  Future<PostEntity?> getPost(String postId) async {
    try {
      final doc = await safeDocumentReference(_postsCollection, postId).get();
      
      if (!doc.exists) {
        return null;
      }

      return PostModel.fromFirestore(doc).toEntity();
    } catch (e) {
      handleFirestoreError(e, '投稿の取得');
    }
  }

  /// ユーザーの投稿一覧を取得
  Future<List<PostEntity>> getUserPosts(String userId, {int limit = 50}) async {
    try {
      final snapshot = await firestore
          .collection(_postsCollection)
          .where('authorId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        try {
          return PostModel.fromFirestore(doc).toEntity();
        } catch (e) {
          AppLogger.error('Failed to parse user post document: ${doc.id}', e);
          return null;
        }
      }).where((post) => post != null).cast<PostEntity>().toList();
    } catch (e) {
      handleFirestoreError(e, 'ユーザー投稿の取得');
    }
  }

  /// 投稿を作成
  Future<String> createPost(PostEntity post, String authorId, String authorName) async {
    try {
      final postModel = PostModel.fromEntity(post).copyWith(
        authorId: authorId,
        authorName: authorName,
        createdAt: DateTime.now(),
      );

      final docRef = await firestore
          .collection(_postsCollection)
          .add(postModel.toFirestore());
      
      AppLogger.info('Post created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      handleFirestoreError(e, '投稿の作成');
    }
  }

  /// 投稿を更新
  Future<void> updatePost(PostEntity post) async {
    try {
      final postModel = PostModel.fromEntity(post);
      await safeDocumentReference(_postsCollection, post.id)
          .update(postModel.toFirestore());
      
      AppLogger.info('Post updated successfully: ${post.id}');
    } catch (e) {
      handleFirestoreError(e, '投稿の更新');
    }
  }

  /// 投稿を論理削除
  Future<void> deletePost(String postId) async {
    try {
      await safeDocumentReference(_postsCollection, postId).update({
        'isDeleted': true,
        'updatedAt': serverTimestamp,
      });
      
      AppLogger.info('Post deleted successfully: $postId');
    } catch (e) {
      handleFirestoreError(e, '投稿の削除');
    }
  }

  /// 投稿にいいねを追加
  Future<void> addLikeToPost(String postId, String userId) async {
    try {
      await executeTransaction((transaction) async {
        final postRef = safeDocumentReference(_postsCollection, postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('投稿が見つかりません');
        }

        final currentLikedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
        
        if (!currentLikedBy.contains(userId)) {
          currentLikedBy.add(userId);
          transaction.update(postRef, {
            'likedBy': currentLikedBy,
            'likesCount': currentLikedBy.length,
          });
        }
      });
      
      AppLogger.info('Like added to post: $postId by $userId');
    } catch (e) {
      handleFirestoreError(e, 'いいねの追加');
    }
  }

  /// 投稿からいいねを削除
  Future<void> removeLikeFromPost(String postId, String userId) async {
    try {
      await executeTransaction((transaction) async {
        final postRef = safeDocumentReference(_postsCollection, postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw Exception('投稿が見つかりません');
        }

        final currentLikedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
        
        if (currentLikedBy.contains(userId)) {
          currentLikedBy.remove(userId);
          transaction.update(postRef, {
            'likedBy': currentLikedBy,
            'likesCount': currentLikedBy.length,
          });
        }
      });
      
      AppLogger.info('Like removed from post: $postId by $userId');
    } catch (e) {
      handleFirestoreError(e, 'いいねの削除');
    }
  }

  /// 投稿のコメント数を更新
  Future<void> updatePostCommentsCount(String postId, int increment) async {
    try {
      await executeTransaction((transaction) async {
        final postRef = safeDocumentReference(_postsCollection, postId);
        final postDoc = await transaction.get(postRef);
        
        if (postDoc.exists) {
          final currentCount = postDoc.data()?['commentsCount'] ?? 0;
          final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
          transaction.update(postRef, {'commentsCount': newCount});
        }
      });
    } catch (e) {
      AppLogger.error('Failed to update comments count for post: $postId', e);
      // コメント数の更新失敗は致命的ではないので例外を再スローしない
    }
  }

  /// 投稿の統計情報を取得
  Future<Map<String, int>> getPostStats(String postId) async {
    try {
      final doc = await safeDocumentReference(_postsCollection, postId).get();
      
      if (!doc.exists) {
        return {'likes': 0, 'comments': 0};
      }

      final data = doc.data()!;
      return {
        'likes': data['likesCount'] ?? 0,
        'comments': data['commentsCount'] ?? 0,
      };
    } catch (e) {
      AppLogger.error('Failed to get post stats: $postId', e);
      return {'likes': 0, 'comments': 0};
    }
  }

  /// ユーザーの投稿統計を取得
  Future<Map<String, int>> getUserPostStats(String userId) async {
    try {
      // 投稿数を取得
      final postsCount = await getCollectionCount(
        _postsCollection,
        query: firestore
            .collection(_postsCollection)
            .where('authorId', isEqualTo: userId)
            .where('isDeleted', isEqualTo: false),
      );

      // 受け取ったいいね数を集計（簡略化のため省略）
      // 実際の実装では全投稿のlikedByを集計する必要がある

      return {
        'posts': postsCount,
        'likesReceived': 0, // 実装省略
      };
    } catch (e) {
      AppLogger.error('Failed to get user post stats: $userId', e);
      return {'posts': 0, 'likesReceived': 0};
    }
  }

  /// 投稿タイプ別の件数を取得
  Future<Map<PostType, int>> getPostCountsByType() async {
    try {
      final casualCount = await getCollectionCount(
        _postsCollection,
        query: firestore
            .collection(_postsCollection)
            .where('type', isEqualTo: 'casual')
            .where('isDeleted', isEqualTo: false),
      );

      final seriousCount = await getCollectionCount(
        _postsCollection,
        query: firestore
            .collection(_postsCollection)
            .where('type', isEqualTo: 'serious')
            .where('isDeleted', isEqualTo: false),
      );

      return {
        PostType.casual: casualCount,
        PostType.serious: seriousCount,
      };
    } catch (e) {
      AppLogger.error('Failed to get post counts by type', e);
      return {PostType.casual: 0, PostType.serious: 0};
    }
  }
}