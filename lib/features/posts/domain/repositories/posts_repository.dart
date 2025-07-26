import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';

/// 投稿リポジトリインターフェース
/// 
/// 投稿に関するデータ操作の抽象化
abstract class PostsRepository {
  /// 投稿一覧を取得（ストリーム）
  /// 
  /// [type] 投稿タイプでフィルタ（null の場合は全タイプ）
  /// [limit] 取得件数制限
  /// [municipality] 自治体でフィルタ
  Stream<List<PostEntity>> getPosts({
    PostType? type,
    int limit = 50,
    String? municipality,
  });

  /// 特定の投稿を取得
  /// 
  /// [postId] 投稿ID
  /// 戻り値: 成功時はPostEntity、存在しない場合はnull
  Future<PostEntity?> getPost(String postId);

  /// ユーザーの投稿一覧を取得
  /// 
  /// [userId] ユーザーID
  /// [limit] 取得件数制限
  Future<List<PostEntity>> getUserPosts(String userId, {int limit = 50});

  /// 投稿を作成
  /// 
  /// [post] 投稿エンティティ
  /// 戻り値: 作成された投稿ID
  Future<String> createPost(PostEntity post);

  /// 投稿を更新
  /// 
  /// [post] 更新する投稿エンティティ
  Future<void> updatePost(PostEntity post);

  /// 投稿を削除
  /// 
  /// [postId] 投稿ID
  Future<void> deletePost(String postId);

  /// 投稿にいいねを追加
  /// 
  /// [postId] 投稿ID
  /// [userId] ユーザーID
  Future<void> likePost(String postId, String userId);

  /// 投稿のいいねを削除
  /// 
  /// [postId] 投稿ID
  /// [userId] ユーザーID
  Future<void> unlikePost(String postId, String userId);

  /// 投稿のコメント一覧を取得
  /// 
  /// [postId] 投稿ID
  /// [limit] 取得件数制限
  Stream<List<CommentEntity>> getComments(String postId, {int limit = 100});

  /// コメントを作成
  /// 
  /// [comment] コメントエンティティ
  /// 戻り値: 作成されたコメントID
  Future<String> createComment(CommentEntity comment);

  /// コメントを更新
  /// 
  /// [comment] 更新するコメントエンティティ
  Future<void> updateComment(CommentEntity comment);

  /// コメントを削除
  /// 
  /// [commentId] コメントID
  Future<void> deleteComment(String commentId);

  /// コメントにいいねを追加
  /// 
  /// [commentId] コメントID
  /// [userId] ユーザーID
  Future<void> likeComment(String commentId, String userId);

  /// コメントのいいねを削除
  /// 
  /// [commentId] コメントID
  /// [userId] ユーザーID
  Future<void> unlikeComment(String commentId, String userId);
}