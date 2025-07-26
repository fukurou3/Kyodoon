import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'themes/app_theme.dart';
import 'providers/riverpod_providers.dart';
import 'navigation/app_router.dart';

/// メインアプリケーションウィジェット
/// 
/// MaterialAppの設定とテーマ管理を担当
class KyodoonApp extends ConsumerWidget {
  const KyodoonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: '地域活性化共創プラットフォーム',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _getThemeMode(themeMode),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }

  /// ライトテーマの構築
  ThemeData _buildLightTheme() {
    return AppTheme.getThemeData(AppThemeMode.light).copyWith(
      textTheme: GoogleFonts.interTextTheme(),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        enableFeedback: false,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }

  /// ダークテーマの構築
  ThemeData _buildDarkTheme() {
    return AppTheme.getThemeData(AppThemeMode.dark).copyWith(
      textTheme: GoogleFonts.interTextTheme(),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        enableFeedback: false,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }

  /// テーマモードの変換
  ThemeMode _getThemeMode(AppThemeMode appThemeMode) {
    return appThemeMode == AppThemeMode.light 
        ? ThemeMode.light 
        : ThemeMode.dark;
  }
}