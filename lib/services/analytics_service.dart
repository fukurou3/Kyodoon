import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Firebase Analytics統合サービス
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);

  /// Analytics初期化
  static Future<void> initialize() async {
    try {
      // Analytics収集の有効化（本番のみ）
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
      
      // ユーザープロパティの設定
      await _setDefaultUserProperties();
      
      AppLogger.info('Firebase Analytics initialized');
    } catch (e) {
      AppLogger.error('Analytics initialization failed', e);
    }
  }

  /// デフォルトユーザープロパティ設定
  static Future<void> _setDefaultUserProperties() async {
    try {
      await _analytics.setUserProperty(
        name: 'platform',
        value: _getPlatformName(),
      );
      
      await _analytics.setUserProperty(
        name: 'app_version',
        value: '1.0.0', // 実際のアプリバージョンに置き換え
      );
    } catch (e) {
      AppLogger.error('Failed to set user properties', e);
    }
  }

  /// プラットフォーム名取得
  static String _getPlatformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  /// ユーザーログイン追跡
  static Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      AppLogger.userAction('login', {'method': method});
    } catch (e) {
      AppLogger.error('Analytics login log failed', e);
    }
  }

  /// ユーザー登録追跡
  static Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      AppLogger.userAction('sign_up', {'method': method});
    } catch (e) {
      AppLogger.error('Analytics signup log failed', e);
    }
  }

  /// 投稿作成追跡
  static Future<void> logPostCreate({
    required String postType,
    int? contentLength,
    bool? hasLocation,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'post_create',
        parameters: {
          'post_type': postType,
          'content_length': contentLength ?? 0,
          'has_location': hasLocation ?? false,
        },
      );
      
      AppLogger.userAction('post_create', {
        'type': postType,
        'content_length': contentLength,
        'has_location': hasLocation,
      });
    } catch (e) {
      AppLogger.error('Analytics post create log failed', e);
    }
  }

  /// 投稿閲覧追跡
  static Future<void> logPostView({
    required String postId,
    required String postType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'post_view',
        parameters: {
          'post_id': postId,
          'post_type': postType,
        },
      );
    } catch (e) {
      AppLogger.error('Analytics post view log failed', e);
    }
  }

  /// いいね追跡
  static Future<void> logLike({
    required String postId,
    required String postType,
    required bool isLiked,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'post_like',
        parameters: {
          'post_id': postId,
          'post_type': postType,
          'action': isLiked ? 'like' : 'unlike',
        },
      );
    } catch (e) {
      AppLogger.error('Analytics like log failed', e);
    }
  }

  /// コメント追跡
  static Future<void> logComment({
    required String postId,
    required String postType,
    int? commentLength,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'post_comment',
        parameters: {
          'post_id': postId,
          'post_type': postType,
          'comment_length': commentLength ?? 0,
        },
      );
    } catch (e) {
      AppLogger.error('Analytics comment log failed', e);
    }
  }

  /// 検索追跡
  static Future<void> logSearch({
    required String searchTerm,
    String? category,
    int? resultCount,
  }) async {
    try {
      final parameters = <String, Object>{
        'result_count': resultCount ?? 0,
      };
      if (category != null) {
        parameters['category'] = category;
      }
      
      await _analytics.logSearch(
        searchTerm: searchTerm,
        numberOfNights: null,
        numberOfRooms: null,
        numberOfPassengers: null,
        origin: null,
        destination: null,
        startDate: null,
        endDate: null,
        travelClass: null,
        parameters: parameters,
      );
    } catch (e) {
      AppLogger.error('Analytics search log failed', e);
    }
  }

  /// 画面遷移追跡
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? 'Screen',
      );
      
      AppLogger.navigation('Unknown', screenName);
    } catch (e) {
      AppLogger.error('Analytics screen view log failed', e);
    }
  }

  /// カスタムイベント追跡
  static Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      
      AppLogger.userAction(eventName, parameters ?? {});
    } catch (e) {
      AppLogger.error('Analytics custom event log failed', e);
    }
  }

  /// エラーイベント追跡
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? context,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage,
          'context': context ?? 'unknown',
        },
      );
    } catch (e) {
      AppLogger.error('Analytics error log failed', e);
    }
  }

  /// パフォーマンス追跡
  static Future<void> logPerformance({
    required String operation,
    required int durationMs,
    bool? isSuccess,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_performance',
        parameters: {
          'operation': operation,
          'duration_ms': durationMs,
          'is_success': isSuccess ?? true,
          'is_slow': durationMs > 1000,
        },
      );
    } catch (e) {
      AppLogger.error('Analytics performance log failed', e);
    }
  }

  /// セキュリティイベント追跡
  static Future<void> logSecurityEvent({
    required String eventType,
    required String severity,
    Map<String, Object>? details,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'security_event',
        parameters: {
          'event_type': eventType,
          'severity': severity,
          ...?details,
        },
      );
      
      AppLogger.security(eventType, details ?? {});
    } catch (e) {
      AppLogger.error('Analytics security event log failed', e);
    }
  }

  /// ユーザープロパティ設定
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      AppLogger.error('Analytics user property set failed', e);
    }
  }

  /// ユーザーID設定
  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      AppLogger.error('Analytics user ID set failed', e);
    }
  }

  /// アプリバージョン設定
  static Future<void> setAppVersion(String version) async {
    try {
      await _analytics.setUserProperty(name: 'app_version', value: version);
    } catch (e) {
      AppLogger.error('Analytics app version set failed', e);
    }
  }

  /// A/Bテスト用のバリアント設定
  static Future<void> setExperimentVariant({
    required String experimentName,
    required String variantName,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: 'experiment_$experimentName',
        value: variantName,
      );
    } catch (e) {
      AppLogger.error('Analytics experiment variant set failed', e);
    }
  }

  /// デバッグビュー有効化（開発時のみ）
  static Future<void> enableDebugView() async {
    if (kDebugMode) {
      try {
        await _analytics.setUserProperty(name: 'debug_mode', value: 'true');
        AppLogger.info('Analytics debug view enabled');
      } catch (e) {
        AppLogger.error('Analytics debug view enable failed', e);
      }
    }
  }
}