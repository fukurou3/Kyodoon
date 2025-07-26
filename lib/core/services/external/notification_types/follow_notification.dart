import '../notification_service_factory.dart';

/// フォロー通知専用の処理クラス
class FollowNotificationHandler {
  /// フォロー通知のデータを作成
  static Map<String, dynamic> createNotificationData({
    required String targetUserId,
    String? customMessage,
    Map<String, dynamic>? additionalData,
  }) {
    return {
      'targetUserId': targetUserId,
      'type': 'follow',
      'message': customMessage ?? NotificationServiceFactory.getDefaultMessage('follow'),
      'metadata': {
        'notificationType': 'follow',
        'priority': NotificationServiceFactory.getNotificationPriority('follow'),
        ...?additionalData,
      },
    };
  }

  /// フォロー通知のバリデーション
  static bool validateFollowNotification({
    required String targetUserId,
  }) {
    if (targetUserId.isEmpty) {
      return false;
    }

    return NotificationServiceFactory.validateNotificationData(
      targetUserId: targetUserId,
      notificationType: 'follow',
      message: NotificationServiceFactory.getDefaultMessage('follow'),
      data: {},
    );
  }
}