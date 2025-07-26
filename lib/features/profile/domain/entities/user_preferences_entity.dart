/// ユーザー設定エンティティ
/// 
/// ドメイン層のユーザー設定表現
class UserPreferencesEntity {
  final String userId;
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final DisplaySettings display;
  final List<String> blockedUsers;
  final List<String> mutedKeywords;
  final DateTime? updatedAt;

  const UserPreferencesEntity({
    required this.userId,
    required this.notifications,
    required this.privacy,
    required this.display,
    this.blockedUsers = const [],
    this.mutedKeywords = const [],
    this.updatedAt,
  });

  /// コピーを作成
  UserPreferencesEntity copyWith({
    String? userId,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    DisplaySettings? display,
    List<String>? blockedUsers,
    List<String>? mutedKeywords,
    DateTime? updatedAt,
  }) {
    return UserPreferencesEntity(
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
    return other is UserPreferencesEntity &&
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
    return 'UserPreferencesEntity(userId: $userId)';
  }
}

/// 通知設定
class NotificationSettings {
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool notifyOnNewPosts;
  final bool notifyOnComments;
  final bool notifyOnLikes;
  final bool notifyOnMentions;

  const NotificationSettings({
    this.enablePushNotifications = true,
    this.enableEmailNotifications = false,
    this.notifyOnNewPosts = true,
    this.notifyOnComments = true,
    this.notifyOnLikes = false,
    this.notifyOnMentions = true,
  });

  NotificationSettings copyWith({
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? notifyOnNewPosts,
    bool? notifyOnComments,
    bool? notifyOnLikes,
    bool? notifyOnMentions,
  }) {
    return NotificationSettings(
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      notifyOnNewPosts: notifyOnNewPosts ?? this.notifyOnNewPosts,
      notifyOnComments: notifyOnComments ?? this.notifyOnComments,
      notifyOnLikes: notifyOnLikes ?? this.notifyOnLikes,
      notifyOnMentions: notifyOnMentions ?? this.notifyOnMentions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'notifyOnNewPosts': notifyOnNewPosts,
      'notifyOnComments': notifyOnComments,
      'notifyOnLikes': notifyOnLikes,
      'notifyOnMentions': notifyOnMentions,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enablePushNotifications: map['enablePushNotifications'] ?? true,
      enableEmailNotifications: map['enableEmailNotifications'] ?? false,
      notifyOnNewPosts: map['notifyOnNewPosts'] ?? true,
      notifyOnComments: map['notifyOnComments'] ?? true,
      notifyOnLikes: map['notifyOnLikes'] ?? false,
      notifyOnMentions: map['notifyOnMentions'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettings &&
        other.enablePushNotifications == enablePushNotifications &&
        other.enableEmailNotifications == enableEmailNotifications &&
        other.notifyOnNewPosts == notifyOnNewPosts &&
        other.notifyOnComments == notifyOnComments &&
        other.notifyOnLikes == notifyOnLikes &&
        other.notifyOnMentions == notifyOnMentions;
  }

  @override
  int get hashCode {
    return Object.hash(
      enablePushNotifications,
      enableEmailNotifications,
      notifyOnNewPosts,
      notifyOnComments,
      notifyOnLikes,
      notifyOnMentions,
    );
  }
}

/// プライバシー設定
class PrivacySettings {
  final bool profileIsPublic;
  final bool showEmail;
  final bool showLastLogin;
  final bool allowDirectMessages;
  final bool showActivityStatus;

  const PrivacySettings({
    this.profileIsPublic = true,
    this.showEmail = false,
    this.showLastLogin = false,
    this.allowDirectMessages = true,
    this.showActivityStatus = true,
  });

  PrivacySettings copyWith({
    bool? profileIsPublic,
    bool? showEmail,
    bool? showLastLogin,
    bool? allowDirectMessages,
    bool? showActivityStatus,
  }) {
    return PrivacySettings(
      profileIsPublic: profileIsPublic ?? this.profileIsPublic,
      showEmail: showEmail ?? this.showEmail,
      showLastLogin: showLastLogin ?? this.showLastLogin,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileIsPublic': profileIsPublic,
      'showEmail': showEmail,
      'showLastLogin': showLastLogin,
      'allowDirectMessages': allowDirectMessages,
      'showActivityStatus': showActivityStatus,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      profileIsPublic: map['profileIsPublic'] ?? true,
      showEmail: map['showEmail'] ?? false,
      showLastLogin: map['showLastLogin'] ?? false,
      allowDirectMessages: map['allowDirectMessages'] ?? true,
      showActivityStatus: map['showActivityStatus'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivacySettings &&
        other.profileIsPublic == profileIsPublic &&
        other.showEmail == showEmail &&
        other.showLastLogin == showLastLogin &&
        other.allowDirectMessages == allowDirectMessages &&
        other.showActivityStatus == showActivityStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      profileIsPublic,
      showEmail,
      showLastLogin,
      allowDirectMessages,
      showActivityStatus,
    );
  }
}

/// 表示設定
class DisplaySettings {
  final String language;
  final String theme;
  final int postsPerPage;
  final bool showImages;
  final bool autoRefresh;

  const DisplaySettings({
    this.language = 'ja',
    this.theme = 'system',
    this.postsPerPage = 20,
    this.showImages = true,
    this.autoRefresh = true,
  });

  DisplaySettings copyWith({
    String? language,
    String? theme,
    int? postsPerPage,
    bool? showImages,
    bool? autoRefresh,
  }) {
    return DisplaySettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      postsPerPage: postsPerPage ?? this.postsPerPage,
      showImages: showImages ?? this.showImages,
      autoRefresh: autoRefresh ?? this.autoRefresh,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'theme': theme,
      'postsPerPage': postsPerPage,
      'showImages': showImages,
      'autoRefresh': autoRefresh,
    };
  }

  factory DisplaySettings.fromMap(Map<String, dynamic> map) {
    return DisplaySettings(
      language: map['language'] ?? 'ja',
      theme: map['theme'] ?? 'system',
      postsPerPage: map['postsPerPage'] ?? 20,
      showImages: map['showImages'] ?? true,
      autoRefresh: map['autoRefresh'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplaySettings &&
        other.language == language &&
        other.theme == theme &&
        other.postsPerPage == postsPerPage &&
        other.showImages == showImages &&
        other.autoRefresh == autoRefresh;
  }

  @override
  int get hashCode {
    return Object.hash(
      language,
      theme,
      postsPerPage,
      showImages,
      autoRefresh,
    );
  }
}