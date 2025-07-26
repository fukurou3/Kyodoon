import 'package:cloud_firestore/cloud_firestore.dart';

/// セキュアな通知エンティティ
class SecureNotification {
  final String id;
  final String type;
  final String userId;
  final String? fromUserId;
  final String message;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;

  const SecureNotification({
    required this.id,
    required this.type,
    required this.userId,
    this.fromUserId,
    required this.message,
    required this.metadata,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
  });

  /// Firestoreドキュメントから SecureNotification を作成
  factory SecureNotification.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('通知データが見つかりません');
    }

    return SecureNotification(
      id: doc.id,
      type: data['type'] as String,
      userId: data['userId'] as String,
      fromUserId: data['fromUserId'] as String?,
      message: data['message'] as String,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestore用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'userId': userId,
      if (fromUserId != null) 'fromUserId': fromUserId,
      'message': message,
      'metadata': metadata,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
    };
  }

  /// 通知を既読にマークしたコピーを作成
  SecureNotification markAsRead() {
    final now = DateTime.now();
    return SecureNotification(
      id: id,
      type: type,
      userId: userId,
      fromUserId: fromUserId,
      message: message,
      metadata: metadata,
      isRead: true,
      createdAt: createdAt,
      updatedAt: now,
      readAt: now,
    );
  }

  /// 通知の優先度を取得
  String get priority {
    return metadata['priority'] as String? ?? 'medium';
  }

  /// 通知が高優先度かチェック
  bool get isHighPriority {
    return priority == 'high';
  }

  /// 通知タイプに基づくアイコンを取得
  String get iconType {
    switch (type) {
      case 'like':
        return '👍';
      case 'comment':
        return '💬';
      case 'follow':
        return '👤';
      case 'mention':
        return '@';
      case 'reply':
        return '↪️';
      case 'repost':
        return '🔄';
      default:
        return '📢';
    }
  }

  /// 関連するリソースIDを取得（投稿ID、コメントIDなど）
  String? get relatedResourceId {
    return metadata['postId'] as String? ?? 
           metadata['commentId'] as String? ?? 
           metadata['userId'] as String?;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecureNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SecureNotification(id: $id, type: $type, message: $message, isRead: $isRead)';
  }
}