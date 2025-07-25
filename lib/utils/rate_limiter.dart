import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';

/// レート制限を管理するクラス
class RateLimiter {
  static final Map<String, Queue<DateTime>> _requestHistory = {};
  static final Map<String, DateTime> _blockUntil = {};
  
  // デフォルト制限設定
  static const Map<String, RateLimit> _defaultLimits = {
    'post_create': RateLimit(maxRequests: 5, windowMinutes: 5), // 5分間に5回まで投稿
    'auth_login': RateLimit(maxRequests: 10, windowMinutes: 15), // 15分間に10回までログイン試行
    'auth_register': RateLimit(maxRequests: 3, windowMinutes: 60), // 1時間に3回まで登録試行
    'comment_create': RateLimit(maxRequests: 10, windowMinutes: 5), // 5分間に10回までコメント
    'like_toggle': RateLimit(maxRequests: 30, windowMinutes: 1), // 1分間に30回までいいね
    'search': RateLimit(maxRequests: 20, windowMinutes: 1), // 1分間に20回まで検索
    'profile_update': RateLimit(maxRequests: 3, windowMinutes: 60), // 1時間に3回までプロフィール更新
  };

  /// レート制限チェック
  /// [action] アクション名
  /// [userId] ユーザーID（IP制限の場合は空文字）
  /// [customLimit] カスタム制限（オプション）
  static Future<RateLimitResult> checkLimit(
    String action, 
    String userId, {
    RateLimit? customLimit,
  }) async {
    final limit = customLimit ?? _defaultLimits[action];
    if (limit == null) {
      return RateLimitResult(allowed: true);
    }

    final key = '${action}_$userId';
    final now = DateTime.now();

    // ブロック期間中かチェック
    if (_blockUntil.containsKey(key)) {
      final blockUntil = _blockUntil[key]!;
      if (now.isBefore(blockUntil)) {
        final remainingSeconds = blockUntil.difference(now).inSeconds;
        return RateLimitResult(
          allowed: false,
          remainingTime: remainingSeconds,
          reason: 'レート制限により一時的にブロックされています',
        );
      } else {
        _blockUntil.remove(key);
      }
    }

    // リクエスト履歴を取得・初期化
    if (!_requestHistory.containsKey(key)) {
      _requestHistory[key] = Queue<DateTime>();
    }

    final history = _requestHistory[key]!;
    final windowStart = now.subtract(Duration(minutes: limit.windowMinutes));

    // 期限切れのリクエストを削除
    while (history.isNotEmpty && history.first.isBefore(windowStart)) {
      history.removeFirst();
    }

    // 制限チェック
    if (history.length >= limit.maxRequests) {
      // ブロック期間を設定（制限時間の2倍）
      final blockDuration = Duration(minutes: limit.windowMinutes * 2);
      _blockUntil[key] = now.add(blockDuration);
      
      // 永続化（アプリ再起動時も制限を維持）
      await _saveBlockInfo(key, _blockUntil[key]!);
      
      return RateLimitResult(
        allowed: false,
        remainingTime: blockDuration.inSeconds,
        reason: 'レート制限を超過しました。しばらく時間をおいてから再試行してください。',
      );
    }

    // リクエストを記録
    history.add(now);
    
    final remainingRequests = limit.maxRequests - history.length;
    final nextResetTime = history.isNotEmpty 
        ? history.first.add(Duration(minutes: limit.windowMinutes))
        : now.add(Duration(minutes: limit.windowMinutes));

    return RateLimitResult(
      allowed: true,
      remainingRequests: remainingRequests,
      resetTime: nextResetTime,
    );
  }

  /// グローバルレート制限（IP基準）
  static Future<RateLimitResult> checkGlobalLimit(
    String action, {
    RateLimit? customLimit,
  }) async {
    // 実際のIPアドレス取得は実装依存
    // ここでは簡易的にグローバルキーを使用
    return await checkLimit(action, 'global', customLimit: customLimit);
  }

  /// ユーザー別レート制限
  static Future<RateLimitResult> checkUserLimit(
    String action,
    String userId, {
    RateLimit? customLimit,
  }) async {
    if (userId.isEmpty) {
      throw ArgumentError('ユーザーIDが必要です');
    }
    return await checkLimit(action, userId, customLimit: customLimit);
  }

  /// レート制限リセット（管理者用）
  static void resetUserLimit(String action, String userId) {
    final key = '${action}_$userId';
    _requestHistory.remove(key);
    _blockUntil.remove(key);
  }

  /// 全制限リセット（デバッグ用）
  static void resetAllLimits() {
    _requestHistory.clear();
    _blockUntil.clear();
  }

  /// 永続化されたブロック情報を保存
  static Future<void> _saveBlockInfo(String key, DateTime blockUntil) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('block_$key', blockUntil.toIso8601String());
    } catch (e) {
      // SharedPreferences のエラーは無視（メモリ上でのみ制限）
    }
  }

  /// 永続化されたブロック情報を読み込み
  static Future<void> _loadBlockInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('block_'));
      
      for (final key in keys) {
        final blockUntilStr = prefs.getString(key);
        if (blockUntilStr != null) {
          final blockUntil = DateTime.parse(blockUntilStr);
          final actualKey = key.substring(6); // 'block_' プレフィックスを除去
          
          if (DateTime.now().isBefore(blockUntil)) {
            _blockUntil[actualKey] = blockUntil;
          } else {
            // 期限切れのブロック情報を削除
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      // 読み込みエラーは無視
    }
  }

  /// 初期化（アプリ起動時に呼び出し）
  static Future<void> initialize() async {
    await _loadBlockInfo();
  }

  /// 統計情報取得（デバッグ用）
  static Map<String, dynamic> getStatistics() {
    return {
      'active_limits': _requestHistory.length,
      'blocked_keys': _blockUntil.length,
      'request_history': _requestHistory.map((key, queue) => 
          MapEntry(key, queue.length)),
      'block_until': _blockUntil.map((key, time) => 
          MapEntry(key, time.toIso8601String())),
    };
  }
}

/// レート制限設定
class RateLimit {
  final int maxRequests;
  final int windowMinutes;

  const RateLimit({
    required this.maxRequests,
    required this.windowMinutes,
  });

  @override
  String toString() => 'RateLimit($maxRequests requests per ${windowMinutes}min)';
}

/// レート制限チェック結果
class RateLimitResult {
  final bool allowed;
  final String? reason;
  final int? remainingRequests;
  final int? remainingTime; // 秒
  final DateTime? resetTime;

  RateLimitResult({
    required this.allowed,
    this.reason,
    this.remainingRequests,
    this.remainingTime,
    this.resetTime,
  });

  bool get isBlocked => !allowed;
  
  String get message {
    if (allowed) {
      return remainingRequests != null 
          ? '残り$remainingRequests回のリクエストが可能です'
          : 'リクエストが許可されています';
    } else {
      return reason ?? 'レート制限により拒否されました';
    }
  }

  @override
  String toString() => 'RateLimitResult(allowed: $allowed, reason: $reason)';
}