import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/posts_repository.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/rate_limiter.dart';
import '../../../../core/services/external/secure_notification_service.dart';

/// 投稿リポジトリの実装
/// 
/// Firestore と連携し、ドメインエンティティとの変換を行う
class PostsRepositoryImpl implements PostsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SecureNotificationService _notificationService;

  PostsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    SecureNotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _notificationService = notificationService ?? SecureNotificationService();

  @override
  Stream<List<PostEntity>> getPosts({
    PostType? type,
    int limit = 50,
    String? municipality,
  }) {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('posts')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      // タイプでフィルタ
      if (type != null) {
        query = query.where('type', isEqualTo: type == PostType.casual ? 'casual' : 'serious');
      }

      // 自治体でフィルタ
      if (municipality != null && municipality.isNotEmpty) {
        query = query.where('municipality', isEqualTo: municipality);
      }

      // 件数制限
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

  @override
  Future<PostEntity?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      
      if (!doc.exists) {
        return null;
      }

      final postModel = PostModel.fromFirestore(doc);
      return postModel.toEntity();
    } catch (e) {
      AppLogger.error('Failed to get post: $postId', e);
      throw DataException('投稿の取得に失敗しました');
    }
  }

  @override
  Future<List<PostEntity>> getUserPosts(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
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
      AppLogger.error('Failed to get user posts: $userId', e);
      throw DataException('ユーザーの投稿取得に失敗しました');
    }
  }

  @override
  Future<String> createPost(PostEntity post) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      // レート制限チェック
      final rateLimitResult = await RateLimiter.checkUserLimit('post_create', user.uid);
      if (!rateLimitResult.allowed) {
        AppLogger.warning('投稿レート制限', {
          'userId': user.uid,
          'reason': rateLimitResult.reason,
          'remainingTime': rateLimitResult.remainingTime,
        });
        throw RateLimitException(rateLimitResult.message);
      }

      // ユーザー情報を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      // 投稿モデルを作成
      final postModel = PostModel.fromEntity(post).copyWith(
        authorId: user.uid,
        authorName: userName,
        createdAt: DateTime.now(),
      );

      // Firestoreに保存
      final docRef = await _firestore.collection('posts').add(postModel.toFirestore());
      
      AppLogger.info('Post created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create post', e);
      if (e is AuthException || e is RateLimitException) rethrow;
      throw DataException('投稿の作成に失敗しました');
    }
  }

  @override
  Future<void> updatePost(PostEntity post) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      // 権限チェック
      if (!post.canEdit(user.uid)) {
        throw PermissionException('投稿の編集権限がありません');
      }

      final postModel = PostModel.fromEntity(post);
      await _firestore.collection('posts').doc(post.id).update(postModel.toFirestore());
      
      AppLogger.info('Post updated successfully: ${post.id}');
    } catch (e) {
      AppLogger.error('Failed to update post: ${post.id}', e);
      if (e is AuthException || e is PermissionException) rethrow;
      throw DataException('投稿の更新に失敗しました');
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      // 論理削除
      await _firestore.collection('posts').doc(postId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Post deleted successfully: $postId');
    } catch (e) {
      AppLogger.error('Failed to delete post: $postId', e);
      if (e is AuthException) rethrow;
      throw DataException('投稿の削除に失敗しました');
    }
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    try {
      String? postAuthorId;
      bool wasLiked = false;
      
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('posts').doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw DataException('投稿が見つかりません');
        }

        final currentLikedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
        postAuthorId = postDoc.data()?['authorId'];
        
        if (!currentLikedBy.contains(userId)) {
          currentLikedBy.add(userId);
          transaction.update(postRef, {
            'likedBy': currentLikedBy,
            'likesCount': currentLikedBy.length,
          });
          wasLiked = true;
        }
      });
      
      // 通知を送信（自分への通知は不要）
      if (wasLiked && postAuthorId != null && postAuthorId != userId) {
        try {
          await _notificationService.requestPostNotification(
            postId: postId,
            postAuthorId: postAuthorId!,
            action: 'like',
          );
        } catch (e) {
          AppLogger.warning('Failed to send like notification', e);
          // 通知失敗は致命的ではないので継続
        }
      }
      
      AppLogger.info('Post liked: $postId by $userId');
    } catch (e) {
      AppLogger.error('Failed to like post: $postId', e);
      if (e is DataException) rethrow;
      throw DataException('いいねに失敗しました');
    }
  }

  @override
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('posts').doc(postId);
        final postDoc = await transaction.get(postRef);
        
        if (!postDoc.exists) {
          throw DataException('投稿が見つかりません');
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
      
      AppLogger.info('Post unliked: $postId by $userId');
    } catch (e) {
      AppLogger.error('Failed to unlike post: $postId', e);
      if (e is DataException) rethrow;
      throw DataException('いいね取り消しに失敗しました');
    }
  }

  @override
  Stream<List<CommentEntity>> getComments(String postId, {int limit = 100}) {
    try {
      return _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return CommentModel.fromFirestore(doc).toEntity();
          } catch (e) {
            AppLogger.error('Failed to parse comment document: ${doc.id}', e);
            return null;
          }
        }).where((comment) => comment != null).cast<CommentEntity>().toList();
      });
    } catch (e) {
      AppLogger.error('Failed to get comments stream for post: $postId', e);
      return Stream.value([]);
    }
  }

  @override
  Future<String> createComment(CommentEntity comment) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      // レート制限チェック
      final rateLimitResult = await RateLimiter.checkUserLimit('comment_create', user.uid);
      if (!rateLimitResult.allowed) {
        throw RateLimitException(rateLimitResult.message);
      }

      // ユーザー情報を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      // 投稿情報を取得（通知用）
      final postDoc = await _firestore.collection('posts').doc(comment.postId).get();
      final postAuthorId = postDoc.data()?['authorId'];

      // コメントモデルを作成
      final commentModel = CommentModel.fromEntity(comment).copyWith(
        authorId: user.uid,
        authorName: userName,
        createdAt: DateTime.now(),
      );

      // Firestoreに保存
      final docRef = await _firestore
          .collection('posts')
          .doc(comment.postId)
          .collection('comments')
          .add(commentModel.toFirestore());

      // 投稿のコメント数を更新
      await _updatePostCommentsCount(comment.postId, 1);

      // 通知を送信（自分への通知は不要）
      if (postAuthorId != null && postAuthorId != user.uid) {
        try {
          await _notificationService.requestPostNotification(
            postId: comment.postId,
            postAuthorId: postAuthorId,
            action: 'comment',
            commentContent: comment.content,
          );
        } catch (e) {
          AppLogger.warning('Failed to send comment notification', e);
          // 通知失敗は致命的ではないので継続
        }
      }
      
      AppLogger.info('Comment created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Failed to create comment', e);
      if (e is AuthException || e is RateLimitException) rethrow;
      throw DataException('コメントの作成に失敗しました');
    }
  }

  @override
  Future<void> updateComment(CommentEntity comment) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      // 権限チェック
      if (!comment.canEdit(user.uid)) {
        throw PermissionException('コメントの編集権限がありません');
      }

      final commentModel = CommentModel.fromEntity(comment);
      await _firestore
          .collection('posts')
          .doc(comment.postId)
          .collection('comments')
          .doc(comment.id)
          .update(commentModel.toFirestore());
      
      AppLogger.info('Comment updated successfully: ${comment.id}');
    } catch (e) {
      AppLogger.error('Failed to update comment: ${comment.id}', e);
      if (e is AuthException || e is PermissionException) rethrow;
      throw DataException('コメントの更新に失敗しました');
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('ログインが必要です');
      }

      // コメントを取得してpostIdを確認
      final commentQuery = await _firestore
          .collectionGroup('comments')
          .where(FieldPath.documentId, isEqualTo: commentId)
          .get();

      if (commentQuery.docs.isEmpty) {
        throw DataException('コメントが見つかりません');
      }

      final commentDoc = commentQuery.docs.first;
      final postId = commentDoc.data()['postId'] as String;

      // 論理削除
      await commentDoc.reference.update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 投稿のコメント数を更新
      await _updatePostCommentsCount(postId, -1);
      
      AppLogger.info('Comment deleted successfully: $commentId');
    } catch (e) {
      AppLogger.error('Failed to delete comment: $commentId', e);
      if (e is AuthException || e is DataException) rethrow;
      throw DataException('コメントの削除に失敗しました');
    }
  }

  @override
  Future<void> likeComment(String commentId, String userId) async {
    try {
      // コメントを取得
      final commentQuery = await _firestore
          .collectionGroup('comments')
          .where(FieldPath.documentId, isEqualTo: commentId)
          .get();

      if (commentQuery.docs.isEmpty) {
        throw DataException('コメントが見つかりません');
      }

      final commentRef = commentQuery.docs.first.reference;

      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw DataException('コメントが見つかりません');
        }

        final currentLikedBy = List<String>.from(commentDoc.data()?['likedBy'] ?? []);
        
        if (!currentLikedBy.contains(userId)) {
          currentLikedBy.add(userId);
          transaction.update(commentRef, {
            'likedBy': currentLikedBy,
            'likesCount': currentLikedBy.length,
          });
        }
      });
      
      AppLogger.info('Comment liked: $commentId by $userId');
    } catch (e) {
      AppLogger.error('Failed to like comment: $commentId', e);
      if (e is DataException) rethrow;
      throw DataException('コメントのいいねに失敗しました');
    }
  }

  @override
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      // コメントを取得
      final commentQuery = await _firestore
          .collectionGroup('comments')
          .where(FieldPath.documentId, isEqualTo: commentId)
          .get();

      if (commentQuery.docs.isEmpty) {
        throw DataException('コメントが見つかりません');
      }

      final commentRef = commentQuery.docs.first.reference;

      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw DataException('コメントが見つかりません');
        }

        final currentLikedBy = List<String>.from(commentDoc.data()?['likedBy'] ?? []);
        
        if (currentLikedBy.contains(userId)) {
          currentLikedBy.remove(userId);
          transaction.update(commentRef, {
            'likedBy': currentLikedBy,
            'likesCount': currentLikedBy.length,
          });
        }
      });
      
      AppLogger.info('Comment unliked: $commentId by $userId');
    } catch (e) {
      AppLogger.error('Failed to unlike comment: $commentId', e);
      if (e is DataException) rethrow;
      throw DataException('コメントのいいね取り消しに失敗しました');
    }
  }

  /// 投稿のコメント数を更新
  Future<void> _updatePostCommentsCount(String postId, int increment) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('posts').doc(postId);
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
}