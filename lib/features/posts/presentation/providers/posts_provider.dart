import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/usecases/posts_usecase.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/app_logger.dart';

/// 投稿プロバイダー
/// 
/// Clean Architectureのプレゼンテーション層
class PostsProvider extends ChangeNotifier {
  final PostsUseCase _postsUseCase;

  List<PostEntity> _posts = [];
  PostType? _selectedType;
  String? _selectedMunicipality;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<PostEntity>>? _postsSubscription;

  PostsProvider(this._postsUseCase) {
    _loadPosts();
  }

  /// 投稿一覧
  List<PostEntity> get posts => _posts;

  /// 選択されている投稿タイプ
  PostType? get selectedType => _selectedType;

  /// 選択されている自治体
  String? get selectedMunicipality => _selectedMunicipality;

  /// ローディング状態
  bool get isLoading => _isLoading;

  /// エラーメッセージ
  String? get errorMessage => _errorMessage;

  /// エラークリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 投稿タイプフィルターを設定
  void setTypeFilter(PostType? type) {
    if (_selectedType != type) {
      _selectedType = type;
      _loadPosts();
      notifyListeners();
    }
  }

  /// 自治体フィルターを設定
  void setMunicipalityFilter(String? municipality) {
    if (_selectedMunicipality != municipality) {
      _selectedMunicipality = municipality;
      _loadPosts();
      notifyListeners();
    }
  }

  /// 投稿一覧をリロード
  void reloadPosts() {
    _loadPosts();
  }

  /// 投稿一覧を読み込み
  void _loadPosts() {
    _postsSubscription?.cancel();
    
    _postsSubscription = _postsUseCase.getPosts(
      type: _selectedType,
      municipality: _selectedMunicipality,
    ).listen(
      (posts) {
        _posts = posts;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _handleError('投稿の取得に失敗しました', error);
      },
    );

    _setLoading(true);
  }

  /// 投稿を作成
  Future<bool> createPost({
    required PostType type,
    required String content,
    String? title,
    String? municipality,
    bool isAnnouncement = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final postId = await _postsUseCase.createPost(
        type: type,
        content: content,
        title: title,
        municipality: municipality,
        isAnnouncement: isAnnouncement,
      );

      AppLogger.info('Post created successfully: $postId');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } on RateLimitException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('投稿の作成に失敗しました');
      AppLogger.error('Failed to create post', e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// 投稿を更新
  Future<bool> updatePost({
    required String postId,
    required String content,
    String? title,
    String? municipality,
    bool? isAnnouncement,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _postsUseCase.updatePost(
        postId: postId,
        content: content,
        title: title,
        municipality: municipality,
        isAnnouncement: isAnnouncement,
      );

      AppLogger.info('Post updated successfully: $postId');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } on DataException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('投稿の更新に失敗しました');
      AppLogger.error('Failed to update post: $postId', e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// 投稿を削除
  Future<bool> deletePost(String postId) async {
    _setLoading(true);
    _clearError();

    try {
      await _postsUseCase.deletePost(postId);
      AppLogger.info('Post deleted successfully: $postId');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('投稿の削除に失敗しました');
      AppLogger.error('Failed to delete post: $postId', e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// 投稿のいいねを切り替え
  Future<bool> togglePostLike(String postId, String userId) async {
    try {
      await _postsUseCase.togglePostLike(postId, userId);
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on DataException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('いいねの更新に失敗しました');
      AppLogger.error('Failed to toggle post like: $postId', e);
      return false;
    }
  }

  /// ローディング状態の設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// エラー設定
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  /// エラークリア
  void _clearError() {
    _errorMessage = null;
  }

  /// エラーハンドリング
  void _handleError(String message, dynamic error) {
    AppLogger.error(message, error);
    _setError(message);
  }

  /// カジュアル投稿の作成
  Future<bool> createCasualPost(String content, {bool isAnnouncement = false}) async {
    return await createPost(
      type: PostType.casual,
      content: content,
      isAnnouncement: isAnnouncement,
    );
  }

  /// 真剣投稿の作成
  Future<bool> createSeriousPost({
    required String title,
    required String content,
    String? municipality,
    bool isAnnouncement = false,
  }) async {
    return await createPost(
      type: PostType.serious,
      content: content,
      title: title,
      municipality: municipality,
      isAnnouncement: isAnnouncement,
    );
  }

  /// 全投稿のストリーム
  Stream<List<PostEntity>> getAllPostsStream() {
    return _postsUseCase.getPosts();
  }

  /// タイプ別投稿のストリーム  
  Stream<List<PostEntity>> getPostsStream(PostType type) {
    return _postsUseCase.getPosts(type: type);
  }

  /// カジュアル投稿のストリーム
  Stream<List<PostEntity>> getCasualPosts({int limit = 50}) {
    return _postsUseCase.getPosts(type: PostType.casual, limit: limit);
  }

  /// 真剣投稿のストリーム
  Stream<List<PostEntity>> getSeriousPosts({int limit = 50}) {
    return _postsUseCase.getPosts(type: PostType.serious, limit: limit);
  }

  /// ユーザーの投稿を取得
  Future<List<PostEntity>> getUserPosts(String userId) async {
    return await _postsUseCase.getUserPosts(userId);
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }
}

/// 投稿詳細プロバイダー
/// 
/// 個別投稿の詳細表示とコメント管理
class PostDetailProvider extends ChangeNotifier {
  final PostsUseCase _postsUseCase;

  PostEntity? _post;
  List<CommentEntity> _comments = [];
  bool _isLoading = false;
  bool _isCommentsLoading = false;
  String? _errorMessage;

  StreamSubscription<List<CommentEntity>>? _commentsSubscription;

  PostDetailProvider(this._postsUseCase);

  /// 投稿
  PostEntity? get post => _post;

  /// コメント一覧
  List<CommentEntity> get comments => _comments;

  /// ローディング状態
  bool get isLoading => _isLoading;

  /// コメントローディング状態
  bool get isCommentsLoading => _isCommentsLoading;

  /// エラーメッセージ
  String? get errorMessage => _errorMessage;

  /// エラークリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 投稿を読み込み
  Future<void> loadPost(String postId) async {
    _setLoading(true);
    _clearError();

    try {
      final post = await _postsUseCase.getPost(postId);
      if (post == null) {
        _setError('投稿が見つかりません');
        return;
      }

      _post = post;
      _loadComments(postId);

    } catch (e) {
      _handleError('投稿の取得に失敗しました', e);
    } finally {
      _setLoading(false);
    }
  }

  /// コメントを読み込み
  void _loadComments(String postId) {
    _commentsSubscription?.cancel();
    
    _setCommentsLoading(true);
    
    _commentsSubscription = _postsUseCase.getComments(postId).listen(
      (comments) {
        _comments = comments;
        _isCommentsLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _handleError('コメントの取得に失敗しました', error);
        _isCommentsLoading = false;
        notifyListeners();
      },
    );
  }

  /// コメントを作成
  Future<bool> createComment({
    required String postId,
    required String content,
  }) async {
    _clearError();

    try {
      final commentId = await _postsUseCase.createComment(
        postId: postId,
        content: content,
      );

      AppLogger.info('Comment created successfully: $commentId');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } on RateLimitException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('コメントの作成に失敗しました');
      AppLogger.error('Failed to create comment', e);
      return false;
    }
  }

  /// コメントを更新
  Future<bool> updateComment({
    required String commentId,
    required String content,
  }) async {
    _clearError();

    try {
      await _postsUseCase.updateComment(
        commentId: commentId,
        content: content,
      );

      AppLogger.info('Comment updated successfully: $commentId');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('コメントの更新に失敗しました');
      AppLogger.error('Failed to update comment: $commentId', e);
      return false;
    }
  }

  /// コメントを削除
  Future<bool> deleteComment(String commentId) async {
    _clearError();

    try {
      await _postsUseCase.deleteComment(commentId);
      AppLogger.info('Comment deleted successfully: $commentId');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('コメントの削除に失敗しました');
      AppLogger.error('Failed to delete comment: $commentId', e);
      return false;
    }
  }

  /// コメントのいいねを切り替え
  Future<bool> toggleCommentLike(String commentId, String userId) async {
    try {
      await _postsUseCase.toggleCommentLike(commentId, userId);
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('いいねの更新に失敗しました');
      AppLogger.error('Failed to toggle comment like: $commentId', e);
      return false;
    }
  }

  /// ローディング状態の設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// コメントローディング状態の設定
  void _setCommentsLoading(bool loading) {
    _isCommentsLoading = loading;
  }

  /// エラー設定
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// エラークリア
  void _clearError() {
    _errorMessage = null;
  }

  /// エラーハンドリング
  void _handleError(String message, dynamic error) {
    AppLogger.error(message, error);
    _setError(message);
  }

  @override
  void dispose() {
    _commentsSubscription?.cancel();
    super.dispose();
  }
}