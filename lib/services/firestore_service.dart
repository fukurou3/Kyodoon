import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_models.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import '../utils/security_validator.dart';
import '../utils/rate_limiter.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // カジュアル投稿の取得
  static Stream<List<PostModel>> getCasualPosts({int limit = 50}) {
    return _firestore
        .collection('posts')
        .where('type', isEqualTo: 'casual')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  // 真剣投稿の取得
  static Stream<List<PostModel>> getSeriousPosts({int limit = 50}) {
    return _firestore
        .collection('posts')
        .where('type', isEqualTo: 'serious')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }


  // 投稿の作成
  static Future<AppResult<void>> createPost(PostModel post) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AppResult.error('ユーザーがログインしていません');
      }

      // レート制限チェック
      final rateLimitResult = await RateLimiter.checkUserLimit('post_create', user.uid);
      if (!rateLimitResult.allowed) {
        AppLogger.warning('投稿レート制限', {
          'userId': user.uid,
          'reason': rateLimitResult.reason,
          'remainingTime': rateLimitResult.remainingTime,
        });
        return AppResult.error(rateLimitResult.message);
      }

      // 入力検証
      final validationResult = SecurityValidator.validatePostContent(post.content);
      if (!validationResult.isValid) {
        return AppResult.error(validationResult.errorMessage ?? '投稿内容が無効です');
      }

      // コンテンツをサニタイズ
      final sanitizedContent = SecurityValidator.sanitizeHtml(post.content);

      // ユーザー情報を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      // 投稿データを作成（サニタイズされたコンテンツを使用）
      final postData = post.toFirestore();
      postData['content'] = sanitizedContent; // サニタイズされたコンテンツを使用
      postData['authorId'] = user.uid;
      postData['authorName'] = userName;
      postData['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('posts').add(postData);
      return AppResult.success(null);
    } catch (e) {
      AppLogger.firestore('create', 'posts', error: e);
      return AppResult.fromError(e, context: '投稿作成');
    }
  }

  // カジュアル投稿の作成
  static Future<AppResult<void>> createCasualPost(String content, {bool isAnnouncement = false}) async {
    // 事前検証（createPostでも行うが、早期にエラーを検出）
    final validationResult = SecurityValidator.validatePostContent(content);
    if (!validationResult.isValid) {
      return AppResult.error(validationResult.errorMessage ?? '投稿内容が無効です');
    }

    final post = PostModel(
      id: '',
      type: PostType.casual,
      content: content,
      authorId: '',
      authorName: '',
      createdAt: DateTime.now(),
      isAnnouncement: isAnnouncement,
    );
    return await createPost(post);
  }

  // 真剣投稿の作成
  static Future<AppResult<void>> createSeriousPost({
    required String title,
    required String content,
    LocationType? locationType,
    String? municipality,
    bool isAnnouncement = false,
  }) async {
    // タイトルの検証
    if (title.isEmpty || title.length > 100) {
      return AppResult.error('タイトルは1〜100文字で入力してください');
    }
    
    // タイトルのXSSチェック
    if (SecurityValidator.containsXssThreats(title)) {
      return AppResult.error('タイトルに不正なコンテンツが検出されました');
    }

    // コンテンツの事前検証
    final validationResult = SecurityValidator.validatePostContent(content);
    if (!validationResult.isValid) {
      return AppResult.error(validationResult.errorMessage ?? '投稿内容が無効です');
    }

    final post = PostModel(
      id: '',
      type: PostType.serious,
      content: content,
      title: title,
      authorId: '',
      authorName: '',
      createdAt: DateTime.now(),
      locationType: locationType,
      municipality: municipality,
      isAnnouncement: isAnnouncement,
    );
    
    return await createPost(post);
  }

  // デバッグ用：すべての投稿を取得
  static Future<AppResult<List<PostModel>>> getAllPosts() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .limit(100)
          .get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      return AppResult.success(posts);
    } catch (e) {
      AppLogger.firestore('query', 'posts', error: e);
      return AppResult.fromError(e, context: '投稿取得');
    }
  }

  // すべての投稿のストリーム取得
  static Stream<List<PostModel>> getAllPostsStream({int limit = 50}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  // 投稿タイプ別のストリーム取得
  static Stream<QuerySnapshot> getPostsStream(PostType type, {int limit = 50}) {
    String typeString = type == PostType.casual ? 'casual' : 'serious';
    return _firestore
        .collection('posts')
        .where('type', isEqualTo: typeString)
        .limit(limit)
        .snapshots();
  }

  // ユーザーの投稿を取得
  static Future<AppResult<List<PostModel>>> getUserPosts(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      return AppResult.success(posts);
    } catch (e) {
      AppLogger.firestore('query', 'posts', error: e);
      return AppResult.fromError(e, context: 'ユーザー投稿取得');
    }
  }

  // 通知設定を取得
  static Future<AppResult<String>> getNotificationSetting(String currentUserId, String targetUserId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc('${currentUserId}_$targetUserId')
          .get();
      
      if (doc.exists) {
        return AppResult.success(doc.data()?['setting'] ?? 'off');
      }
      return AppResult.success('off');
    } catch (e) {
      AppLogger.firestore('get', 'notifications', error: e);
      return AppResult.fromError(e, context: '通知設定取得');
    }
  }

  // 通知設定を更新
  static Future<AppResult<void>> updateNotificationSetting(String currentUserId, String targetUserId, String setting) async {
    try {
      await _firestore
          .collection('notifications')
          .doc('${currentUserId}_$targetUserId')
          .set({
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
        'setting': setting,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return AppResult.success(null);
    } catch (e) {
      AppLogger.firestore('set', 'notifications', error: e);
      return AppResult.fromError(e, context: '通知設定更新');
    }
  }

}