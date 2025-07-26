import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'themes/app_theme.dart';
import 'providers/theme_provider.dart';
import 'navigation/auth_wrapper.dart';

/// メインアプリケーションウィジェット
/// 
/// MaterialAppの設定とテーマ管理を担当
class KyodoonApp extends StatelessWidget {
  const KyodoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '地域活性化共創プラットフォーム',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: _getThemeMode(themeProvider.themeMode),
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
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