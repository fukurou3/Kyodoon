/// 投稿タイプ列挙型
enum PostType { casual, serious }

/// 地域タイプ列挙型
enum LocationType { municipality }

/// 投稿エンティティ
/// 
/// ドメイン層の投稿表現
class PostEntity {
  final String id;
  final PostType type;
  final String content;
  final String? title; // 真剣投稿のみ
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final LocationType? locationType;
  final String? municipality;
  final bool isAnnouncement;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final bool isDeleted;

  const PostEntity({
    required this.id,
    required this.type,
    required this.content,
    this.title,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.locationType,
    this.municipality,
    this.isAnnouncement = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.isDeleted = false,
  });

  /// コピーを作成
  PostEntity copyWith({
    String? id,
    PostType? type,
    String? content,
    String? title,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    LocationType? locationType,
    String? municipality,
    bool? isAnnouncement,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    bool? isDeleted,
  }) {
    return PostEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationType: locationType ?? this.locationType,
      municipality: municipality ?? this.municipality,
      isAnnouncement: isAnnouncement ?? this.isAnnouncement,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// いいね済みかどうか
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  /// 投稿者かどうか
  bool isAuthor(String userId) {
    return authorId == userId;
  }

  /// 編集可能かどうか
  bool canEdit(String userId) {
    return isAuthor(userId) && !isDeleted;
  }

  /// 削除可能かどうか
  bool canDelete(String userId) {
    return isAuthor(userId) && !isDeleted;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostEntity &&
        other.id == id &&
        other.type == type &&
        other.content == content &&
        other.title == title &&
        other.authorId == authorId &&
        other.authorName == authorName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.locationType == locationType &&
        other.municipality == municipality &&
        other.isAnnouncement == isAnnouncement &&
        other.likesCount == likesCount &&
        other.commentsCount == commentsCount &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      content,
      title,
      authorId,
      authorName,
      createdAt,
      updatedAt,
      locationType,
      municipality,
      isAnnouncement,
      likesCount,
      commentsCount,
      isDeleted,
    );
  }

  @override
  String toString() {
    return 'PostEntity(id: $id, type: $type, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}