/// 通知サービスのファクトリクラス
/// 異なる通知タイプに応じて適切な処理を提供
class NotificationServiceFactory {
  static const Map<String, String> _notificationMessages = {
    'like': 'あなたの投稿にいいねしました',
    'comment': 'あなたの投稿にコメントしました',
    'follow': 'あなたをフォローしました',
    'mention': 'あなたがメンションされました',
    'reply': 'あなたのコメントに返信しました',
    'repost': 'あなたの投稿をリポストしました',
  };

  /// 通知タイプに基づいてデフォルトメッセージを取得
  static String getDefaultMessage(String notificationType) {
    return _notificationMessages[notificationType] ?? '新しい通知があります';
  }

  /// 通知データのバリデーション
  static bool validateNotificationData({
    required String targetUserId,
    required String notificationType,
    required String message,
    Map<String, dynamic>? data,
  }) {
    // 基本バリデーション
    if (targetUserId.isEmpty || notificationType.isEmpty || message.isEmpty) {
      return false;
    }

    // 通知タイプの妥当性チェック
    if (!_notificationMessages.containsKey(notificationType)) {
      return false;
    }

    // メッセージ長制限（500文字）
    if (message.length > 500) {
      return false;
    }

    // 特定の通知タイプに必要なデータの確認
    if (data != null) {
      switch (notificationType) {
        case 'like':
        case 'comment':
        case 'repost':
          return data.containsKey('postId') && data['postId'].toString().isNotEmpty;
        case 'reply':
          return data.containsKey('commentId') && data['commentId'].toString().isNotEmpty;
        default:
          return true;
      }
    }

    return true;
  }

  /// 通知タイプに基づく優先度の決定
  static String getNotificationPriority(String notificationType) {
    switch (notificationType) {
      case 'mention':
      case 'reply':
        return 'high';
      case 'like':
      case 'follow':
        return 'medium';
      case 'comment':
      case 'repost':
        return 'low';
      default:
        return 'medium';
    }
  }
}