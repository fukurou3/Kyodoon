import '../notification_service_factory.dart';

/// コメント通知専用の処理クラス
class CommentNotificationHandler {
  /// コメント通知のデータを作成
  static Map<String, dynamic> createNotificationData({
    required String targetUserId,
    required String postId,
    required String commentId,
    String? customMessage,
  }) {
    return {
      'targetUserId': targetUserId,
      'type': 'comment',
      'message': customMessage ?? NotificationServiceFactory.getDefaultMessage('comment'),
      'metadata': {
        'postId': postId,
        'commentId': commentId,
        'notificationType': 'comment',
        'priority': NotificationServiceFactory.getNotificationPriority('comment'),
      },
    };
  }

  /// コメント通知のバリデーション
  static bool validateCommentNotification({
    required String targetUserId,
    required String postId,
    required String commentId,
  }) {
    if (targetUserId.isEmpty || postId.isEmpty || commentId.isEmpty) {
      return false;
    }

    return NotificationServiceFactory.validateNotificationData(
      targetUserId: targetUserId,
      notificationType: 'comment',
      message: NotificationServiceFactory.getDefaultMessage('comment'),
      data: {
        'postId': postId,
        'commentId': commentId,
      },
    );
  }
}