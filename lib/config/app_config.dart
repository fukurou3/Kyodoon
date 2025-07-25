import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// アプリケーション設定管理クラス
class AppConfig {
  static AppEnvironment _environment = AppEnvironment.development;
  
  /// 現在の環境
  static AppEnvironment get environment => _environment;
  
  /// 環境の初期化
  static void initialize({AppEnvironment? env}) {
    if (env != null) {
      _environment = env;
    } else {
      // 自動判定
      if (kDebugMode) {
        _environment = AppEnvironment.development;
      } else if (kReleaseMode) {
        _environment = AppEnvironment.production;
      } else {
        _environment = AppEnvironment.staging;
      }
    }
  }

  /// 環境別設定取得
  static T getConfig<T>(String key, T defaultValue) {
    final envValue = dotenv.env[key];
    if (envValue == null) return defaultValue;
    
    if (T == bool) {
      return (envValue.toLowerCase() == 'true') as T;
    } else if (T == int) {
      return (int.tryParse(envValue) ?? defaultValue) as T;
    } else if (T == double) {
      return (double.tryParse(envValue) ?? defaultValue) as T;
    } else {
      return envValue as T;
    }
  }

  // Firebase設定
  static String get firebaseApiKey => getConfig('FIREBASE_API_KEY', '');
  static String get firebaseAppId => getConfig('FIREBASE_APP_ID', '');
  static String get firebaseProjectId => getConfig('FIREBASE_PROJECT_ID', '');
  static String get firebaseAuthDomain => getConfig('FIREBASE_AUTH_DOMAIN', '');
  static String get firebaseStorageBucket => getConfig('FIREBASE_STORAGE_BUCKET', '');
  static String get firebaseMeasurementId => getConfig('FIREBASE_MEASUREMENT_ID', '');

  // アプリケーション設定
  static String get appName {
    switch (_environment) {
      case AppEnvironment.development:
        return 'Kyodoon (Dev)';
      case AppEnvironment.staging:
        return 'Kyodoon (Staging)';
      case AppEnvironment.production:
        return 'Kyodoon';
    }
  }

  static String get appVersion => getConfig('APP_VERSION', '1.0.0');
  static String get buildNumber => getConfig('BUILD_NUMBER', '1');

  // API設定
  static String get apiBaseUrl {
    switch (_environment) {
      case AppEnvironment.development:
        return getConfig('DEV_API_URL', 'http://localhost:3000');
      case AppEnvironment.staging:
        return getConfig('STAGING_API_URL', 'https://staging-api.kyodoon.com');
      case AppEnvironment.production:
        return getConfig('PROD_API_URL', 'https://api.kyodoon.com');
    }
  }

  // ログ設定
  static bool get enableAnalytics {
    switch (_environment) {
      case AppEnvironment.development:
        return getConfig('DEV_ENABLE_ANALYTICS', false);
      case AppEnvironment.staging:
        return getConfig('STAGING_ENABLE_ANALYTICS', true);
      case AppEnvironment.production:
        return getConfig('PROD_ENABLE_ANALYTICS', true);
    }
  }

  static bool get enableCrashlytics {
    switch (_environment) {
      case AppEnvironment.development:
        return false;
      case AppEnvironment.staging:
        return getConfig('STAGING_ENABLE_CRASHLYTICS', true);
      case AppEnvironment.production:
        return getConfig('PROD_ENABLE_CRASHLYTICS', true);
    }
  }

  static bool get enableVerboseLogging {
    switch (_environment) {
      case AppEnvironment.development:
        return true;
      case AppEnvironment.staging:
        return getConfig('STAGING_VERBOSE_LOGGING', false);
      case AppEnvironment.production:
        return false;
    }
  }

  // セキュリティ設定
  static bool get enableSecurityLogging {
    return getConfig('ENABLE_SECURITY_LOGGING', true);
  }

  static int get rateLimitMaxRequests {
    switch (_environment) {
      case AppEnvironment.development:
        return getConfig('DEV_RATE_LIMIT_MAX', 100);
      case AppEnvironment.staging:
        return getConfig('STAGING_RATE_LIMIT_MAX', 50);
      case AppEnvironment.production:
        return getConfig('PROD_RATE_LIMIT_MAX', 30);
    }
  }

  static int get rateLimitWindowMinutes {
    return getConfig('RATE_LIMIT_WINDOW_MINUTES', 5);
  }

  // 機能フラグ
  static bool get enableFeatureX {
    return getConfig('ENABLE_FEATURE_X', false);
  }

  static bool get enableBetaFeatures {
    switch (_environment) {
      case AppEnvironment.development:
        return true;
      case AppEnvironment.staging:
        return getConfig('ENABLE_BETA_FEATURES', true);
      case AppEnvironment.production:
        return getConfig('ENABLE_BETA_FEATURES', false);
    }
  }

  // パフォーマンス設定
  static int get maxCacheSize {
    switch (_environment) {
      case AppEnvironment.development:
        return getConfig('DEV_MAX_CACHE_SIZE_MB', 100);
      case AppEnvironment.staging:
        return getConfig('STAGING_MAX_CACHE_SIZE_MB', 50);
      case AppEnvironment.production:
        return getConfig('PROD_MAX_CACHE_SIZE_MB', 30);
    }
  }

  static int get networkTimeoutSeconds {
    return getConfig('NETWORK_TIMEOUT_SECONDS', 30);
  }

  // UI設定
  static bool get enableDarkModeByDefault {
    return getConfig('ENABLE_DARK_MODE_DEFAULT', false);
  }

  static String get defaultLanguage {
    return getConfig('DEFAULT_LANGUAGE', 'ja');
  }

  // デバッグ設定
  static bool get showDebugInfo {
    switch (_environment) {
      case AppEnvironment.development:
        return true;
      case AppEnvironment.staging:
        return getConfig('SHOW_DEBUG_INFO', false);
      case AppEnvironment.production:
        return false;
    }
  }

  static bool get enablePerformanceOverlay {
    return _environment == AppEnvironment.development &&
           getConfig('ENABLE_PERFORMANCE_OVERLAY', false);
  }

  // 外部サービス設定
  static String get mapApiKey {
    return getConfig('MAP_API_KEY', '');
  }

  static String get sentryDsn {
    return getConfig('SENTRY_DSN', '');
  }

  // 環境情報の取得
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': _environment.name,
      'app_name': appName,
      'app_version': appVersion,
      'build_number': buildNumber,
      'firebase_project_id': firebaseProjectId,
      'api_base_url': apiBaseUrl,
      'enable_analytics': enableAnalytics,
      'enable_crashlytics': enableCrashlytics,
      'enable_verbose_logging': enableVerboseLogging,
      'enable_beta_features': enableBetaFeatures,
      'show_debug_info': showDebugInfo,
    };
  }

  /// 設定の妥当性チェック
  static List<String> validateConfig() {
    final errors = <String>[];

    if (firebaseApiKey.isEmpty) {
      errors.add('Firebase API Key is missing');
    }

    if (firebaseProjectId.isEmpty) {
      errors.add('Firebase Project ID is missing');
    }

    if (apiBaseUrl.isEmpty) {
      errors.add('API Base URL is missing');
    }

    if (_environment == AppEnvironment.production) {
      if (enableVerboseLogging) {
        errors.add('Verbose logging should be disabled in production');
      }

      if (showDebugInfo) {
        errors.add('Debug info should be disabled in production');
      }
    }

    return errors;
  }

  /// 設定の文字列表現
  static String configToString() {
    final info = getEnvironmentInfo();
    final buffer = StringBuffer();
    buffer.writeln('=== App Configuration ===');
    info.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }
}

/// アプリケーション環境の列挙
enum AppEnvironment {
  development('dev'),
  staging('staging'),
  production('prod');

  const AppEnvironment(this.value);
  final String value;

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;
}