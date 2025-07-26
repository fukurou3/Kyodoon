import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * セキュアなユーザー設定更新Cloud Function
 * 
 * プライバシー設定とブロック・ミュート機能の高度なセキュリティ検証
 */
export const secureUpdateUserPreferences = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    notifications?: any;
    privacy?: any;
    display?: any;
    blockedUsers?: string[];
    mutedKeywords?: string[];
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const userId = context.auth.uid;
    const { notifications, privacy, display, blockedUsers, mutedKeywords } = data;

    try {
      // 既存設定の取得（将来の拡張用）
      const preferencesDoc = await admin
        .firestore()
        .collection("user_preferences")
        .doc(userId)
        .get();

      // 現在は使用していないが、将来の差分更新機能で使用予定
      // const currentPreferences: any = preferencesDoc.exists ? preferencesDoc.data() || {} : {};

      // 更新データの準備
      const updateData: any = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // 通知設定の検証と更新
      if (notifications) {
        const validatedNotifications = validateNotificationSettings(notifications);
        updateData.notifications = validatedNotifications;
      }

      // プライバシー設定の検証と更新
      if (privacy) {
        const validatedPrivacy = validatePrivacySettings(privacy);
        updateData.privacy = validatedPrivacy;
      }

      // 表示設定の検証と更新
      if (display) {
        const validatedDisplay = validateDisplaySettings(display);
        updateData.display = validatedDisplay;
      }

      // ブロックユーザーリストの検証と更新
      if (blockedUsers) {
        const validatedBlockedUsers = await validateBlockedUsersList(blockedUsers, userId);
        updateData.blockedUsers = validatedBlockedUsers;
      }

      // ミュートキーワードリストの検証と更新
      if (mutedKeywords) {
        const validatedMutedKeywords = validateMutedKeywordsList(mutedKeywords);
        updateData.mutedKeywords = validatedMutedKeywords;
      }

      // Firestoreに設定を保存
      await admin
        .firestore()
        .collection("user_preferences")
        .doc(userId)
        .set(updateData, { merge: true });

      // セキュリティログ記録
      await admin.firestore().collection("security_logs").add({
        action: "user_preferences_updated",
        userId: userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          userAgent: context.rawRequest?.headers["user-agent"] || "",
          ip: context.rawRequest?.ip || "",
          fieldsUpdated: Object.keys(updateData).filter(key => key !== 'updatedAt'),
          blockedUsersCount: blockedUsers?.length || 0,
          mutedKeywordsCount: mutedKeywords?.length || 0,
        },
      });

      return {
        success: true,
        message: "ユーザー設定が正常に更新されました",
      };
    } catch (error) {
      console.error("ユーザー設定更新エラー:", error);

      // エラーログ記録
      await admin.firestore().collection("error_logs").add({
        action: "user_preferences_update_failed",
        userId: userId,
        error: error instanceof Error ? error.message : "Unknown error",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "ユーザー設定の更新に失敗しました"
      );
    }
  });

/**
 * セキュアなユーザーブロック機能
 */
export const secureBlockUser = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    targetUserId: string;
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const currentUserId = context.auth.uid;
    const { targetUserId } = data;

    if (!targetUserId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "ターゲットユーザーIDが必要です"
      );
    }

    // 自分自身をブロックしようとした場合のチェック
    if (currentUserId === targetUserId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "自分自身をブロックすることはできません"
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

      // ブロック処理をトランザクションで実行
      await admin.firestore().runTransaction(async (transaction) => {
        const preferencesRef = admin
          .firestore()
          .collection("user_preferences")
          .doc(currentUserId);
        
        const preferencesDoc = await transaction.get(preferencesRef);
        
        let blockedUsers: string[] = [];
        if (preferencesDoc.exists) {
          const data = preferencesDoc.data();
          blockedUsers = data?.blockedUsers || [];
        }

        // 重複チェック
        if (blockedUsers.includes(targetUserId)) {
          throw new functions.https.HttpsError(
            "already-exists",
            "このユーザーは既にブロック済みです"
          );
        }

        // ブロックリストの上限チェック
        if (blockedUsers.length >= 1000) {
          throw new functions.https.HttpsError(
            "resource-exhausted",
            "ブロックユーザー数が上限に達しています（最大1000ユーザー）"
          );
        }

        // 検証済みのリストに追加
        const validatedBlockedUsers = await validateBlockedUsersList(
          [...blockedUsers, targetUserId],
          currentUserId
        );

        transaction.set(preferencesRef, {
          blockedUsers: validatedBlockedUsers,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      });

      // セキュリティログ記録
      await admin.firestore().collection("security_logs").add({
        action: "user_blocked",
        userId: currentUserId,
        targetUserId: targetUserId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          userAgent: context.rawRequest?.headers["user-agent"] || "",
          ip: context.rawRequest?.ip || "",
        },
      });

      return {
        success: true,
        message: "ユーザーをブロックしました",
      };
    } catch (error) {
      console.error("ユーザーブロックエラー:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "ユーザーのブロックに失敗しました"
      );
    }
  });

/**
 * 通知設定のバリデーション
 */
function validateNotificationSettings(notifications: any): any {
  const validatedSettings: any = {};

  // Boolean値の検証
  const booleanFields = [
    'enablePushNotifications',
    'enableEmailNotifications',
    'notifyOnNewPosts',
    'notifyOnComments',
    'notifyOnLikes',
    'notifyOnMentions'
  ];

  for (const field of booleanFields) {
    if (notifications.hasOwnProperty(field)) {
      if (typeof notifications[field] !== 'boolean') {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `通知設定の${field}はboolean値である必要があります`
        );
      }
      validatedSettings[field] = notifications[field];
    }
  }

  return validatedSettings;
}

/**
 * プライバシー設定のバリデーション
 */
function validatePrivacySettings(privacy: any): any {
  const validatedSettings: any = {};

  // Boolean値の検証
  const booleanFields = [
    'profileIsPublic',
    'showEmail',
    'showLastLogin',
    'allowDirectMessages',
    'showActivityStatus'
  ];

  for (const field of booleanFields) {
    if (privacy.hasOwnProperty(field)) {
      if (typeof privacy[field] !== 'boolean') {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `プライバシー設定の${field}はboolean値である必要があります`
        );
      }
      validatedSettings[field] = privacy[field];
    }
  }

  return validatedSettings;
}

/**
 * 表示設定のバリデーション
 */
function validateDisplaySettings(display: any): any {
  const validatedSettings: any = {};

  // 言語設定の検証
  if (display.hasOwnProperty('language')) {
    const allowedLanguages = ['ja', 'en'];
    if (typeof display.language !== 'string' || !allowedLanguages.includes(display.language)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "無効な言語設定です"
      );
    }
    validatedSettings.language = display.language;
  }

  // テーマ設定の検証
  if (display.hasOwnProperty('theme')) {
    const allowedThemes = ['light', 'dark', 'system'];
    if (typeof display.theme !== 'string' || !allowedThemes.includes(display.theme)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "無効なテーマ設定です"
      );
    }
    validatedSettings.theme = display.theme;
  }

  // 投稿数設定の検証
  if (display.hasOwnProperty('postsPerPage')) {
    if (typeof display.postsPerPage !== 'number' || 
        display.postsPerPage < 5 || 
        display.postsPerPage > 100) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "投稿数は5-100の範囲で設定してください"
      );
    }
    validatedSettings.postsPerPage = display.postsPerPage;
  }

  // Boolean値の検証
  const booleanFields = ['showImages', 'autoRefresh'];
  for (const field of booleanFields) {
    if (display.hasOwnProperty(field)) {
      if (typeof display[field] !== 'boolean') {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `表示設定の${field}はboolean値である必要があります`
        );
      }
      validatedSettings[field] = display[field];
    }
  }

  return validatedSettings;
}

/**
 * ブロックユーザーリストのバリデーション
 */
async function validateBlockedUsersList(blockedUsers: string[], currentUserId: string): Promise<string[]> {
  if (!Array.isArray(blockedUsers)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "ブロックユーザーリストは配列である必要があります"
    );
  }

  if (blockedUsers.length > 1000) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "ブロックユーザー数が上限を超えています（最大1000ユーザー）"
    );
  }

  const validatedUsers: string[] = [];
  const seenUsers = new Set<string>();

  for (const userId of blockedUsers) {
    // 基本的なバリデーション
    if (typeof userId !== 'string' || userId.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "無効なユーザーIDが含まれています"
      );
    }

    if (userId.length > 128) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "ユーザーIDが長すぎます"
      );
    }

    // Firebase Auth UID形式の検証
    if (!/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(userId)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "無効なユーザーID形式です"
      );
    }

    // 自分自身をブロックしようとしていないかチェック
    if (userId === currentUserId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "自分自身をブロックすることはできません"
      );
    }

    // 重複チェック
    if (seenUsers.has(userId)) {
      continue; // 重複は無視
    }

    seenUsers.add(userId);
    validatedUsers.push(userId);
  }

  return validatedUsers;
}

/**
 * ミュートキーワードリストのバリデーション
 */
function validateMutedKeywordsList(mutedKeywords: string[]): string[] {
  if (!Array.isArray(mutedKeywords)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "ミュートキーワードリストは配列である必要があります"
    );
  }

  if (mutedKeywords.length > 500) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "ミュートキーワード数が上限を超えています（最大500キーワード）"
    );
  }

  const validatedKeywords: string[] = [];
  const seenKeywords = new Set<string>();

  for (const keyword of mutedKeywords) {
    // 基本的なバリデーション
    if (typeof keyword !== 'string' || keyword.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "無効なキーワードが含まれています"
      );
    }

    if (keyword.length > 100) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "キーワードが長すぎます（最大100文字）"
      );
    }

    // XSS攻撃パターンの検証
    const dangerousPatterns = [
      /<script[^>]*>/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /<iframe[^>]*>/i,
      /data:/i,
      /&#x?[0-9a-f]+;/i,
      /%[0-9a-f]{2}/i,
    ];

    if (dangerousPatterns.some(pattern => pattern.test(keyword))) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "不正なコンテンツが検出されました"
      );
    }

    // 制御文字のチェック
    if (/[\u0000-\u001F\u007F-\u009F]/.test(keyword)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "制御文字は使用できません"
      );
    }

    // 重複チェック
    const normalizedKeyword = keyword.toLowerCase().trim();
    if (seenKeywords.has(normalizedKeyword)) {
      continue; // 重複は無視
    }

    seenKeywords.add(normalizedKeyword);
    validatedKeywords.push(keyword.trim());
  }

  return validatedKeywords;
}