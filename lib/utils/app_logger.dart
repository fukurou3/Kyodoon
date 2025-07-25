import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

/// アプリケーション共通のロガー
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    // リリースビルドではログを無効化
    level: kDebugMode ? Level.debug : Level.off,
  );

  // 構造化ログのための追加ロガー
  static final List<Map<String, dynamic>> _structuredLogs = [];
  static const int _maxLogCount = 1000; // メモリ使用量制限

  /// デバッグログ
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 情報ログ
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 警告ログ
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// エラーログ
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 致命的エラーログ
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// 認証関連のログ（機密情報を除く）
  static void auth(String action, {String? userId, dynamic error}) {
    if (error != null) {
      _logger.e('Auth $action failed', error: error);
    } else {
      _logger.i('Auth $action successful${userId != null ? ' (User: ${userId.substring(0, 8)}...)' : ''}');
    }
  }

  /// Firestore操作のログ
  static void firestore(String operation, String collection, {String? docId, dynamic error}) {
    if (error != null) {
      _logger.e('Firestore $operation failed: $collection${docId != null ? '/$docId' : ''}', error: error);
    } else {
      _logger.d('Firestore $operation: $collection${docId != null ? '/$docId' : ''}');
    }
  }

  /// ナビゲーションのログ
  static void navigation(String from, String to) {
    _logger.d('Navigation: $from → $to');
  }

  /// パフォーマンス測定のログ
  static void performance(String operation, Duration duration) {
    _logger.i('Performance: $operation took ${duration.inMilliseconds}ms');
    _addStructuredLog('performance', {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'is_slow': duration.inMilliseconds > 1000,
    });
  }

  /// 構造化ログの追加（セキュリティ・分析用）
  static void _addStructuredLog(String type, Map<String, dynamic> data) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'type': type,
      'user_id': _getCurrentUserId(),
      'session_id': _getSessionId(),
      'platform': _getPlatform(),
      'data': data,
    };

    _structuredLogs.add(logEntry);

    // メモリ使用量制限
    if (_structuredLogs.length > _maxLogCount) {
      _structuredLogs.removeAt(0);
    }

    // 重要なセキュリティイベントの場合は即座に出力
    if (_isSecurityEvent(type)) {
      _logSecurityEvent(logEntry);
    }
  }

  /// セキュリティ関連のログ
  static void security(String event, Map<String, dynamic> details) {
    _logger.w('Security Event: $event', error: details);
    _addStructuredLog('security', {
      'event': event,
      'details': details,
      'severity': _getSecuritySeverity(event),
    });
  }

  /// レート制限ログ
  static void rateLimit(String action, String userId, Map<String, dynamic> details) {
    _logger.w('Rate Limit: $action for user ${userId.substring(0, 8)}...');
    _addStructuredLog('rate_limit', {
      'action': action,
      'user_id_hash': _hashUserId(userId),
      'details': details,
    });
  }

  /// ユーザー行動ログ（プライバシー配慮）
  static void userAction(String action, Map<String, dynamic> metadata) {
    _logger.d('User Action: $action');
    _addStructuredLog('user_action', {
      'action': action,
      'metadata': metadata,
    });
  }

  /// エラーレポート（詳細な診断情報付き）
  static void errorReport(String context, dynamic error, StackTrace? stackTrace, {
    Map<String, dynamic>? additionalInfo
  }) {
    _logger.e('Error Report: $context', error: error, stackTrace: stackTrace);
    _addStructuredLog('error', {
      'context': context,
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'stack_trace': stackTrace?.toString(),
      'additional_info': additionalInfo,
    });
  }

  /// システム監視ログ
  static void systemMetrics(Map<String, dynamic> metrics) {
    _addStructuredLog('system_metrics', metrics);
  }

  /// 現在のユーザーID取得（プライバシー保護）
  static String? _getCurrentUserId() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user?.uid;
    } catch (e) {
      return null;
    }
  }

  /// セッションID取得（簡易実装）
  static String _getSessionId() {
    // 実装時にはより適切なセッション管理を使用
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// プラットフォーム情報取得
  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// セキュリティイベント判定
  static bool _isSecurityEvent(String type) {
    return ['security', 'rate_limit', 'auth_failure', 'suspicious_activity'].contains(type);
  }

  /// セキュリティイベントログ出力
  static void _logSecurityEvent(Map<String, dynamic> logEntry) {
    // 本番環境では外部ログサービスに送信
    if (kDebugMode) {
      print('SECURITY EVENT: ${jsonEncode(logEntry)}');
    }
  }

  /// セキュリティイベントの重要度判定
  static String _getSecuritySeverity(String event) {
    switch (event) {
      case 'unauthorized_access':
      case 'potential_injection':
      case 'suspicious_login':
        return 'high';
      case 'rate_limit_exceeded':
      case 'invalid_input':
        return 'medium';
      default:
        return 'low';
    }
  }

  /// ユーザーIDのハッシュ化（プライバシー保護）
  static String _hashUserId(String userId) {
    // 簡易ハッシュ（本番では適切なハッシュ関数を使用）
    return userId.length > 8 ? '${userId.substring(0, 4)}****${userId.substring(userId.length - 4)}' : '****';
  }

  /// 構造化ログの取得（デバッグ・分析用）
  static List<Map<String, dynamic>> getStructuredLogs({String? type, int? limit}) {
    var logs = _structuredLogs;
    
    if (type != null) {
      logs = logs.where((log) => log['type'] == type).toList();
    }
    
    if (limit != null && limit < logs.length) {
      logs = logs.sublist(logs.length - limit);
    }
    
    return logs;
  }

  /// ログ統計情報
  static Map<String, dynamic> getLogStatistics() {
    final typeCount = <String, int>{};
    for (final log in _structuredLogs) {
      final type = log['type'] as String;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return {
      'total_logs': _structuredLogs.length,
      'log_types': typeCount,
      'memory_usage_mb': (_structuredLogs.length * 0.5) / 1024, // 概算
      'oldest_log': _structuredLogs.isNotEmpty ? _structuredLogs.first['timestamp'] : null,
      'newest_log': _structuredLogs.isNotEmpty ? _structuredLogs.last['timestamp'] : null,
    };
  }

  /// ログクリア（メモリ管理）
  static void clearLogs({String? type}) {
    if (type != null) {
      _structuredLogs.removeWhere((log) => log['type'] == type);
    } else {
      _structuredLogs.clear();
    }
  }
}