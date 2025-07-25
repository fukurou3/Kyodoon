import 'package:flutter/material.dart';

// テーマモード列挙型
enum AppThemeMode { light, dark }

// アプリテーマクラス
class AppTheme {
  
  // ライトモードの色定義
  static const _lightColors = {
    'background': Color(0xFFFFF9F0),
    'text': Color(0xFF2C1810),
  };
  
  // ダークモードの色定義
  static const _darkColors = {
    'background': Color(0xFF1A1611),
    'text': Color(0xFFF5F3F0),
  };
  
  // 現在のテーマモード
  static AppThemeMode _currentMode = AppThemeMode.light;
  
  // テーマモードゲッター
  static AppThemeMode get currentMode => _currentMode;
  
  // テーマモードセッター
  static void setThemeMode(AppThemeMode mode) {
    _currentMode = mode;
  }
  
  // 色を取得するメソッド
  static Color getColor(String colorKey) {
    final colors = _currentMode == AppThemeMode.light ? _lightColors : _darkColors;
    return colors[colorKey] ?? Colors.grey;
  }
  
  // ThemeDataを生成するメソッド
  static ThemeData getThemeData(AppThemeMode mode) {
    final colors = mode == AppThemeMode.light ? _lightColors : _darkColors;
    
    return ThemeData(
      useMaterial3: true,
      brightness: mode == AppThemeMode.light ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: colors['background']!,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['text']!,
        brightness: mode == AppThemeMode.light ? Brightness.light : Brightness.dark,
      ).copyWith(
        surface: colors['background']!,
        onSurface: colors['text']!,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors['background']!,
        foregroundColor: colors['text']!,
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colors['text']!),
        bodyMedium: TextStyle(color: colors['text']!),
        bodySmall: TextStyle(color: colors['text']!),
      ),
    );
  }
}

// テーマ色へのアクセスを簡単にするクラス
class AppColors {
  static Color get background => AppTheme.getColor('background');
  static Color get text => AppTheme.getColor('text');
}