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
      // 二重検証: Custom ClaimsとFirestoreの両方をチェック
      const userRecord = await admin.auth().getUser(adminUserId);
      const customClaims = userRecord.customClaims || {};
      
      // Custom Claimsでの管理者権限確認
      const hasCustomClaimAdmin = customClaims.admin === true || 
                                 customClaims.super_admin === true ||
                                 (customClaims.permissions && 
                                  customClaims.permissions.includes("create_system_notifications"));

      // Firestoreでの管理者権限確認（フォールバック）
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
      
      // Firestoreでの権限チェック（セキュリティ強化のため禁止）
      const hasFirestoreRole = adminData.role === "admin" || 
                              adminData.role === "super_admin" ||
                              adminData.permissions?.includes("create_system_notifications");

      // 権限昇格攻撃の検出
      if (hasFirestoreRole && !hasCustomClaimAdmin) {
        // 権限昇格攻撃の可能性を検出・ログ記録
        await admin.firestore().collection("security_violations").add({
          action: "privilege_escalation_attempt",
          userId: adminUserId,
          functionName: "createSystemNotification",
          detectedIssue: "firestore_role_without_custom_claims",
          firestoreData: adminData,
          customClaims: customClaims,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          ip: context.rawRequest?.ip || "unknown",
          userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
        });
      }

      // Custom Claimsのみを信頼した権限判定
      if (!hasCustomClaimAdmin) {
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
 * 管理者権限設定Function
 * 
 * セキュリティ考慮事項:
 * - 超管理者のみ実行可能
 * - Custom Claims を使用した権限管理
 * - 詳細な監査ログの記録
 */
export const setAdminPrivileges = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    targetUserId: string;
    adminLevel: "admin" | "super_admin" | "moderator";
    permissions?: string[];
    reason: string;
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const executorUserId = context.auth.uid;
    const { targetUserId, adminLevel, permissions = [], reason } = data;

    try {
      // 実行者の権限確認（超管理者のみ）
      const executorRecord = await admin.auth().getUser(executorUserId);
      const executorClaims = executorRecord.customClaims || {};
      
      if (executorClaims.super_admin !== true) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "超管理者権限が必要です"
        );
      }

      // 対象ユーザーの存在確認
      await admin.auth().getUser(targetUserId);
      
      // Custom Claims設定
      const newClaims: Record<string, any> = {};
      
      switch (adminLevel) {
      case "super_admin":
        newClaims.super_admin = true;
        newClaims.admin = true;
        newClaims.permissions = [
          "create_system_notifications",
          "delete_notifications",
          "manage_users",
          "view_reports",
          "manage_admin_privileges",
          ...permissions
        ];
        break;
          
      case "admin":
        newClaims.admin = true;
        newClaims.permissions = [
          "create_system_notifications",
          "delete_notifications",
          "view_reports",
          ...permissions
        ];
        break;
          
      case "moderator":
        newClaims.moderator = true;
        newClaims.permissions = [
          "view_reports",
          "moderate_content",
          ...permissions
        ];
        break;
      }

      // Custom Claims を設定
      await admin.auth().setCustomUserClaims(targetUserId, newClaims);

      // 管理者操作の監査ログ
      await admin.firestore().collection("admin_audit_logs").add({
        action: "admin_privileges_granted",
        executorId: executorUserId,
        targetUserId: targetUserId,
        adminLevel: adminLevel,
        permissions: newClaims.permissions,
        reason: reason,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        ip: context.rawRequest?.ip || "unknown",
        userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
      });

      return {
        success: true,
        targetUserId: targetUserId,
        adminLevel: adminLevel,
        permissions: newClaims.permissions,
      };

    } catch (error) {
      console.error("管理者権限設定エラー:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "管理者権限の設定に失敗しました"
      );
    }
  });

/**
 * 管理者権限削除Function
 */
export const removeAdminPrivileges = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    targetUserId: string;
    reason: string;
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const executorUserId = context.auth.uid;
    const { targetUserId, reason } = data;

    try {
      // 実行者の権限確認（超管理者のみ）
      const executorRecord = await admin.auth().getUser(executorUserId);
      const executorClaims = executorRecord.customClaims || {};
      
      if (executorClaims.super_admin !== true) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "超管理者権限が必要です"
        );
      }

      // 自分自身の権限削除を防止
      if (executorUserId === targetUserId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "自分自身の管理者権限は削除できません"
        );
      }

      // 対象ユーザーの現在のClaims取得
      const targetRecord = await admin.auth().getUser(targetUserId);
      const currentClaims = targetRecord.customClaims || {};

      // Custom Claims をクリア（通常ユーザーに戻す）
      await admin.auth().setCustomUserClaims(targetUserId, {});

      // 管理者操作の監査ログ
      await admin.firestore().collection("admin_audit_logs").add({
        action: "admin_privileges_revoked",
        executorId: executorUserId,
        targetUserId: targetUserId,
        previousClaims: currentClaims,
        reason: reason,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        ip: context.rawRequest?.ip || "unknown",
        userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
      });

      return {
        success: true,
        targetUserId: targetUserId,
        previousClaims: currentClaims,
      };

    } catch (error) {
      console.error("管理者権限削除エラー:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "管理者権限の削除に失敗しました"
      );
    }
  });

/**
 * 初期超管理者作成Function (開発・セットアップ用)
 * 
 * セキュリティ考慮事項:
 * - 本番環境では無効化推奨
 * - 管理者が存在しない場合のみ実行可能
 * - 詳細な監査ログの記録
 */
export const createInitialSuperAdmin = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    targetUserId: string;
    reason: string;
    setupKey?: string; // セットアップキー（オプション）
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const { targetUserId, reason, setupKey } = data;

    try {
      // セットアップキーチェック（環境変数で設定可能）
      const expectedSetupKey = process.env.INITIAL_ADMIN_SETUP_KEY;
      if (expectedSetupKey && setupKey !== expectedSetupKey) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "無効なセットアップキーです"
        );
      }

      // 既存の管理者がいないかチェック
      const existingAdmins = await admin.firestore()
        .collection("admin_audit_logs")
        .where("action", "==", "admin_privileges_granted")
        .limit(1)
        .get();

      if (!existingAdmins.empty) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "既に管理者が存在するため、初期セットアップは実行できません"
        );
      }

      // 対象ユーザーの存在確認
      const targetRecord = await admin.auth().getUser(targetUserId);
      
      // 初期超管理者のCustom Claims設定
      const newClaims = {
        super_admin: true,
        admin: true,
        permissions: [
          "create_system_notifications",
          "delete_notifications",
          "manage_users",
          "view_reports",
          "manage_admin_privileges",
          "initial_setup"
        ]
      };

      // Custom Claims を設定
      await admin.auth().setCustomUserClaims(targetUserId, newClaims);

      // 初期セットアップの監査ログ
      await admin.firestore().collection("admin_audit_logs").add({
        action: "initial_super_admin_created",
        executorId: context.auth.uid,
        targetUserId: targetUserId,
        adminLevel: "super_admin",
        permissions: newClaims.permissions,
        reason: reason,
        isInitialSetup: true,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        ip: context.rawRequest?.ip || "unknown",
        userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
      });

      // セキュリティログ
      await admin.firestore().collection("security_logs").add({
        action: "initial_admin_setup_completed",
        executorId: context.auth.uid,
        targetUserId: targetUserId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          setupKeyProvided: !!setupKey,
          userAgent: context.rawRequest?.headers["user-agent"] || "",
          ip: context.rawRequest?.ip || "",
        },
      });

      return {
        success: true,
        message: "初期超管理者が正常に作成されました",
        targetUserId: targetUserId,
        adminLevel: "super_admin",
        permissions: newClaims.permissions,
      };

    } catch (error) {
      console.error("初期超管理者作成エラー:", error);

      // エラーログ記録
      await admin.firestore().collection("error_logs").add({
        action: "initial_super_admin_creation_failed",
        executorId: context.auth.uid,
        error: error instanceof Error ? error.message : "Unknown error",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        data: data,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "初期超管理者の作成に失敗しました"
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
      // 二重検証: Custom ClaimsとFirestoreの両方をチェック
      const userRecord = await admin.auth().getUser(adminUserId);
      const customClaims = userRecord.customClaims || {};
      
      // Custom Claimsでの管理者権限確認
      const hasCustomClaimAdmin = customClaims.admin === true || 
                                 customClaims.super_admin === true ||
                                 (customClaims.permissions && 
                                  customClaims.permissions.includes("delete_notifications"));

      // Firestoreでの管理者権限確認（攻撃検出用）
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
      const hasFirestoreRole = adminData.role === "admin" || 
                              adminData.role === "super_admin" ||
                              adminData.permissions?.includes("delete_notifications");

      // 権限昇格攻撃の検出
      if (hasFirestoreRole && !hasCustomClaimAdmin) {
        await admin.firestore().collection("security_violations").add({
          action: "privilege_escalation_attempt",
          userId: adminUserId,
          functionName: "deleteNotificationsByAdmin",
          detectedIssue: "firestore_role_without_custom_claims",
          firestoreData: adminData,
          customClaims: customClaims,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          ip: context.rawRequest?.ip || "unknown",
          userAgent: context.rawRequest?.headers["user-agent"] || "unknown",
        });
      }

      // Custom Claimsのみを信頼した権限判定
      if (!hasCustomClaimAdmin) {
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