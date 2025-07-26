import 'dart:async';

import '../../../utils/app_logger.dart';

/// 通知サービス
/// 
/// プッシュ通知とアプリ内通知を管理
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  String? _fcmToken;
  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _notificationController = StreamController.broadcast();

  /// 通知ストリーム
  Stream<AppNotification> get notificationStream => _notificationController.stream;

  /// 現在の通知一覧
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// 未読通知数
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// 初期化
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Firebase Messaging の初期化（実装省略）
      // await _initializeFirebaseMessaging();
      
      _initialized = true;
      AppLogger.info('NotificationService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize NotificationService', e);
    }
  }

  /// FCMトークンを取得
  Future<String?> getFcmToken() async {
    if (!_initialized) await initialize();
    
    try {
      // Firebase Messaging でトークンを取得（実装省略）
      // _fcmToken = await FirebaseMessaging.instance.getToken();
      // AppLogger.info('FCM token retrieved');
      return _fcmToken;
    } catch (e) {
      AppLogger.error('Failed to get FCM token', e);
      return null;
    }
  }

  /// 通知権限をリクエスト
  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();

    try {
      // Firebase Messaging で権限をリクエスト（実装省略）
      // final settings = await FirebaseMessaging.instance.requestPermission();
      // final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
      
      const granted = true; // 暫定的にtrue
      AppLogger.info('Notification permission granted: $granted');
      return granted;
    } catch (e) {
      AppLogger.error('Failed to request notification permission', e);
      return false;
    }
  }

  /// アプリ内通知を表示
  void showInAppNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.info,
    Map<String, dynamic>? data,
    Duration? autoHide,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      data: data ?? {},
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notification);
    _notificationController.add(notification);

    // 自動非表示のタイマー設定
    if (autoHide != null) {
      Timer(autoHide, () {
        hideNotification(notification.id);
      });
    }

    // 通知数制限（最大100件）
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    AppLogger.debug('In-app notification shown: $title');
  }

  /// 通知を既読にする
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      AppLogger.debug('Notification marked as read: $notificationId');
    }
  }

  /// すべての通知を既読にする
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    AppLogger.debug('All notifications marked as read');
  }

  /// 通知を非表示にする
  void hideNotification(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isVisible: false);
      AppLogger.debug('Notification hidden: $notificationId');
    }
  }

  /// 通知を削除
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    AppLogger.debug('Notification deleted: $notificationId');
  }

  /// すべての通知をクリア
  void clearAllNotifications() {
    _notifications.clear();
    AppLogger.debug('All notifications cleared');
  }

  /// 通知設定を更新
  Future<void> updateNotificationSettings({
    bool? enablePush,
    bool? enableInApp,
    bool? enableSound,
    bool? enableVibration,
  }) async {
    try {
      // 設定をローカルストレージに保存（実装省略）
      AppLogger.info('Notification settings updated');
    } catch (e) {
      AppLogger.error('Failed to update notification settings', e);
    }
  }

  /// 特定の投稿に関する通知を送信
  void notifyAboutPost({
    required String postId,
    required String postTitle,
    required String action,
    required String actorName,
  }) {
    String title;
    String body;

    switch (action) {
      case 'like':
        title = 'いいねがつきました';
        body = '$actorName さんがあなたの投稿「$postTitle」にいいねしました';
        break;
      case 'comment':
        title = 'コメントがつきました';
        body = '$actorName さんがあなたの投稿「$postTitle」にコメントしました';
        break;
      default:
        title = '投稿への反応';
        body = '$actorName さんがあなたの投稿「$postTitle」に反応しました';
    }

    showInAppNotification(
      title: title,
      body: body,
      type: NotificationType.social,
      data: {
        'postId': postId,
        'action': action,
        'actorName': actorName,
      },
      autoHide: const Duration(seconds: 5),
    );
  }

  /// システム通知を送信
  void notifySystemMessage({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    Duration? autoHide,
  }) {
    showInAppNotification(
      title: title,
      body: message,
      type: type,
      autoHide: autoHide,
    );
  }

  /// エラー通知を送信
  void notifyError(String message) {
    showInAppNotification(
      title: 'エラー',
      body: message,
      type: NotificationType.error,
      autoHide: const Duration(seconds: 8),
    );
  }

  /// 成功通知を送信
  void notifySuccess(String message) {
    showInAppNotification(
      title: '成功',
      body: message,
      type: NotificationType.success,
      autoHide: const Duration(seconds: 3),
    );
  }

  /// 警告通知を送信
  void notifyWarning(String message) {
    showInAppNotification(
      title: '警告',
      body: message,
      type: NotificationType.warning,
      autoHide: const Duration(seconds: 5),
    );
  }

  /// リソースを解放
  void dispose() {
    _notificationController.close();
  }
}

/// アプリ内通知クラス
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final bool isVisible;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
    this.isVisible = true,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    bool? isVisible,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.isVisible == isVisible;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, body, type, timestamp, isRead, isVisible);
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}

/// 通知タイプ列挙型
enum NotificationType {
  info('info'),
  success('success'),
  warning('warning'),
  error('error'),
  social('social'),
  system('system');

  const NotificationType(this.value);
  final String value;
}