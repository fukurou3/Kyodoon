import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kyodoon/core/services/external/secure_notification_service.dart';
// import 'package:kyodoon/main.dart' as app; // 未使用のためコメントアウト

/// 通知セキュリティ統合テスト
/// 
/// 実行方法:
/// 1. Firebase Emulators を起動
///    firebase emulators:start --only functions,firestore,auth
/// 
/// 2. テスト実行
///    flutter test integration_test/notification_security_integration_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('通知セキュリティ統合テスト', () {
    late FirebaseFirestore firestore;
    late FirebaseAuth auth;
    late FirebaseFunctions functions;
    late SecureNotificationService notificationService;
    
    late String testUserAliceId;
    late String testUserBobId;

    setUpAll(() async {
      // エミュレータ接続設定
      // Firebase Emulator接続は実際のエミュレータ起動時のみ
      // await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);

      firestore = FirebaseFirestore.instance;
      auth = FirebaseAuth.instance;
      functions = FirebaseFunctions.instance;

      // テストユーザー作成
      final aliceCredential = await auth.createUserWithEmailAndPassword(
        email: 'alice@test.com',
        password: 'testpass123',
      );
      testUserAliceId = aliceCredential.user!.uid;

      final bobCredential = await auth.createUserWithEmailAndPassword(
        email: 'bob@test.com',
        password: 'testpass123',
      );
      testUserBobId = bobCredential.user!.uid;

      // Firestoreにユーザーデータ作成
      await firestore.collection('users').doc(testUserAliceId).set({
        'email': 'alice@test.com',
        'displayName': 'Alice',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('users').doc(testUserBobId).set({
        'email': 'bob@test.com',
        'displayName': 'Bob',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // テスト投稿作成
      await firestore.collection('posts').doc('test-post-1').set({
        'authorId': testUserAliceId,
        'content': 'Aliceのテスト投稿',
        'type': 'casual',
        'createdAt': FieldValue.serverTimestamp(),
      });

      notificationService = SecureNotificationService(
        firestore: firestore,
        auth: auth,
        functions: functions,
      );
    });

    tearDownAll(() async {
      // テストデータクリーンアップ
      await _cleanupTestData(firestore, [testUserAliceId, testUserBobId]);
    });

    testWidgets('自分宛て通知作成のテスト', (tester) async {
      // Given: Aliceでログイン
      await auth.signInWithEmailAndPassword(
        email: 'alice@test.com',
        password: 'testpass123',
      );

      // When: 自分宛て通知を作成
      await notificationService.createSelfNotification(
        type: 'like',
        message: 'テスト通知',
        data: {'test': true},
      );

      // Then: 通知が作成されることを確認
      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: testUserAliceId)
          .get();

      expect(notifications.docs.length, 1);
      final notificationData = notifications.docs.first.data();
      expect(notificationData['type'], 'like');
      expect(notificationData['message'], 'テスト通知');
      expect(notificationData['userId'], testUserAliceId);
    });

    testWidgets('Cloud Function経由の通知作成テスト', (tester) async {
      // Given: Bobでログイン
      await auth.signInWithEmailAndPassword(
        email: 'bob@test.com',
        password: 'testpass123',
      );

      // Given: Bobがtest-post-1にいいね
      await firestore.collection('likes').add({
        'postId': 'test-post-1',
        'userId': testUserBobId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // When: BobがAliceの投稿にいいね通知を送信
      await notificationService.createLikeNotification(
        targetUserId: testUserAliceId,
        postId: 'test-post-1',
      );

      // Then: Cloud Function経由で通知が作成される
      // 注意: 実際のテストではCloud Functionが呼び出される
      await Future.delayed(Duration(seconds: 2)); // Cloud Function実行待ち

      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: testUserAliceId)
          .where('type', isEqualTo: 'like')
          .get();

      expect(notifications.docs.length, greaterThan(0));
    });

    testWidgets('セキュリティルール違反の検出テスト', (tester) async {
      // Given: Bobでログイン
      await auth.signInWithEmailAndPassword(
        email: 'bob@test.com',
        password: 'testpass123',
      );

      // When: Bobが直接Aliceの通知を作成しようとする（違反行為）
      try {
        await firestore.collection('notifications').add({
          'userId': testUserAliceId, // 他ユーザーのID
          'type': 'like',
          'message': '不正な通知',
          'data': {},
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        fail('セキュリティルール違反が検出されるべき');
      } catch (e) {
        // Then: セキュリティルールによって拒否される
        expect(e.toString(), contains('permission-denied'));
      }
    });

    testWidgets('通知の既読状態更新テスト', (tester) async {
      // Given: Aliceでログイン
      await auth.signInWithEmailAndPassword(
        email: 'alice@test.com',
        password: 'testpass123',
      );

      // Given: 未読通知を作成
      final notificationRef = await firestore.collection('notifications').add({
        'userId': testUserAliceId,
        'type': 'comment',
        'message': 'コメント通知',
        'data': {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // When: 通知を既読にする
      await notificationService.markAsRead(notificationRef.id);

      // Then: 既読状態が更新される
      final updatedNotification = await notificationRef.get();
      final data = updatedNotification.data()!;
      expect(data['read'], true);
      expect(data['readAt'], isNotNull);
    });

    testWidgets('他ユーザーの通知への不正アクセステスト', (tester) async {
      // Given: Aliceでログイン
      await auth.signInWithEmailAndPassword(
        email: 'alice@test.com',
        password: 'testpass123',
      );

      // Given: Aliceの通知を作成
      final aliceNotificationRef = await firestore.collection('notifications').add({
        'userId': testUserAliceId,
        'type': 'like',
        'message': 'Aliceの通知',
        'data': {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Given: Bobでログイン
      await auth.signInWithEmailAndPassword(
        email: 'bob@test.com',
        password: 'testpass123',
      );

      // When: BobがAliceの通知を既読にしようとする（不正アクセス）
      try {
        await notificationService.markAsRead(aliceNotificationRef.id);
        fail('不正アクセスが検出されるべき');
      } catch (e) {
        // Then: アクセス権限エラーが発生する
        expect(e.toString(), contains('権限がありません'));
      }
    });

    testWidgets('未読通知数の取得テスト', (tester) async {
      // Given: Aliceでログイン
      await auth.signInWithEmailAndPassword(
        email: 'alice@test.com',
        password: 'testpass123',
      );

      // Given: 複数の未読通知を作成
      for (int i = 0; i < 3; i++) {
        await firestore.collection('notifications').add({
          'userId': testUserAliceId,
          'type': 'like',
          'message': '未読通知 $i',
          'data': {},
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // When: 未読通知数を取得
      final unreadCount = await notificationService.getUnreadCount();

      // Then: 正しい未読数が返される
      expect(unreadCount, greaterThanOrEqualTo(3));
    });

    testWidgets('通知一覧ストリームのテスト', (tester) async {
      // Given: Aliceでログイン
      await auth.signInWithEmailAndPassword(
        email: 'alice@test.com',
        password: 'testpass123',
      );

      // Given: テスト通知を作成
      await firestore.collection('notifications').add({
        'userId': testUserAliceId,
        'type': 'comment',
        'message': 'ストリームテスト通知',
        'data': {'test': 'stream'},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // When: 通知一覧ストリームを取得
      final notificationsStream = notificationService.getUserNotifications();
      final notifications = await notificationsStream.first;

      // Then: 通知が含まれている
      expect(notifications.length, greaterThan(0));
      final streamNotification = notifications.firstWhere(
        (n) => n.message == 'ストリームテスト通知',
        orElse: () => throw Exception('通知が見つかりません'),
      );
      expect(streamNotification.metadata['test'], 'stream');
    });
  });
}

Future<void> _cleanupTestData(FirebaseFirestore firestore, List<String> userIds) async {
  // テストで作成されたデータをクリーンアップ
  final collections = ['notifications', 'posts', 'likes', 'comments', 'users'];
  
  for (final collection in collections) {
    final snapshot = await firestore.collection(collection).get();
    final batch = firestore.batch();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}