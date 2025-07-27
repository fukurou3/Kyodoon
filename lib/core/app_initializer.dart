import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../firebase_options.dart';
import '../utils/rate_limiter.dart';
import '../services/analytics_service.dart';
import '../config/app_config.dart';
import 'di/service_locator.dart';

/// アプリケーション初期化を担当するクラス
class AppInitializer {
  static bool _initialized = false;

  /// アプリケーションの初期化
  /// 
  /// 以下の順序で初期化を実行：
  /// 1. Flutter Binding
  /// 2. 環境変数読み込み
  /// 3. アプリ設定初期化
  /// 4. Firebase初期化
  /// 5. サービス初期化
  /// 6. 依存性注入コンテナ初期化（GetItベース）
  static Future<void> initialize() async {
    if (_initialized) return;

    // Flutter Binding確保
    WidgetsFlutterBinding.ensureInitialized();
    
    // 環境変数読み込み
    await dotenv.load(fileName: "assets/.env");
    
    // アプリ設定初期化
    AppConfig.initialize();
    
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // レート制限器初期化
    await RateLimiter.initialize();
    
    // Analytics初期化
    await AnalyticsService.initialize();
    
    // 依存性注入コンテナ初期化
    await setupServiceLocator();

    _initialized = true;
  }

  /// 初期化状態の確認
  static bool get isInitialized => _initialized;
}