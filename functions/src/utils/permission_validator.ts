import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * 通知作成の権限を検証
 * 
 * @param currentUserId 現在のユーザーID
 * @param targetUserId ターゲットユーザーID
 * @param notificationType 通知タイプ
 * @param metadata 通知メタデータ
 */
export async function validateNotificationPermission(
  currentUserId: string,
  targetUserId: string,
  notificationType: string,
  metadata: any
): Promise<void> {
  const firestore = admin.firestore();

  try {
    // 1. 基本権限チェック - 自分に通知を送ることはクライアントサイドで処理
    if (currentUserId === targetUserId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "自分への通知はクライアントサイドで作成してください"
      );
    }

    // 2. ユーザーの存在確認
    const [currentUserDoc, targetUserDoc] = await Promise.all([
      firestore.collection('users').doc(currentUserId).get(),
      firestore.collection('users').doc(targetUserId).get()
    ]);

    if (!currentUserDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "送信者ユーザーが見つかりません"
      );
    }

    if (!targetUserDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "対象ユーザーが見つかりません"
      );
    }

    // 3. ブロック関係の確認
    const isBlocked = await isUserBlocked(currentUserId, targetUserId);
    if (isBlocked) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "この通知を作成する権限がありません"
      );
    }

    // 4. 通知タイプ別の詳細権限チェック
    await validateNotificationTypePermission(
      currentUserId,
      targetUserId,
      notificationType,
      metadata
    );

  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    console.error("権限検証エラー:", error);
    throw new functions.https.HttpsError(
      "internal",
      "権限検証中にエラーが発生しました"
    );
  }
}

/**
 * ブロック・ミュート関係の確認
 */
export async function isUserBlocked(fromUserId: string, targetUserId: string): Promise<boolean> {
  const firestore = admin.firestore();
  
  try {
    // 相互ブロックチェック
    const blockQuery = await firestore
      .collection("blocks")
      .where("blockerId", "in", [fromUserId, targetUserId])
      .where("blockedId", "in", [fromUserId, targetUserId])
      .limit(1)
      .get();
    
    return !blockQuery.empty;
  } catch (error) {
    console.error("ブロック関係確認エラー:", error);
    return true; // エラー時は安全側に倒してブロック扱い
  }
}

/**
 * 通知タイプ別の詳細権限チェック
 */
async function validateNotificationTypePermission(
  currentUserId: string,
  targetUserId: string,
  notificationType: string,
  metadata: any
): Promise<void> {
  const firestore = admin.firestore();

  switch (notificationType) {
    case 'like':
    case 'comment':
    case 'repost':
      // 投稿が存在し、アクセス可能かチェック
      if (!metadata?.postId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "postIdが必要です"
        );
      }
      
      const postDoc = await firestore.collection('posts').doc(metadata.postId).get();
      if (!postDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "投稿が見つかりません"
        );
      }
      
      // 投稿の作成者がtargetUserIdと一致するかチェック
      const postData = postDoc.data()!;
      if (postData.authorId !== targetUserId) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "この投稿に対する通知を作成する権限がありません"
        );
      }
      break;

    case 'reply':
      // コメントが存在し、アクセス可能かチェック
      if (!metadata?.commentId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "commentIdが必要です"
        );
      }
      
      const commentDoc = await firestore.collection('comments').doc(metadata.commentId).get();
      if (!commentDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "コメントが見つかりません"
        );
      }
      
      const commentData = commentDoc.data()!;
      if (commentData.authorId !== targetUserId) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "このコメントに対する通知を作成する権限がありません"
        );
      }
      break;

    case 'follow':
      // フォロー関係の重複チェック（必要に応じて）
      break;

    case 'mention':
      // メンション対象の妥当性チェック（必要に応じて）
      break;

    default:
      throw new functions.https.HttpsError(
        "invalid-argument",
        `未対応の通知タイプです: ${notificationType}`
      );
  }
}