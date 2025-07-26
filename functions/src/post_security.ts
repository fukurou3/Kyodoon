import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * セキュアな投稿作成Cloud Function
 * 
 * 高度なXSS対策とコンテンツ検証を含む投稿作成処理
 */
export const secureCreatePost = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    content: string;
    type: string;
    title?: string;
    locationType?: string;
    municipality?: string;
    isAnnouncement?: boolean;
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const userId = context.auth.uid;
    const { content, type, title, locationType, municipality, isAnnouncement } = data;

    // 入力検証
    if (!content || !type) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "必須パラメータが不足しています"
      );
    }

    // 投稿タイプ検証
    if (!["casual", "serious"].includes(type)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "無効な投稿タイプです"
      );
    }

    try {
      // 高度なXSS検証とサニタイズ
      const sanitizedContent = await advancedContentValidation(content, "content");
      const sanitizedTitle = title ? await advancedContentValidation(title, "title") : undefined;

      // ユーザー情報取得
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "ユーザーが見つかりません"
        );
      }

      const userData = userDoc.data()!;

      // 投稿データ作成
      const postData = {
        content: sanitizedContent,
        type: type,
        title: sanitizedTitle,
        authorId: userId,
        authorName: userData.username || "Unknown",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        locationType: locationType || null,
        municipality: municipality || null,
        isAnnouncement: isAnnouncement || false,
        likesCount: 0,
        commentsCount: 0,
        likedBy: [],
        isDeleted: false,
      };

      // 投稿をFirestoreに保存
      const postRef = await admin.firestore().collection("posts").add(postData);

      // セキュリティログ記録
      await admin.firestore().collection("security_logs").add({
        action: "post_created",
        userId: userId,
        postId: postRef.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          userAgent: context.rawRequest?.headers["user-agent"] || "",
          ip: context.rawRequest?.ip || "",
          contentLength: content.length,
          hasTitle: !!title,
        },
      });

      return {
        success: true,
        postId: postRef.id,
      };
    } catch (error) {
      console.error("投稿作成エラー:", error);

      // エラーログ記録
      await admin.firestore().collection("error_logs").add({
        action: "post_create_failed",
        userId: userId,
        error: error instanceof Error ? error.message : "Unknown error",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        data: { content: content.substring(0, 100), type },
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "投稿の作成に失敗しました"
      );
    }
  });

/**
 * 高度なコンテンツ検証とサニタイズ
 */
async function advancedContentValidation(content: string, type: "content" | "title"): Promise<string> {
  // 長さ制限
  const maxLength = type === "content" ? 2000 : 100;
  if (content.length > maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${type === "content" ? "投稿内容" : "タイトル"}が長すぎます（最大${maxLength}文字）`
    );
  }

  // 高度なXSS攻撃パターン検証
  const advancedDangerousPatterns = [
    // 基本的なHTMLタグ（大文字小文字混在対応）
    /<\s*[sS][cC][rR][iI][pP][tT][^>]*>/i,
    /<\s*[iI][fF][rR][aA][mM][eE][^>]*>/i,
    /<\s*[oO][bB][jJ][eE][cC][tT][^>]*>/i,
    /<\s*[eE][mM][bB][eE][dD][^>]*>/i,
    /<\s*[fF][oO][rR][mM][^>]*>/i,
    /<\s*[iI][nN][pP][uU][tT][^>]*>/i,
    /<\s*[mM][eE][tT][aA][^>]*>/i,
    /<\s*[lL][iI][nN][kK][^>]*>/i,
    /<\s*[sS][tT][yY][lL][eE][^>]*>/i,
    /<\s*[bB][aA][sS][eE][^>]*>/i,

    // JavaScript実行（エンコーディング対応）
    /[jJ][aA][vV][aA][sS][cC][rR][iI][pP][tT]\s*:/,
    /[vV][bB][sS][cC][rR][iI][pP][tT]\s*:/,
    /[dD][aA][tT][aA]\s*:/,
    /[mM][oO][cC][hH][aA]\s*:/,

    // イベントハンドラー（包括的）
    /[oO][nN]\w+\s*=/,
    /[oO][nN][cC][lL][iI][cC][kK]\s*=/,
    /[oO][nN][lL][oO][aA][dD]\s*=/,
    /[oO][nN][eE][rR][rR][oO][rR]\s*=/,
    /[oO][nN][fF][oO][cC][uU][sS]\s*=/,
    /[oO][nN][mM][oO][uU][sS][eE][oO][vV][eE][rR]\s*=/,

    // 評価系関数
    /[eE][vV][aA][lL]\s*\(/,
    /[fF][uU][nN][cC][tT][iI][oO][nN]\s*\(/,
    /[sS][eE][tT][tT][iI][mM][eE][oO][uU][tT]\s*\(/,
    /[sS][eE][tT][iI][nN][tT][eE][rR][vV][aA][lL]\s*\(/,

    // エンコーディング攻撃
    /&#x?[0-9a-fA-F]+;/,
    /%[0-9a-fA-F]{2}/,
    /\\u[0-9a-fA-F]{4}/,
    /\\x[0-9a-fA-F]{2}/,

    // Unicode制御文字
    /[\u0000-\u001F\u007F-\u009F]/,
    /[\u200B-\u200D\uFEFF]/,

    // Base64エンコーディング
    /[dD][aA][tT][aA]:[^;]*;[bB][aA][sS][eE]64,/,

    // CSS式攻撃
    /[eE][xX][pP][rR][eE][sS][sS][iI][oO][nN]\s*\(/,
    /[bB][eE][hH][aA][vV][iI][oO][rR]\s*:/,

    // XMLエンティティ攻撃
    /<!ENTITY/i,
    /<!DOCTYPE/i,
    /<!\[CDATA\[/i,
  ];

  // パターンマッチング検証
  for (const pattern of advancedDangerousPatterns) {
    if (pattern.test(content)) {
      // セキュリティ違反を記録
      await admin.firestore().collection("security_violations").add({
        action: `xss_attempt_in_${type}`,
        content: content,
        pattern: pattern.toString(),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          userAgent: "unknown", // contextは関数内でアクセス不可
          ip: "unknown",
        },
      });

      throw new functions.https.HttpsError(
        "invalid-argument",
        "不正なコンテンツが検出されました"
      );
    }
  }

  // 高度なサニタイズ処理
  let sanitized = content;

  // HTMLエンティティエンコーディング
  sanitized = sanitized
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#x27;")
    .replace(/\//g, "&#x2F;")
    .replace(/\n/g, "&#10;")
    .replace(/\r/g, "&#13;")
    .replace(/\t/g, "&#9;");

  // Unicode制御文字の除去
  sanitized = sanitized
    .replace(/[\u0000-\u001F\u007F-\u009F]/g, "")
    .replace(/[\u200B-\u200D\uFEFF]/g, "");

  return sanitized;
}

/**
 * セキュアなコメント作成Cloud Function
 */
export const secureCreateComment = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {
    postId: string;
    content: string;
  }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です"
      );
    }

    const userId = context.auth.uid;
    const { postId, content } = data;

    // 入力検証
    if (!postId || !content) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "必須パラメータが不足しています"
      );
    }

    try {
      // コンテンツの検証とサニタイズ
      const sanitizedContent = await advancedContentValidation(content, "content");

      // 投稿の存在確認
      const postDoc = await admin.firestore().collection("posts").doc(postId).get();
      if (!postDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "投稿が見つかりません"
        );
      }

      // ユーザー情報取得
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "ユーザーが見つかりません"
        );
      }

      const userData = userDoc.data()!;

      // コメントデータ作成
      const commentData = {
        content: sanitizedContent,
        userId: userId,
        username: userData.username || "Unknown",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        postId: postId,
      };

      // コメントをFirestoreに保存
      const commentRef = await admin
        .firestore()
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .add(commentData);

      // 投稿のコメント数を更新
      await admin.firestore().collection("posts").doc(postId).update({
        commentsCount: admin.firestore.FieldValue.increment(1),
      });

      return {
        success: true,
        commentId: commentRef.id,
      };
    } catch (error) {
      console.error("コメント作成エラー:", error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "コメントの作成に失敗しました"
      );
    }
  });