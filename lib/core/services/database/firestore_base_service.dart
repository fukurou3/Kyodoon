import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../errors/app_exceptions.dart';
import '../../../utils/app_logger.dart';

/// Firestoreの基盤サービス
/// 
/// 共通のFirestore操作を提供
abstract class FirestoreBaseService {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  FirestoreBaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
        firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// 現在のユーザーを取得
  User? get currentUser => firebaseAuth.currentUser;

  /// ログイン状態の確認
  bool get isLoggedIn => firebaseAuth.currentUser != null;

  /// 現在のユーザーIDを取得
  String? get currentUserId => firebaseAuth.currentUser?.uid;

  /// ドキュメントの存在確認
  Future<bool> documentExists(String collection, String documentId) async {
    try {
      final doc = await firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.error('Failed to check document existence: $collection/$documentId', e);
      return false;
    }
  }

  /// バッチ処理の実行
  Future<void> executeBatch(Function(WriteBatch batch) batchFunction) async {
    try {
      final batch = firestore.batch();
      batchFunction(batch);
      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to execute batch operation', e);
      throw DataException('バッチ処理に失敗しました');
    }
  }

  /// トランザクション処理の実行
  Future<T> executeTransaction<T>(
    Future<T> Function(Transaction transaction) transactionFunction,
  ) async {
    try {
      return await firestore.runTransaction(transactionFunction);
    } catch (e) {
      AppLogger.error('Failed to execute transaction', e);
      throw DataException('トランザクション処理に失敗しました');
    }
  }

  /// コレクションの統計情報を取得
  Future<int> getCollectionCount(String collection, {Query<Map<String, dynamic>>? query}) async {
    try {
      final snapshot = await (query ?? firestore.collection(collection)).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get collection count: $collection', e);
      return 0;
    }
  }

  /// 安全なドキュメント参照の取得
  DocumentReference<Map<String, dynamic>> safeDocumentReference(String collection, String documentId) {
    if (documentId.isEmpty) {
      throw ArgumentError('Document ID cannot be empty');
    }
    return firestore.collection(collection).doc(documentId);
  }

  /// 安全なコレクション参照の取得
  CollectionReference<Map<String, dynamic>> safeCollectionReference(String collection) {
    if (collection.isEmpty) {
      throw ArgumentError('Collection name cannot be empty');
    }
    return firestore.collection(collection);
  }

  /// サーバータイムスタンプを取得
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Firebaseエラーを適切な例外に変換
  Never handleFirestoreError(dynamic error, String context) {
    AppLogger.error('$context failed', error);
    
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          throw PermissionException('権限がありません');
        case 'not-found':
          throw DataException('データが見つかりません');
        case 'unavailable':
          throw NetworkException('サービスが利用できません');
        case 'deadline-exceeded':
          throw NetworkException('接続がタイムアウトしました');
        default:
          throw DataException('$context: ${error.message ?? "不明なエラー"}');
      }
    }
    
    throw DataException(context);
  }
}