import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_initializer.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

/// アプリケーションエントリーポイント
void main() async {
  // アプリケーションの初期化
  await AppInitializer.initialize();
  
  // 依存性注入の設定（後方互換性のため一時的に保持）
  await setupServiceLocator();
  
  // アプリケーションの起動
  runApp(
    ProviderScope(
      child: const KyodoonApp(),
    ),
  );
}
