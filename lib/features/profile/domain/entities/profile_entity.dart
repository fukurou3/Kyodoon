/// プロフィールエンティティ
/// 
/// ドメイン層のユーザープロフィール表現
class ProfileEntity {
  final String userId;
  final String email;
  final String? displayName;
  final String? bio;
  final String? photoUrl;
  final String? municipality;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final int postsCount;
  final int likesGivenCount;
  final int likesReceivedCount;
  final bool isPublic;
  final bool isEmailVerified;

  const ProfileEntity({
    required this.userId,
    required this.email,
    this.displayName,
    this.bio,
    this.photoUrl,
    this.municipality,
    this.interests = const [],
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.postsCount = 0,
    this.likesGivenCount = 0,
    this.likesReceivedCount = 0,
    this.isPublic = true,
    this.isEmailVerified = false,
  });

  /// コピーを作成
  ProfileEntity copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? bio,
    String? photoUrl,
    String? municipality,
    List<String>? interests,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    int? postsCount,
    int? likesGivenCount,
    int? likesReceivedCount,
    bool? isPublic,
    bool? isEmailVerified,
  }) {
    return ProfileEntity(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      municipality: municipality ?? this.municipality,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      postsCount: postsCount ?? this.postsCount,
      likesGivenCount: likesGivenCount ?? this.likesGivenCount,
      likesReceivedCount: likesReceivedCount ?? this.likesReceivedCount,
      isPublic: isPublic ?? this.isPublic,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  /// 表示名を取得（displayNameがない場合はemailの@マーク前を使用）
  String get effectiveDisplayName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return email.split('@').first;
  }

  /// プロフィールが完成しているかどうか
  bool get isProfileComplete {
    return displayName != null &&
           displayName!.isNotEmpty &&
           municipality != null &&
           municipality!.isNotEmpty;
  }

  /// 活動レベルを計算（投稿数とスコア数から）
  ActivityLevel get activityLevel {
    final totalActivity = postsCount + likesGivenCount + likesReceivedCount;
    
    if (totalActivity >= 100) return ActivityLevel.veryActive;
    if (totalActivity >= 50) return ActivityLevel.active;
    if (totalActivity >= 10) return ActivityLevel.moderate;
    if (totalActivity > 0) return ActivityLevel.beginner;
    return ActivityLevel.newUser;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileEntity &&
        other.userId == userId &&
        other.email == email &&
        other.displayName == displayName &&
        other.bio == bio &&
        other.photoUrl == photoUrl &&
        other.municipality == municipality &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastLoginAt == lastLoginAt &&
        other.postsCount == postsCount &&
        other.likesGivenCount == likesGivenCount &&
        other.likesReceivedCount == likesReceivedCount &&
        other.isPublic == isPublic &&
        other.isEmailVerified == isEmailVerified;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      email,
      displayName,
      bio,
      photoUrl,
      municipality,
      createdAt,
      updatedAt,
      lastLoginAt,
      postsCount,
      likesGivenCount,
      likesReceivedCount,
      isPublic,
      isEmailVerified,
    );
  }

  @override
  String toString() {
    return 'ProfileEntity(userId: $userId, displayName: $displayName, municipality: $municipality)';
  }
}

/// 活動レベル列挙型
enum ActivityLevel {
  newUser('新規ユーザー'),
  beginner('初心者'),
  moderate('中級者'),
  active('活発ユーザー'),
  veryActive('とても活発');

  const ActivityLevel(this.displayName);
  final String displayName;
}