import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_preferences_entity.dart';

/// ユーザー設定データモデル
/// 
/// Firestoreとの連携用モデル
class UserPreferencesModel {
  final String userId;
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final DisplaySettings display;
  final List<String> blockedUsers;
  final List<String> mutedKeywords;
  final DateTime? updatedAt;

  const UserPreferencesModel({
    required this.userId,
    required this.notifications,
    required this.privacy,
    required this.display,
    this.blockedUsers = const [],
    this.mutedKeywords = const [],
    this.updatedAt,
  });

  /// FirestoreドキュメントからUserPreferencesModelを作成
  factory UserPreferencesModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      // デフォルト設定を返す
      return UserPreferencesModel(
        userId: snapshot.id,
        notifications: const NotificationSettings(),
        privacy: const PrivacySettings(),
        display: const DisplaySettings(),
      );
    }

    return UserPreferencesModel(
      userId: snapshot.id,
      notifications: NotificationSettings.fromMap(data['notifications'] ?? {}),
      privacy: PrivacySettings.fromMap(data['privacy'] ?? {}),
      display: DisplaySettings.fromMap(data['display'] ?? {}),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      mutedKeywords: List<String>.from(data['mutedKeywords'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// UserPreferencesModelをFirestoreドキュメント用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'notifications': notifications.toMap(),
      'privacy': privacy.toMap(),
      'display': display.toMap(),
      'blockedUsers': blockedUsers,
      'mutedKeywords': mutedKeywords,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// UserPreferencesModelをUserPreferencesEntityに変換
  UserPreferencesEntity toEntity() {
    return UserPreferencesEntity(
      userId: userId,
      notifications: notifications,
      privacy: privacy,
      display: display,
      blockedUsers: blockedUsers,
      mutedKeywords: mutedKeywords,
      updatedAt: updatedAt,
    );
  }

  /// UserPreferencesEntityからUserPreferencesModelを作成
  factory UserPreferencesModel.fromEntity(UserPreferencesEntity entity) {
    return UserPreferencesModel(
      userId: entity.userId,
      notifications: entity.notifications,
      privacy: entity.privacy,
      display: entity.display,
      blockedUsers: entity.blockedUsers,
      mutedKeywords: entity.mutedKeywords,
      updatedAt: entity.updatedAt,
    );
  }

  /// デフォルト設定でUserPreferencesModelを作成
  factory UserPreferencesModel.defaultSettings(String userId) {
    return UserPreferencesModel(
      userId: userId,
      notifications: const NotificationSettings(),
      privacy: const PrivacySettings(),
      display: const DisplaySettings(),
    );
  }

  /// コピーを作成
  UserPreferencesModel copyWith({
    String? userId,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    DisplaySettings? display,
    List<String>? blockedUsers,
    List<String>? mutedKeywords,
    DateTime? updatedAt,
  }) {
    return UserPreferencesModel(
      userId: userId ?? this.userId,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      display: display ?? this.display,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      mutedKeywords: mutedKeywords ?? this.mutedKeywords,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferencesModel &&
        other.userId == userId &&
        other.notifications == notifications &&
        other.privacy == privacy &&
        other.display == display &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      notifications,
      privacy,
      display,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserPreferencesModel(userId: $userId)';
  }
}