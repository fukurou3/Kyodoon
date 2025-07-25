import 'package:flutter/material.dart';

class NavigationHelper {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Function(String)? _showUserPageCallback;
  static VoidCallback? _showMyPageCallback;
  
  static void setShowUserPageCallback(Function(String) callback) {
    _showUserPageCallback = callback;
  }
  
  static void setShowMyPageCallback(VoidCallback callback) {
    _showMyPageCallback = callback;
  }
  
  static void showUserPage(String userId) {
    _showUserPageCallback?.call(userId);
  }
  
  static void showMyPage() {
    _showMyPageCallback?.call();
  }
}