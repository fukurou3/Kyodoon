/// コメントエンティティ
/// 
/// ドメイン層のコメント表現
class CommentEntity {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final int likesCount;
  final List<String> likedBy;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.likesCount = 0,
    this.likedBy = const [],
  });

  /// コピーを作成
  CommentEntity copyWith({
    String? id,
    String? postId,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    int? likesCount,
    List<String>? likedBy,
  }) {
    return CommentEntity(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  /// いいね済みかどうか
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  /// コメント投稿者かどうか
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
    return other is CommentEntity &&
        other.id == id &&
        other.postId == postId &&
        other.content == content &&
        other.authorId == authorId &&
        other.authorName == authorName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDeleted == isDeleted &&
        other.likesCount == likesCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      postId,
      content,
      authorId,
      authorName,
      createdAt,
      updatedAt,
      isDeleted,
      likesCount,
    );
  }

  @override
  String toString() {
    return 'CommentEntity(id: $id, postId: $postId, authorName: $authorName)';
  }
}