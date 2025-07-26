import '../notification_service_factory.dart';

/// いいね通知専用の処理クラス
class LikeNotificationHandler {
  /// いいね通知のデータを作成
  static Map<String, dynamic> createNotificationData({
    required String targetUserId,
    required String postId,
    String? customMessage,
  }) {
    return {
      'targetUserId': targetUserId,
      'type': 'like',
      'message': customMessage ?? NotificationServiceFactory.getDefaultMessage('like'),
      'metadata': {
        'postId': postId,
        'notificationType': 'like',
        'priority': NotificationServiceFactory.getNotificationPriority('like'),
      },
    };
  }

  /// いいね通知のバリデーション
  static bool validateLikeNotification({
    required String targetUserId,
    required String postId,
  }) {
    if (targetUserId.isEmpty || postId.isEmpty) {
      return false;
    }

    return NotificationServiceFactory.validateNotificationData(
      targetUserId: targetUserId,
      notificationType: 'like',
      message: NotificationServiceFactory.getDefaultMessage('like'),
      data: {'postId': postId},
    );
  }
}