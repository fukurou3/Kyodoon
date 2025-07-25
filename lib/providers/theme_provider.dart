import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  AppThemeMode _themeMode = AppThemeMode.light;
  
  AppThemeMode get themeMode => _themeMode;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  // テーマモードを変更
  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    AppTheme.setThemeMode(mode);
    _saveThemeMode();
    notifyListeners();
  }
  
  // テーマを切り替え
  void toggleTheme() {
    final newMode = _themeMode == AppThemeMode.light 
        ? AppThemeMode.dark 
        : AppThemeMode.light;
    setThemeMode(newMode);
  }
  
  // テーマモードを保存
  void _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.toString());
  }
  
  // テーマモードを読み込み
  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    
    if (themeString != null) {
      _themeMode = themeString == AppThemeMode.dark.toString() 
          ? AppThemeMode.dark 
          : AppThemeMode.light;
      AppTheme.setThemeMode(_themeMode);
      notifyListeners();
    }
  }
}