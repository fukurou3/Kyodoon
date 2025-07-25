import 'package:cloud_firestore/cloud_firestore.dart';

class DateUtils {
  // Timestampを相対時間に変換
  static String formatTimestamp(Timestamp timestamp) {
    return formatRelativeTime(timestamp.toDate());
  }

  // DateTimeを相対時間に変換
  static String formatDateTime(DateTime dateTime) {
    return formatRelativeTime(dateTime);
  }

  // 共通の相対時間フォーマット処理
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週間前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$monthsヶ月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years年前';
    }
  }

  // 日付を日本語フォーマットで表示（完全な日時）
  static String formatDateTimeJapanese(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 日付のみを日本語フォーマットで表示
  static String formatDateJapanese(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
  }

  // 時刻のみを表示
  static String formatTimeOnly(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 投稿用の柔軟な日時フォーマット
  static String formatPostDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // 1日以内は相対時間
    if (difference.inDays < 1) {
      return formatRelativeTime(dateTime);
    }
    // 7日以内は「月日 時刻」
    else if (difference.inDays < 7) {
      return '${dateTime.month}月${dateTime.day}日 ${formatTimeOnly(dateTime)}';
    }
    // それ以上は「年月日」
    else {
      return formatDateJapanese(dateTime);
    }
  }
}