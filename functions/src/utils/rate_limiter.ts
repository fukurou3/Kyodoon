import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * 多層レート制限チェック
 * 
 * @param userId 送信者のユーザーID
 * @param ip 送信者のIPアドレス
 * @param notificationType 通知タイプ
 * @param targetUserId ターゲットユーザーID
 */
export async function checkRateLimits(
  userId: string, 
  ip: string, 
  notificationType: string, 
  targetUserId: string
): Promise<void> {
  const firestore = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const oneMinuteAgo = admin.firestore.Timestamp.fromMillis(now.toMillis() - 60 * 1000);
  const oneHourAgo = admin.firestore.Timestamp.fromMillis(now.toMillis() - 60 * 60 * 1000);

  try {
    // 並行処理でパフォーマンス向上
    const [
      userNotifications,
      targetNotifications,
      recentTargetNotifications,
      targetUserDoc,
      senderUserDoc
    ] = await Promise.all([
      // 1. ユーザーごとレート制限チェック
      firestore
        .collection("notifications")
        .where("fromUserId", "==", userId)
        .where("createdAt", ">=", oneMinuteAgo)
        .get(),
      
      // 3. ターゲットユーザー保護チェック
      firestore
        .collection("notifications")
        .where("userId", "==", targetUserId)
        .where("createdAt", ">=", oneHourAgo)
        .get(),

      // 4. 協調攻撃検出
      firestore
        .collection("notifications")
        .where("userId", "==", targetUserId)
        .where("type", "==", notificationType)
        .where("createdAt", ">=", oneMinuteAgo)
        .get(),

      // ターゲットユーザーデータ取得
      firestore.collection("users").doc(targetUserId).get(),

      // 送信者ユーザーデータ取得
      firestore.collection("users").doc(userId).get()
    ]);

    // 1. ユーザーごとレート制限（基本制限）
    let userLimit = 10; // デフォルト制限

    // 送信者の新規アカウント制限チェック
    if (senderUserDoc.exists) {
      const senderData = senderUserDoc.data()!;
      if (senderData.createdAt) {
        try {
          const createdAt = senderData.createdAt instanceof admin.firestore.Timestamp 
            ? senderData.createdAt 
            : admin.firestore.Timestamp.fromDate(new Date(senderData.createdAt));
          
          const accountAge = now.toMillis() - createdAt.toMillis();
          const twentyFourHours = 24 * 60 * 60 * 1000;

          if (accountAge < twentyFourHours) {
            userLimit = 3; // 新規アカウントは1分間に3通知まで
          }
        } catch (dateError) {
          console.warn("アカウント作成日時の解析に失敗:", dateError);
          userLimit = 3; // エラー時は安全側に倒して制限を厳しくする
        }
      }
    }

    if (userNotifications.size >= userLimit) {
      const message = userLimit === 3 
        ? "新規アカウントのため、通知送信に制限があります。"
        : "レート制限に達しました。しばらく待ってから再試行してください。";
      
      throw new functions.https.HttpsError(
        "resource-exhausted",
        message
      );
    }

    // 2. IP制限（多重アカウント攻撃対策）
    if (ip !== "unknown") {
      try {
        // セキュリティログからIP別の通知作成履歴を取得
        const ipNotifications = await firestore
          .collection("security_logs")
          .where("action", "==", "notification_created")
          .where("timestamp", ">=", oneMinuteAgo)
          .get();

        // 同一IPからの通知作成数をカウント
        let ipNotificationCount = 0;
        ipNotifications.docs.forEach(doc => {
          const logData = doc.data();
          if (logData.metadata && logData.metadata.ip === ip) {
            ipNotificationCount++;
          }
        });

        // IP単位でのレート制限（1分間に20通知まで）
        if (ipNotificationCount >= 20) {
          await firestore.collection("security_violations").add({
            action: "ip_rate_limit_exceeded",
            ip: ip,
            userId: userId,
            attempts: ipNotificationCount,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              period: "1_minute",
              limit: 20,
              userAgent: "unknown" // 実際の実装では context.rawRequest から取得
            },
          });

          throw new functions.https.HttpsError(
            "resource-exhausted",
            "システム制限により一時的に利用を制限しています。"
          );
        }

        // 警告レベルでのログ出力
        if (ipNotificationCount >= 15) {
          console.warn(`IP ${ip} からの高頻度通知を検出: ${ipNotificationCount}件/分`);
        }

      } catch (ipError) {
        if (ipError instanceof functions.https.HttpsError) {
          throw ipError;
        }
        console.warn("IP制限チェックでエラー:", ipError);
        // IP制限チェックの失敗は処理を止めない（ログのみ）
      }
    }

    // 3. ターゲットユーザー保護（有名ユーザー対策）
    let maxNotificationsPerHour = 50; // デフォルト制限

    if (targetUserDoc.exists) {
      const targetUserData = targetUserDoc.data()!;
      
      // 安全な型チェック
      const isVerified = targetUserData.isVerified === true;
      const followersCount = typeof targetUserData.followersCount === 'number' 
        ? targetUserData.followersCount 
        : 0;

      if (isVerified || followersCount > 1000) {
        maxNotificationsPerHour = 200; // VIPユーザーは1時間に200通知まで
      }
    }

    if (targetNotifications.size >= maxNotificationsPerHour) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "受信者の通知制限に達しているため、通知を送信できません。"
      );
    }

    // 4. 協調攻撃検出（複数ユーザーが同一ターゲットを狙う）
    if (recentTargetNotifications.size >= 5) {
      const senderIds = new Set(
        recentTargetNotifications.docs
          .map(doc => doc.data().fromUserId)
          .filter(id => typeof id === 'string' && id.length > 0)
      );
      
      // 異なる送信者から同タイプの通知が来ている場合（協調攻撃の可能性）
      if (senderIds.size >= 3) {
        await firestore.collection("security_violations").add({
          action: "coordinated_notification_attack",
          targetUserId: targetUserId,
          notificationType: notificationType,
          senderCount: senderIds.size,
          notificationCount: recentTargetNotifications.size,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            senderIds: Array.from(senderIds),
            currentSender: userId,
            ip: ip !== "unknown" ? ip : null,
          },
        });

        throw new functions.https.HttpsError(
          "resource-exhausted",
          "システムにより一時的に制限されています。"
        );
      }
    }

  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    console.error("レート制限チェックエラー:", error);
    // エラー時は制限を適用（安全側に倒す）
    throw new functions.https.HttpsError(
      "internal",
      "システムエラーが発生しました。しばらく待ってから再試行してください。"
    );
  }
}