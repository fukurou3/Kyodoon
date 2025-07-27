import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_initializer.dart';
import 'app.dart';

/// アプリケーションエントリーポイント
/// 
/// AppInitializer.initialize() 内で以下の初期化処理を実行：
/// - Flutter Binding, Firebase, 依存性注入コンテナ等のセットアップ
void main() async {
  // アプリケーションの初期化（DI初期化を含む）
  await AppInitializer.initialize();
  
  // アプリケーションの起動
  runApp(
    ProviderScope(
      child: const KyodoonApp(),
    ),
  );
}
