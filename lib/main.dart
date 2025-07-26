import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_initializer.dart';
import 'core/di/injection_container.dart';
import 'providers/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart' as auth;
import 'features/posts/presentation/providers/posts_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'app.dart';

/// アプリケーションエントリーポイント
void main() async {
  // アプリケーションの初期化
  await AppInitializer.initialize();
  
  // アプリケーションの起動
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => InjectionContainer.instance.get<auth.AuthProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => InjectionContainer.instance.get<PostsProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => InjectionContainer.instance.get<ProfileProvider>(),
        ),
      ],
      child: const KyodoonApp(),
    ),
  );
}
