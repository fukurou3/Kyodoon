import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * 管理者専用システム通知作成Function
 * 
 * セキュリティ考慮事項:
 * - 管理者権限の厳格な検証
 * - システム通知のみ作成可能
 * - 監査ログの詳細記録
 */
export const createSystemNotification = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    targetUserId?: string;
    targetUserIds?: string[];
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

    const adminUserId = context.auth.uid;
    const { targetUserId, targetUserIds, message, metadata } = data;

    try {
      // 管理者権限の厳格な検証
      const adminDoc = await admin
        .firestore()
        .collection("users")
        .doc(adminUserId)
        .get();

      if (!adminDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "ユーザーが見つかりません"
        );
      }

      const adminData = adminDoc.data()!;
      
      // 複数の管理者権限チェック
      const isAdmin = adminData.role === "admin" || 
                     adminData.role === "super_admin" ||
                     adminData.permissions?.includes("create_system_notifications");

      if (!isAdmin) {
        // 権限違反の詳細ログ
        await admin.firestore().collection("security_violations").add({
          action: "unauthorized_admin_function_access",
          userId: adminUserId,
          functionName: "createSystemNotification",
          attemptedData: data,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          ip: context.rawRequest?.ip || "unknown",
          userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
        });

        throw new functions.https.HttpsError(
          "permission-denied",
          "管理者権限が必要です"
        );
      }

      // 入力検証
      if (!message || message.trim().length === 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "メッセージは必須です"
        );
      }

      if (message.length > 1000) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "メッセージが長すぎます（最大1000文字）"
        );
      }

      // ターゲットユーザーの指定確認
      if (!targetUserId && (!targetUserIds || targetUserIds.length === 0)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "通知対象のユーザーを指定してください"
        );
      }

      // 一度に送信できる通知数の制限
      const maxBulkNotifications = 100;
      if (targetUserIds && targetUserIds.length > maxBulkNotifications) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `一度に送信できる通知は${maxBulkNotifications}件までです`
        );
      }

      const notificationIds: string[] = [];
      const batch = admin.firestore().batch();
      const targets = targetUserId ? [targetUserId] : targetUserIds!;

      // 各ターゲットユーザーに対して通知作成
      for (const userId of targets) {
        // ターゲットユーザーの存在確認
        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .get();

        if (!userDoc.exists) {
          console.warn(`ユーザーが見つかりません: ${userId}`);
          continue;
        }

        // システム通知データ
        const notificationData = {
          userId: userId,
          fromUserId: adminUserId,
          type: "system",
          message: message.trim(),
          metadata: {
            ...metadata,
            adminId: adminUserId,
            adminName: adminData.displayName || adminData.email || "管理者",
          },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        const notificationRef = admin.firestore().collection("notifications").doc();
        batch.set(notificationRef, notificationData);
        notificationIds.push(notificationRef.id);
      }

      // 一括作成実行
      await batch.commit();

      // 管理者操作の監査ログ
      await admin.firestore().collection("admin_audit_logs").add({
        action: "system_notification_created",
        adminId: adminUserId,
        adminName: adminData.displayName || adminData.email || "管理者",
        targetCount: targets.length,
        message: message,
        notificationIds: notificationIds,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        ip: context.rawRequest?.ip || "unknown",
        userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
      });

      return {
        success: true,
        notificationCount: notificationIds.length,
        notificationIds: notificationIds,
      };

    } catch (error) {
      console.error("システム通知作成エラー:", error);

      // エラーログ記録
      await admin.firestore().collection("error_logs").add({
        action: "system_notification_create_failed",
        adminId: adminUserId,
        error: error instanceof Error ? error.message : "Unknown error",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        data: data,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "システム通知の作成に失敗しました"
      );
    }
  });

/**
 * 管理者による通知一括削除Function
 */
export const deleteNotificationsByAdmin = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    notificationIds: string[];
    reason: string;
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const adminUserId = context.auth.uid;
    const { notificationIds, reason } = data;

    try {
      // 管理者権限確認
      const adminDoc = await admin
        .firestore()
        .collection("users")
        .doc(adminUserId)
        .get();

      if (!adminDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "ユーザーが見つかりません"
        );
      }

      const adminData = adminDoc.data()!;
      const isAdmin = adminData.role === "admin" || 
                     adminData.role === "super_admin" ||
                     adminData.permissions?.includes("delete_notifications");

      if (!isAdmin) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "管理者権限が必要です"
        );
      }

      // 入力検証
      if (!notificationIds || notificationIds.length === 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "削除対象の通知IDを指定してください"
        );
      }

      if (notificationIds.length > 100) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "一度に削除できる通知は100件までです"
        );
      }

      if (!reason || reason.trim().length === 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "削除理由は必須です"
        );
      }

      // 一括削除実行
      const batch = admin.firestore().batch();
      const deletedNotifications: any[] = [];

      for (const notificationId of notificationIds) {
        const notificationRef = admin
          .firestore()
          .collection("notifications")
          .doc(notificationId);
        
        const notificationDoc = await notificationRef.get();
        if (notificationDoc.exists) {
          deletedNotifications.push({
            id: notificationId,
            data: notificationDoc.data(),
          });
          batch.delete(notificationRef);
        }
      }

      await batch.commit();

      // 削除操作の監査ログ
      await admin.firestore().collection("admin_audit_logs").add({
        action: "notifications_deleted_by_admin",
        adminId: adminUserId,
        adminName: adminData.displayName || adminData.email || "管理者",
        deletedCount: deletedNotifications.length,
        reason: reason.trim(),
        deletedNotifications: deletedNotifications,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        ip: context.rawRequest?.ip || "unknown",
        userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
      });

      return {
        success: true,
        deletedCount: deletedNotifications.length,
      };

    } catch (error) {
      console.error("管理者通知削除エラー:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "通知の削除に失敗しました"
      );
    }
  });