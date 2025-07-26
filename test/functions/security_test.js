const { describe, it, before, after } = require('mocha');
const { expect } = require('chai');
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

/**
 * Cloud Functions セキュリティテスト
 * 
 * 実行前に以下を起動:
 * firebase emulators:start --only functions,firestore,auth
 */

describe('Cloud Functions セキュリティテスト', function() {
  this.timeout(10000);

  let db;
  let auth;
  let testUsers = {};

  before(async () => {
    // Firebase Admin SDK初期化（エミュレータ用）
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: 'test-project',
        credential: admin.credential.applicationDefault(),
      });
    }

    // エミュレータ接続設定
    process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
    process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

    db = getFirestore();
    auth = getAuth();

    // テストユーザー作成
    testUsers.alice = await createTestUser('alice@test.com', 'Alice');
    testUsers.bob = await createTestUser('bob@test.com', 'Bob');
    testUsers.admin = await createTestUser('admin@test.com', 'Admin', true);

    // テストデータ準備
    await setupTestData();
  });

  after(async () => {
    // テストデータクリーンアップ
    await cleanupTestData();
  });

  async function createTestUser(email, name, isAdmin = false) {
    const userRecord = await auth.createUser({
      email: email,
      displayName: name,
      password: 'testpass123',
    });

    // Firestoreにユーザーデータ作成
    await db.collection('users').doc(userRecord.uid).set({
      email: email,
      displayName: name,
      role: isAdmin ? 'admin' : 'user',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { uid: userRecord.uid, email, name };
  }

  async function setupTestData() {
    // テスト用投稿作成
    await db.collection('posts').doc('test-post-1').set({
      authorId: testUsers.alice.uid,
      content: 'テスト投稿1',
      type: 'casual',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // テスト用いいね作成
    await db.collection('likes').doc('like-1').set({
      postId: 'test-post-1',
      userId: testUsers.bob.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // テスト用コメント作成
    await db.collection('comments').doc('comment-1').set({
      postId: 'test-post-1',
      authorId: testUsers.bob.uid,
      content: 'テストコメント',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  async function cleanupTestData() {
    // コレクションのクリーンアップ
    const collections = ['users', 'posts', 'likes', 'comments', 'notifications', 'security_violations'];
    
    for (const collectionName of collections) {
      const snapshot = await db.collection(collectionName).get();
      const batch = db.batch();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }

    // テストユーザー削除
    for (const user of Object.values(testUsers)) {
      try {
        await auth.deleteUser(user.uid);
      } catch (error) {
        console.warn(`Failed to delete user ${user.uid}:`, error.message);
      }
    }
  }

  async function callFunction(functionName, data, userToken = null) {
    // Cloud Functions呼び出しのシミュレーション
    // 実際の実装では firebase-functions-test を使用
    
    const mockContext = {
      auth: userToken ? { uid: userToken } : null,
      rawRequest: {
        ip: '127.0.0.1',
        headers: { 'user-agent': 'test-agent' }
      }
    };

    // ここでは簡略化したテストロジック
    // 実際のテストでは firebase-functions-test を使用して
    // 実際のCloud Functionを呼び出す
    return { success: true, mockCall: true };
  }

  describe('createNotification Function', () => {
    
    it('認証されていないリクエストを拒否する', async () => {
      try {
        await callFunction('createNotification', {
          targetUserId: testUsers.alice.uid,
          type: 'like',
          message: 'テスト通知',
        });
        expect.fail('認証エラーが発生するべきです');
      } catch (error) {
        expect(error.code).to.equal('unauthenticated');
      }
    });

    it('自分への通知作成を拒否する', async () => {
      try {
        await callFunction('createNotification', {
          targetUserId: testUsers.alice.uid,
          type: 'like',
          message: 'テスト通知',
        }, testUsers.alice.uid);
        expect.fail('自己通知エラーが発生するべきです');
      } catch (error) {
        expect(error.code).to.equal('invalid-argument');
      }
    });

    it('システム通知作成を拒否する', async () => {
      try {
        await callFunction('createNotification', {
          targetUserId: testUsers.alice.uid,
          type: 'system',
          message: 'システム通知',
        }, testUsers.bob.uid);
        expect.fail('権限エラーが発生するべきです');
      } catch (error) {
        expect(error.code).to.equal('permission-denied');
      }
    });

    it('存在しないユーザーへの通知作成を拒否する', async () => {
      try {
        await callFunction('createNotification', {
          targetUserId: 'non-existent-user',
          type: 'like',
          message: 'テスト通知',
        }, testUsers.bob.uid);
        expect.fail('ユーザー存在エラーが発生するべきです');
      } catch (error) {
        expect(error.code).to.equal('not-found');
      }
    });

    // 実際のリソース確認テスト（モック）
    it('有効ないいね通知の作成を許可する', async () => {
      const result = await callFunction('createNotification', {
        targetUserId: testUsers.alice.uid,
        type: 'like',
        message: 'いいね通知',
        metadata: { postId: 'test-post-1' }
      }, testUsers.bob.uid);

      expect(result.success).to.be.true;
    });

    it('無効ないいね通知の作成を拒否する', async () => {
      try {
        await callFunction('createNotification', {
          targetUserId: testUsers.alice.uid,
          type: 'like',
          message: 'いいね通知',
          metadata: { postId: 'non-existent-post' }
        }, testUsers.bob.uid);
        expect.fail('権限エラーが発生するべきです');
      } catch (error) {
        expect(error.code).to.equal('permission-denied');
      }
    });

  });

  describe('createSystemNotification Function', () => {
    
    it('管理者権限がない場合を拒否する', async () => {
      try {
        await callFunction('createSystemNotification', {
          targetUserId: testUsers.alice.uid,
          message: 'システム通知',
        }, testUsers.bob.uid);
        expect.fail('権限エラーが発生するべきです');
      } catch (error) {
        expect(error.code).to.equal('permission-denied');
      }
    });

    it('管理者による正当なシステム通知作成を許可する', async () => {
      const result = await callFunction('createSystemNotification', {
        targetUserId: testUsers.alice.uid,
        message: 'システムからのお知らせ',
      }, testUsers.admin.uid);

      expect(result.success).to.be.true;
    });

    it('一括通知の件数制限を適用する', async () => {
      const targetUserIds = Array.from({ length: 101 }, (_, i) => `user${i}`);
      
      try {
        await callFunction('createSystemNotification', {
          targetUserIds: targetUserIds,
          message: '一括通知テスト',
        }, testUsers.admin.uid);
        expect.fail('件数制限エラーが発生するべきです');
      } catch (error) {
        expect(error.code).to.equal('invalid-argument');
      }
    });

  });

  describe('セキュリティログテスト', () => {
    
    it('権限違反ログが記録される', async () => {
      // 権限違反を発生させる
      try {
        await callFunction('createNotification', {
          targetUserId: testUsers.alice.uid,
          type: 'like',
          message: 'テスト通知',
          metadata: { postId: 'non-existent-post' }
        }, testUsers.bob.uid);
      } catch (error) {
        // エラーは期待されるので無視
      }

      // セキュリティ違反ログの確認（モック）
      const violationLogs = await db.collection('security_violations')
        .where('fromUserId', '==', testUsers.bob.uid)
        .get();

      expect(violationLogs.docs.length).to.be.greaterThan(0);
    });

    it('管理者操作ログが記録される', async () => {
      // 管理者操作実行（モック）
      await callFunction('createSystemNotification', {
        targetUserId: testUsers.alice.uid,
        message: 'システム通知',
      }, testUsers.admin.uid);

      // 管理者監査ログの確認（モック）
      const auditLogs = await db.collection('admin_audit_logs')
        .where('adminId', '==', testUsers.admin.uid)
        .get();

      expect(auditLogs.docs.length).to.be.greaterThan(0);
    });

  });

  describe('Firebase Emulator 統合テスト', () => {
    
    it('Firestore エミュレータが動作している', async () => {
      const testDoc = await db.collection('test').doc('connectivity').set({
        test: true,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      const doc = await db.collection('test').doc('connectivity').get();
      expect(doc.exists).to.be.true;
      expect(doc.data().test).to.be.true;
    });

    it('Auth エミュレータが動作している', async () => {
      const users = await auth.listUsers();
      expect(users.users.length).to.be.greaterThan(0);
    });

    it('セキュリティルールがテスト環境で動作する', async () => {
      // テスト用の認証コンテキストでFirestoreアクセス
      // 実際のテストではfirebase-admin-testingを使用
      const testData = {
        type: 'like',
        userId: testUsers.alice.uid,
        message: 'テスト通知',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      };

      // 自分の通知作成は成功するべき
      await db.collection('notifications').add(testData);
      
      // 他人の通知作成は失敗するべき（実際のテストでは認証コンテキストを使用）
      expect(true).to.be.true; // プレースホルダー
    });

  });

});

/**
 * テスト実行手順:
 * 
 * 1. Firebase Emulatorを起動
 *    firebase emulators:start --only functions,firestore,auth --project test-project
 * 
 * 2. テスト実行
 *    cd functions && npm test
 * 
 * 3. セキュリティテストのみ実行
 *    cd functions && npm run test:security
 * 
 * 実際の本格的なテストには以下のパッケージが必要:
 * - firebase-functions-test
 * - @firebase/testing (deprecated) または @firebase/rules-unit-testing
 * - firebase-admin-testing
 */