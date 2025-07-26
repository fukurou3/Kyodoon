import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_providers.dart';
import '../screens/landing_page.dart';
import '../screens/home_screen.dart';
import '../screens/posts_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/casual_post_screen.dart';
import '../screens/serious_post_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/privacy_policy_screen.dart';
import 'main_navigation_screen.dart';

/// アプリケーションのルーティング設定
/// 
/// GoRouterを使用したナビゲーション管理
class AppRouter {
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      routes: [
      // ランディングページ
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const AboutKyodoonPage(),
      ),
      
      // メインナビゲーション（認証後）
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          // ホーム画面
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePageContent(),
          ),
          
          // 投稿一覧画面
          GoRoute(
            path: '/posts',
            name: 'posts',
            builder: (context, state) => const PostsScreen(),
          ),
          
          // マイページ
          GoRoute(
            path: '/my-page',
            name: 'my-page',
            builder: (context, state) => const MyPageScreen(isOwnPage: true),
          ),
          
          // ユーザーページ
          GoRoute(
            path: '/user/:userId',
            name: 'user-page',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return MyPageScreen(userId: userId, isOwnPage: false);
            },
          ),
          
          // カジュアル投稿画面
          GoRoute(
            path: '/casual-post',
            name: 'casual-post',
            builder: (context, state) => const CasualPostScreen(),
          ),
          
          // シリアス投稿画面
          GoRoute(
            path: '/serious-post',
            name: 'serious-post',
            builder: (context, state) => const SeriousPostScreen(),
          ),
        ],
      ),
      
      // 利用規約
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      
      // プライバシーポリシー
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
    
      // 認証状態に基づくリダイレクト
      redirect: (context, state) {
        final isLoggedIn = ref.read(isLoggedInProvider);
        final isLoading = ref.read(authLoadingProvider);
        
        // ローディング中は何もしない
        if (isLoading) return null;
        
        final location = state.uri.toString();
        
        // 認証が必要なパス
        final protectedPaths = ['/home', '/posts', '/my-page', '/casual-post', '/serious-post'];
        final isProtectedPath = protectedPaths.any((path) => location.startsWith(path));
        
        // 未認証でprotectedパスにアクセスしようとした場合はランディングページへ
        if (!isLoggedIn && isProtectedPath) {
          return '/';
        }
        
        // 認証済みでランディングページにいる場合はホームへ
        if (isLoggedIn && location == '/') {
          return '/home';
        }
        
        return null;
      },
    
    // エラーページ
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'ページが見つかりません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? '不明なエラーが発生しました'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// GoRouterの拡張メソッド
extension AppRouterExtension on BuildContext {
  /// ユーザーページに遷移
  void goToUserPage(String userId) {
    go('/user/$userId');
  }
  
  /// マイページに遷移
  void goToMyPage() {
    go('/my-page');
  }
  
  /// 投稿画面に遷移
  void goToPosts() {
    go('/posts');
  }
  
  /// ホーム画面に遷移
  void goToHome() {
    go('/home');
  }
  
  /// カジュアル投稿作成画面に遷移
  void goToCasualPost() {
    go('/casual-post');
  }
  
  /// シリアス投稿作成画面に遷移
  void goToSeriousPost() {
    go('/serious-post');
  }
}