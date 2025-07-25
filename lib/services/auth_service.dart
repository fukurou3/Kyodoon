import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 現在のユーザーのストリーム
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 現在のユーザー
  static User? get currentUser => _auth.currentUser;

  // ログイン状態の確認
  static bool get isLoggedIn => _auth.currentUser != null;

  // 現在のユーザーIDを取得
  static String? getCurrentUserId() => _auth.currentUser?.uid;

  // 現在のユーザーを取得
  static User? getCurrentUser() => _auth.currentUser;

  // ユーザー登録
  static Future<AppResult<UserCredential>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestoreにユーザー情報を保存
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return AppResult.success(result);
    } catch (e) {
      AppLogger.auth('register', error: e);
      return AppResult.fromError(e, context: 'ユーザー登録');
    }
  }

  // ログイン
  static Future<AppResult<UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AppResult.success(result);
    } catch (e) {
      AppLogger.auth('login', error: e);
      return AppResult.fromError(e, context: 'ログイン');
    }
  }

  // ログアウト
  static Future<AppResult<void>> signOut() async {
    try {
      await _auth.signOut();
      return AppResult.success(null);
    } catch (e) {
      AppLogger.auth('logout', error: e);
      return AppResult.fromError(e, context: 'ログアウト');
    }
  }

  // ユーザー情報の取得
  static Future<AppResult<Map<String, dynamic>?>> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return AppResult.success(doc.data() as Map<String, dynamic>?);
    } catch (e) {
      AppLogger.auth('getUserData', error: e);
      return AppResult.fromError(e, context: 'ユーザー情報取得');
    }
  }
}