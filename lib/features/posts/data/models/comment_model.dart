import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/comment_entity.dart';

/// コメントデータモデル
/// 
/// Firestoreとの連携用モデル
class CommentModel {
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

  const CommentModel({
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

  /// FirestoreドキュメントからCommentModelを作成
  factory CommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('コメントデータが見つかりません');
    }

    return CommentModel(
      id: snapshot.id,
      postId: data['postId'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  /// CommentModelをFirestoreドキュメント用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isDeleted': isDeleted,
      'likesCount': likesCount,
      'likedBy': likedBy,
    };
  }

  /// CommentModelをCommentEntityに変換
  CommentEntity toEntity() {
    return CommentEntity(
      id: id,
      postId: postId,
      content: content,
      authorId: authorId,
      authorName: authorName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      likesCount: likesCount,
      likedBy: likedBy,
    );
  }

  /// CommentEntityからCommentModelを作成
  factory CommentModel.fromEntity(CommentEntity entity) {
    return CommentModel(
      id: entity.id,
      postId: entity.postId,
      content: entity.content,
      authorId: entity.authorId,
      authorName: entity.authorName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
      likesCount: entity.likesCount,
      likedBy: entity.likedBy,
    );
  }

  /// コピーを作成
  CommentModel copyWith({
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
    return CommentModel(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentModel &&
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
    return 'CommentModel(id: $id, postId: $postId, authorName: $authorName)';
  }
}