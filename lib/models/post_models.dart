enum PostType { casual, serious }
enum LocationType { municipality }

class PostModel {
  final String id;
  final PostType type;
  final String content;
  final String? title; // 真剣投稿のみ
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final LocationType? locationType;
  final String? municipality;
  final bool isAnnouncement; // 告知フラグ

  const PostModel({
    required this.id,
    required this.type,
    required this.content,
    this.title,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.locationType,
    this.municipality,
    this.isAnnouncement = false,
  });

  factory PostModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PostModel(
      id: id,
      type: data['type'] == 'casual' ? PostType.casual : PostType.serious,
      content: data['content'] ?? '',
      title: data['title'],
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      locationType: data['locationType'] != null 
          ? LocationType.municipality
          : null,
      municipality: data['municipality'],
      isAnnouncement: data['isAnnouncement'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'type': type == PostType.casual ? 'casual' : 'serious',
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt,
      'isAnnouncement': isAnnouncement,
    };

    if (title != null) data['title'] = title;
    if (locationType != null) {
      data['locationType'] = locationType.toString();
    }
    if (municipality != null) data['municipality'] = municipality;

    return data;
  }

  bool get hasLocation => municipality != null;
}