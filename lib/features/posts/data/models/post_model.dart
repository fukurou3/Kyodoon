import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/post_entity.dart';

/// 投稿データモデル
/// 
/// Firestoreとの連携用モデル
class PostModel {
  final String id;
  final PostType type;
  final String content;
  final String? title;
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

  const PostModel({
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

  /// FirestoreドキュメントからPostModelを作成
  factory PostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('投稿データが見つかりません');
    }

    return PostModel(
      id: snapshot.id,
      type: data['type'] == 'casual' ? PostType.casual : PostType.serious,
      content: data['content'] ?? '',
      title: data['title'],
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      locationType: data['locationType'] != null ? LocationType.municipality : null,
      municipality: data['municipality'],
      isAnnouncement: data['isAnnouncement'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  /// PostModelをFirestoreドキュメント用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'type': type == PostType.casual ? 'casual' : 'serious',
      'content': content,
      'title': title,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'locationType': locationType?.toString(),
      'municipality': municipality,
      'isAnnouncement': isAnnouncement,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'isDeleted': isDeleted,
    };
  }

  /// PostModelをPostEntityに変換
  PostEntity toEntity() {
    return PostEntity(
      id: id,
      type: type,
      content: content,
      title: title,
      authorId: authorId,
      authorName: authorName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      locationType: locationType,
      municipality: municipality,
      isAnnouncement: isAnnouncement,
      likesCount: likesCount,
      commentsCount: commentsCount,
      likedBy: likedBy,
      isDeleted: isDeleted,
    );
  }

  /// PostEntityからPostModelを作成
  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      id: entity.id,
      type: entity.type,
      content: entity.content,
      title: entity.title,
      authorId: entity.authorId,
      authorName: entity.authorName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      locationType: entity.locationType,
      municipality: entity.municipality,
      isAnnouncement: entity.isAnnouncement,
      likesCount: entity.likesCount,
      commentsCount: entity.commentsCount,
      likedBy: entity.likedBy,
      isDeleted: entity.isDeleted,
    );
  }

  /// コピーを作成
  PostModel copyWith({
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
    return PostModel(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostModel &&
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
    return 'PostModel(id: $id, type: $type, authorName: $authorName)';
  }
}