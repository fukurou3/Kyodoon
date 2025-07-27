import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { checkRateLimits } from "./utils/rate_limiter";
import { validateNotificationPermission, isUserBlocked } from "./utils/permission_validator";

// 管理者機能をインポート
export * from "./admin_functions";

// セキュア投稿機能をインポート
export * from "./post_security";

// セキュアユーザー設定機能をインポート
export * from "./user_preferences_security";

// Firebase Admin初期化
admin.initializeApp();

// 古い関数定義は utils/ に移動済み

// レート制限チェック関数は utils/rate_limiter.ts に移動済み

// 通知生成Cloud Function（セキュリティ強化版）
export const createNotification = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    targetUserId: string;
    type: string;
    message: string;
    metadata?: Record<string, any>;
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const currentUserId = context.auth.uid;
    const { targetUserId, type, message, metadata } = data;

    // 入力検証
    if (!targetUserId || !type || !message) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "必須パラメータが不足しています"
      );
    }

    // 自分に通知を送る場合は拒否（自己通知はクライアントサイドでのみ許可）
    if (currentUserId === targetUserId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "自分への通知はクライアントサイドで作成してください"
      );
    }

    // メッセージ長制限
    if (message.length > 500) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "メッセージが長すぎます"
      );
    }

    // XSS対策: メッセージ内容の危険なタグ検証
    const dangerousPatterns = [
      /<script[^>]*>/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /<iframe[^>]*>/i,
      /<object[^>]*>/i,
      /<embed[^>]*>/i,
      /<form[^>]*>/i,
      /<input[^>]*>/i
    ];
    
    for (const pattern of dangerousPatterns) {
      if (pattern.test(message)) {
        // セキュリティ違反を記録
        await admin.firestore().collection("security_violations").add({
          action: "xss_attempt_in_notification",
          userId: currentUserId,
          message: message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          ip: context.rawRequest?.ip || "unknown",
          userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
        });

        throw new functions.https.HttpsError(
          "invalid-argument",
          "メッセージに不正なコンテンツが含まれています"
        );
      }
    }

    // 通知タイプ検証
    const allowedTypes = [
      "like", "comment", "follow", "mention", 
      "reply", "repost"
    ];
    if (!allowedTypes.includes(type)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "無効な通知タイプです"
      );
    }

    // システム通知は拒否（管理者用の別Functionで処理）
    if (type === "system") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "システム通知の作成権限がありません"
      );
    }

    try {
      // ターゲットユーザーの存在確認
      const targetUserDoc = await admin
        .firestore()
        .collection("users")
        .doc(targetUserId)
        .get();

      if (!targetUserDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "ターゲットユーザーが見つかりません"
        );
      }

      // ブロック関係の確認
      const isBlocked = await isUserBlocked(currentUserId, targetUserId);
      if (isBlocked) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "この ユーザーとの間でブロック関係があります"
        );
      }

      // 権限チェック: 通知作成の正当性を検証
      // validateNotificationPermissionは権限がない場合にエラーを投げる
      await validateNotificationPermission(
        currentUserId,
        targetUserId,
        type,
        metadata || {}
      );

      // 通知作成データ
      const notificationData = {
        userId: targetUserId,
        fromUserId: currentUserId,
        type: type,
        message: message,
        metadata: metadata || {},
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // 多層レート制限チェック
      await checkRateLimits(currentUserId, context.rawRequest?.ip || "unknown", type, targetUserId);

      // 通知ドキュメント作成
      const notificationRef = await admin
        .firestore()
        .collection("notifications")
        .add(notificationData);

      // セキュリティログ記録
      await admin
        .firestore()
        .collection("security_logs")
        .add({
          action: "notification_created",
          userId: currentUserId,
          targetUserId: targetUserId,
          notificationId: notificationRef.id,
          type: type,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            userAgent: context.rawRequest?.headers["user-agent"] || "",
            ip: context.rawRequest?.ip || "",
          },
        });

      return {
        success: true,
        notificationId: notificationRef.id,
      };
    } catch (error) {
      console.error("通知作成エラー:", error);

      // エラーログ記録
      await admin
        .firestore()
        .collection("error_logs")
        .add({
          action: "notification_create_failed",
          userId: currentUserId,
          error: error instanceof Error ? error.message : "Unknown error",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          data: { targetUserId, type, message },
        });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "通知の作成に失敗しました"
      );
    }
  });

// バッチ通知削除（古い通知の自動削除）
export const cleanupOldNotifications = functions
  .region("asia-northeast1")
  .pubsub.schedule("0 2 * * *") // 毎日午前2時実行
  .timeZone("Asia/Tokyo")
  .onRun(async () => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const query = admin
      .firestore()
      .collection("notifications")
      .where("createdAt", "<", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .limit(500); // バッチサイズ制限

    const snapshot = await query.get();
    
    if (snapshot.empty) {
      console.log("削除対象の古い通知はありません");
      return;
    }

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`${snapshot.size}件の古い通知を削除しました`);
  });

// 通知統計更新
export const updateNotificationStats = functions
  .region("asia-northeast1")
  .firestore.document("notifications/{notificationId}")
  .onCreate(async (snapshot, _context) => {
    const notification = snapshot.data();
    const userId = notification.userId;

    if (!userId) {
      console.error("通知にユーザーIDが含まれていません:", snapshot.id);
      return;
    }

    try {
      // ユーザーの未読通知数を更新
      const userRef = admin.firestore().collection("users").doc(userId);
      
      // ユーザーの存在確認と安全な更新
      const userDoc = await userRef.get();
      if (!userDoc.exists) {
        console.warn(`ユーザーが見つかりません: ${userId}`);
        return;
      }

      // 既存のカウントを取得して安全に更新
      const userData = userDoc.data()!;
      const currentCount = typeof userData.unreadNotificationCount === "number" 
        ? userData.unreadNotificationCount 
        : 0;

      await userRef.update({
        unreadNotificationCount: currentCount + 1,
        lastNotificationAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    } catch (error) {
      console.error("通知統計更新エラー:", error, "通知ID:", snapshot.id);
      // エラーが発生してもFirestore Triggerを停止させない
    }
  });

// 通知既読時の統計更新
export const onNotificationRead = functions
  .region("asia-northeast1")
  .firestore.document("notifications/{notificationId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    // isReadがfalseからtrueに変更された場合のみ処理
    if (!beforeData.isRead && afterData.isRead) {
      const userId = afterData.userId;
      
      if (!userId) {
        console.error("通知にユーザーIDが含まれていません:", context.params.notificationId);
        return;
      }

      try {
        const userRef = admin.firestore().collection("users").doc(userId);
        
        // ユーザーの存在確認と安全な更新
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
          console.warn(`ユーザーが見つかりません: ${userId}`);
          return;
        }

        // 現在のカウントを取得し、負の値にならないよう制御
        const userData = userDoc.data()!;
        const currentCount = typeof userData.unreadNotificationCount === "number" 
          ? userData.unreadNotificationCount 
          : 0;

        // カウントが0以下の場合は0に設定、それ以外は1減算
        const newCount = Math.max(0, currentCount - 1);

        await userRef.update({
          unreadNotificationCount: newCount,
          lastReadAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      } catch (error) {
        console.error("通知既読統計更新エラー:", error, "通知ID:", context.params.notificationId);
        // エラーが発生してもFirestore Triggerを停止させない
      }
    }
  });