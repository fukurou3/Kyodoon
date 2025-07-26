import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart' as custom_auth;
import 'main_navigation_screen.dart';
import '../screens/landing_page.dart';

/// 認証状態に基づく画面切り替えを担当
/// 
/// Firebase Authの状態監視を実装
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // ユーザーがログインしている場合
          return Consumer<custom_auth.AuthProvider>(
            builder: (context, authProvider, child) {
              // AuthProviderに現在のユーザー情報を設定
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (authProvider.currentUser == null) {
                  authProvider.setCurrentUser(snapshot.data!);
                }
              });
              
              return const MainNavigationScreen(child: SizedBox.shrink());
            },
          );
        } else {
          // ユーザーがログインしていない場合
          return const AboutKyodoonPage();
        }
      },
    );
  }
}