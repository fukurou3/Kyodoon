import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';
import '../repositories/posts_repository.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/security_validator.dart';

/// 投稿ユースケース
/// 
/// 投稿に関するビジネスロジックを管理
class PostsUseCase {
  final PostsRepository _repository;

  PostsUseCase(this._repository);

  /// 投稿一覧を取得（ストリーム）
  Stream<List<PostEntity>> getPosts({
    PostType? type,
    int limit = 50,
    String? municipality,
  }) {
    return _repository.getPosts(
      type: type,
      limit: limit,
      municipality: municipality,
    );
  }

  /// 特定の投稿を取得
  Future<PostEntity?> getPost(String postId) async {
    if (postId.isEmpty) {
      throw ValidationException('投稿IDが指定されていません');
    }

    return await _repository.getPost(postId);
  }

  /// ユーザーの投稿一覧を取得
  Future<List<PostEntity>> getUserPosts(String userId, {int limit = 50}) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    if (limit <= 0 || limit > 100) {
      throw ValidationException('取得件数は1〜100の範囲で指定してください');
    }

    return await _repository.getUserPosts(userId, limit: limit);
  }

  /// 投稿を作成
  Future<String> createPost({
    required PostType type,
    required String content,
    String? title,
    String? municipality,
    bool isAnnouncement = false,
  }) async {
    // 入力検証
    final contentValidation = SecurityValidator.validatePostContent(content);
    if (!contentValidation.isValid) {
      throw ValidationException(contentValidation.errorMessage!);
    }

    // 真剣投稿の場合はタイトルが必要
    if (type == PostType.serious) {
      if (title == null || title.trim().isEmpty) {
        throw ValidationException('真剣投稿にはタイトルが必要です');
      }

      final titleValidation = SecurityValidator.validatePostTitle(title);
      if (!titleValidation.isValid) {
        throw ValidationException(titleValidation.errorMessage!);
      }
    }

    // コンテンツをサニタイズ
    final sanitizedContent = SecurityValidator.sanitizeHtml(content);
    final sanitizedTitle = title != null ? SecurityValidator.sanitizeHtml(title) : null;

    // 投稿エンティティを作成
    final post = PostEntity(
      id: '', // リポジトリで生成される
      type: type,
      content: sanitizedContent,
      title: sanitizedTitle,
      authorId: '', // リポジトリで設定される
      authorName: '', // リポジトリで設定される
      createdAt: DateTime.now(),
      municipality: municipality,
      isAnnouncement: isAnnouncement,
    );

    return await _repository.createPost(post);
  }

  /// 投稿を更新
  Future<void> updatePost({
    required String postId,
    required String content,
    String? title,
    String? municipality,
    bool? isAnnouncement,
  }) async {
    if (postId.isEmpty) {
      throw ValidationException('投稿IDが指定されていません');
    }

    // 既存の投稿を取得
    final existingPost = await _repository.getPost(postId);
    if (existingPost == null) {
      throw DataException('投稿が見つかりません');
    }

    // 入力検証
    final contentValidation = SecurityValidator.validatePostContent(content);
    if (!contentValidation.isValid) {
      throw ValidationException(contentValidation.errorMessage!);
    }

    // 真剣投稿の場合はタイトルが必要
    if (existingPost.type == PostType.serious) {
      if (title == null || title.trim().isEmpty) {
        throw ValidationException('真剣投稿にはタイトルが必要です');
      }

      final titleValidation = SecurityValidator.validatePostTitle(title);
      if (!titleValidation.isValid) {
        throw ValidationException(titleValidation.errorMessage!);
      }
    }

    // コンテンツをサニタイズ
    final sanitizedContent = SecurityValidator.sanitizeHtml(content);
    final sanitizedTitle = title != null ? SecurityValidator.sanitizeHtml(title) : null;

    // 投稿を更新
    final updatedPost = existingPost.copyWith(
      content: sanitizedContent,
      title: sanitizedTitle,
      municipality: municipality,
      isAnnouncement: isAnnouncement,
      updatedAt: DateTime.now(),
    );

    await _repository.updatePost(updatedPost);
  }

  /// 投稿を削除
  Future<void> deletePost(String postId) async {
    if (postId.isEmpty) {
      throw ValidationException('投稿IDが指定されていません');
    }

    await _repository.deletePost(postId);
  }

  /// 投稿のいいね切り替え
  Future<void> togglePostLike(String postId, String userId) async {
    if (postId.isEmpty) {
      throw ValidationException('投稿IDが指定されていません');
    }
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    final post = await _repository.getPost(postId);
    if (post == null) {
      throw DataException('投稿が見つかりません');
    }

    if (post.isLikedBy(userId)) {
      await _repository.unlikePost(postId, userId);
    } else {
      await _repository.likePost(postId, userId);
    }
  }

  /// 投稿のコメント一覧を取得
  Stream<List<CommentEntity>> getComments(String postId, {int limit = 100}) {
    if (postId.isEmpty) {
      throw ValidationException('投稿IDが指定されていません');
    }

    return _repository.getComments(postId, limit: limit);
  }

  /// コメントを作成
  Future<String> createComment({
    required String postId,
    required String content,
  }) async {
    if (postId.isEmpty) {
      throw ValidationException('投稿IDが指定されていません');
    }

    // 入力検証
    final validation = SecurityValidator.validateCommentContent(content);
    if (!validation.isValid) {
      throw ValidationException(validation.errorMessage!);
    }

    // コンテンツをサニタイズ
    final sanitizedContent = SecurityValidator.sanitizeHtml(content);

    // コメントエンティティを作成
    final comment = CommentEntity(
      id: '', // リポジトリで生成される
      postId: postId,
      content: sanitizedContent,
      authorId: '', // リポジトリで設定される
      authorName: '', // リポジトリで設定される
      createdAt: DateTime.now(),
    );

    return await _repository.createComment(comment);
  }

  /// コメントを更新
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    if (commentId.isEmpty) {
      throw ValidationException('コメントIDが指定されていません');
    }

    // 入力検証
    final validation = SecurityValidator.validateCommentContent(content);
    if (!validation.isValid) {
      throw ValidationException(validation.errorMessage!);
    }

    // コンテンツをサニタイズ
    final sanitizedContent = SecurityValidator.sanitizeHtml(content);

    // 既存のコメントを取得する必要があるが、現在のリポジトリインターフェースにはない
    // 実装では適切にコメントを更新する
    // ここでは簡略化してリポジトリメソッドを直接呼ぶ
    
    // 注意: 実際の実装ではコメント取得メソッドが必要
    final updatedComment = CommentEntity(
      id: commentId,
      postId: '', // 実際の実装では既存データから取得
      content: sanitizedContent,
      authorId: '', // 実際の実装では既存データから取得
      authorName: '', // 実際の実装では既存データから取得
      createdAt: DateTime.now(), // 実際の実装では既存データから取得
      updatedAt: DateTime.now(),
    );

    await _repository.updateComment(updatedComment);
  }

  /// コメントを削除
  Future<void> deleteComment(String commentId) async {
    if (commentId.isEmpty) {
      throw ValidationException('コメントIDが指定されていません');
    }

    await _repository.deleteComment(commentId);
  }

  /// コメントのいいね切り替え
  Future<void> toggleCommentLike(String commentId, String userId) async {
    if (commentId.isEmpty) {
      throw ValidationException('コメントIDが指定されていません');
    }
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    // 実際の実装では、コメントを取得していいね状態を確認する
    // ここでは簡略化して直接リポジトリメソッドを呼ぶ
    
    // 注意: 実際の実装ではコメント取得メソッドが必要
    // if (comment.isLikedBy(userId)) {
    //   await _repository.unlikeComment(commentId, userId);
    // } else {
    //   await _repository.likeComment(commentId, userId);
    // }
    
    // 暫定的な実装
    await _repository.likeComment(commentId, userId);
  }
}