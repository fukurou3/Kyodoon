import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../errors/app_exceptions.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/security_validator.dart';
import 'notification_service.dart';
import 'models/secure_notification.dart';

/// セキュアな通知サービス
/// 
/// Firestore Security Rulesに準拠した安全な通知管理
class SecureNotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final NotificationService _localNotificationService;

  SecureNotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    NotificationService? localNotificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
        _localNotificationService = localNotificationService ?? NotificationService();

  /// 自分の通知一覧を取得
  Stream<List<SecureNotification>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return SecureNotification.fromFirestore(doc);
        } catch (e) {
          AppLogger.error('Failed to parse notification: ${doc.id}', e);
          return null;
        }
      }).where((notification) => notification != null)
          .cast<SecureNotification>()
          .toList();
    });
  }

  /// 自分宛ての通知を作成（テスト用途のみ）
  Future<void> createSelfNotification({
    required String type,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    try {
      final notification = {
        'type': type,
        'userId': user.uid, // 自分のIDのみ許可
        'message': message,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('notifications').add(notification);
      AppLogger.info('Self notification created: $type');
    } catch (e) {
      AppLogger.error('Failed to create self notification', e);
      throw DataException('通知の作成に失敗しました');
    }
  }

  /// 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      AppLogger.debug('Notification marked as read: $notificationId');
    } catch (e) {
      AppLogger.error('Failed to mark notification as read: $notificationId', e);
      throw DataException('通知の更新に失敗しました');
    }
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();

      AppLogger.debug('Notification deleted: $notificationId');
    } catch (e) {
      AppLogger.error('Failed to delete notification: $notificationId', e);
      throw DataException('通知の削除に失敗しました');
    }
  }

  /// すべての通知を既読にする
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    try {
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': timestamp,
        });
      }

      await batch.commit();
      AppLogger.info('All notifications marked as read for user: ${user.uid}');
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read', e);
      throw DataException('通知の一括更新に失敗しました');
    }
  }

  /// 未読通知数を取得
  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return 0;
    }

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get unread count', e);
      return 0;
    }
  }

  /// 他ユーザーへの通知をリクエスト（Cloud Function経由）
  /// 
  /// セキュリティ上、他ユーザーへの通知は直接作成せず、
  /// Cloud Functionを呼び出してサーバーサイドで作成する
  Future<void> requestNotificationToUser({
    required String targetUserId,
    required String notificationType,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    // XSS対策: メッセージ内容をサニタイズ
    final sanitizedMessage = SecurityValidator.sanitizeHtml(message);

    try {
      // Cloud Function を呼び出す実装
      final callable = _functions.httpsCallable('createNotification');
      
      final result = await callable.call({
        'targetUserId': targetUserId,
        'type': notificationType,
        'message': sanitizedMessage,
        'metadata': data ?? {},
      });

      final responseData = result.data as Map<String, dynamic>;
      if (!responseData['success']) {
        throw Exception('通知の作成に失敗しました');
      }

      AppLogger.info('Notification created successfully via Cloud Function: $targetUserId');
    } catch (e) {
      AppLogger.error('Failed to request notification to user: $targetUserId', e);
      
      // Cloud Function呼び出しに失敗した場合、ローカル通知で代替
      _localNotificationService.showInAppNotification(
        title: '通知エラー',
        body: '通知の送信に失敗しました',
        type: NotificationType.error,
        autoHide: const Duration(seconds: 3),
      );
      
      throw DataException('通知リクエストに失敗しました');
    }
  }

  /// いいね通知の作成
  Future<void> createLikeNotification({
    required String targetUserId,
    required String postId,
  }) async {
    await requestNotificationToUser(
      targetUserId: targetUserId,
      notificationType: 'like',
      message: 'あなたの投稿にいいねしました',
      data: {'postId': postId},
    );
  }

  /// コメント通知の作成
  Future<void> createCommentNotification({
    required String targetUserId,
    required String postId,
    required String commentId,
    String? commentPreview,
  }) async {
    String message = 'あなたの投稿にコメントしました';
    if (commentPreview != null && commentPreview.isNotEmpty) {
      // XSS対策: コメント内容をサニタイズ
      final sanitizedPreview = SecurityValidator.sanitizeHtml(commentPreview);
      final truncated = sanitizedPreview.length > 50 
          ? '${sanitizedPreview.substring(0, 50)}...' 
          : sanitizedPreview;
      message += ': "$truncated"';
    }

    await requestNotificationToUser(
      targetUserId: targetUserId,
      notificationType: 'comment',
      message: message,
      data: {
        'postId': postId,
        'commentId': commentId,
      },
    );
  }

  /// フォロー通知の作成
  Future<void> createFollowNotification({
    required String targetUserId,
  }) async {
    await requestNotificationToUser(
      targetUserId: targetUserId,
      notificationType: 'follow',
      message: 'あなたをフォローしました',
      data: {},
    );
  }

  /// メンション通知の作成
  Future<void> createMentionNotification({
    required String targetUserId,
    required String postId,
  }) async {
    await requestNotificationToUser(
      targetUserId: targetUserId,
      notificationType: 'mention',
      message: 'あなたがメンションされました',
      data: {'postId': postId},
    );
  }

  /// 返信通知の作成
  Future<void> createReplyNotification({
    required String targetUserId,
    required String originalPostId,
    required String replyPostId,
  }) async {
    await requestNotificationToUser(
      targetUserId: targetUserId,
      notificationType: 'reply',
      message: 'あなたの投稿に返信がありました',
      data: {
        'originalPostId': originalPostId,
        'replyPostId': replyPostId,
      },
    );
  }

  /// リポスト通知の作成
  Future<void> createRepostNotification({
    required String targetUserId,
    required String originalPostId,
    required String repostId,
  }) async {
    await requestNotificationToUser(
      targetUserId: targetUserId,
      notificationType: 'repost',
      message: 'あなたの投稿がリポストされました',
      data: {
        'originalPostId': originalPostId,
        'repostId': repostId,
      },
    );
  }

  /// 投稿関連の通知をリクエスト（後方互換性のため残す）
  Future<void> requestPostNotification({
    required String postId,
    required String postAuthorId,
    required String action, // 'like', 'comment'
    String? commentContent,
  }) async {
    switch (action) {
      case 'like':
        await createLikeNotification(
          targetUserId: postAuthorId,
          postId: postId,
        );
        break;
      case 'comment':
        await createCommentNotification(
          targetUserId: postAuthorId,
          postId: postId,
          commentId: '', // 既存コード用のデフォルト
          commentPreview: commentContent,
        );
        break;
      default:
        // 既存のロジックにフォールバック
        await requestNotificationToUser(
          targetUserId: postAuthorId,
          notificationType: action,
          message: 'あなたの投稿に反応しました',
          data: {'postId': postId},
        );
    }
  }
}

