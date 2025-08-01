import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/riverpod_providers.dart';
import '../widgets/login_modal.dart';
import '../widgets/theme_toggle_button.dart';
import '../constants/app_colors.dart';

/// メインナビゲーション画面
/// 
/// サイドバーナビゲーションとコンテンツエリアを管理
class MainNavigationScreen extends ConsumerStatefulWidget {
  final Widget child;
  
  const MainNavigationScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateCurrentIndex();
  }

  @override
  void didUpdateWidget(MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCurrentIndex();
  }

  /// 現在のルートに基づいてナビゲーションインデックスを更新
  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    setState(() {
      if (location.startsWith('/home')) {
        _currentIndex = 0;
      } else if (location.startsWith('/posts')) {
        _currentIndex = 1;
      } else if (location.startsWith('/my-page') || location.startsWith('/user/')) {
        _currentIndex = 2;
      } else {
        _currentIndex = 0;
      }
    });
  }

  /// ログインモーダルの表示
  Future<void> _showLoginModal() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LoginModal(),
    );
    
    // ログイン成功時にマイページに遷移
    if (result == true && mounted) {
      context.go('/my-page');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1100;
    final sidebarWidth = isCompact ? 80.0 : 250.0;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Row(
            children: [
              _buildSidebar(sidebarWidth, isCompact),
              _buildMainContent(),
            ],
          ),
          _buildThemeToggleButton(),
        ],
      ),
    );
  }

  /// サイドバーの構築
  Widget _buildSidebar(double width, bool isCompact) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          right: BorderSide(color: AppColors.text, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(isCompact),
          const SizedBox(height: 20),
          _buildNavigationMenu(isCompact),
          _buildAuthButton(isCompact),
        ],
      ),
    );
  }

  /// ヘッダー部分の構築
  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: isCompact
          ? Center(
              child: Icon(
                Icons.chat_bubble,
                color: AppColors.text,
                size: 28,
              ),
            )
          : Row(
              children: [
                Icon(
                  Icons.chat_bubble,
                  color: AppColors.text,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kyodoon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
    );
  }

  /// ナビゲーションメニューの構築
  Widget _buildNavigationMenu(bool isCompact) {
    return Expanded(
      child: Column(
        children: [
          _buildNavItem(
            label: 'ホーム',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            index: 0,
            isCompact: isCompact,
          ),
          _buildNavItem(
            label: '投稿',
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            index: 1,
            isCompact: isCompact,
          ),
          _buildNavItem(
            label: 'マイページ',
            icon: Icons.person_outlined,
            activeIcon: Icons.person,
            index: 2,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  /// ナビゲーションアイテムの構築
  Widget _buildNavItem({
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required bool isCompact,
  }) {
    final isSelected = _currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _handleNavItemTap(index),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.text.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: isCompact
              ? Center(
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: AppColors.text,
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      color: AppColors.text,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// ナビゲーションアイテムタップ処理
  void _handleNavItemTap(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/posts');
        break;
      case 2:
        if (!ref.read(isLoggedInProvider)) {
          _showLoginModal();
        } else {
          context.go('/my-page');
        }
        break;
    }
  }

  /// 認証ボタンの構築
  Widget _buildAuthButton(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ref.watch(isLoggedInProvider)
          ? _buildLogoutButton(isCompact)
          : _buildLoginButton(isCompact),
    );
  }

  /// ログアウトボタンの構築
  Widget _buildLogoutButton(bool isCompact) {
    return SizedBox(
      width: double.infinity,
      child: isCompact
          ? IconButton(
              onPressed: () => ref.read(authUseCaseProvider).signOut(),
              icon: const Icon(Icons.logout_outlined),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.text,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: () => ref.read(authUseCaseProvider).signOut(),
              icon: const Icon(Icons.logout_outlined, size: 18),
              label: const Text('ログアウト'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.text,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
    );
  }

  /// ログインボタンの構築
  Widget _buildLoginButton(bool isCompact) {
    return SizedBox(
      width: double.infinity,
      child: isCompact
          ? IconButton(
              onPressed: () => _showLoginModal(),
              icon: const Icon(Icons.login),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.text,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: () => _showLoginModal(),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('ログイン'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.text,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
    );
  }

  /// メインコンテンツエリアの構築
  Widget _buildMainContent() {
    return Expanded(
      child: Column(
        children: [
          // トップバー（特定画面では非表示）
          if (!_shouldHideTitle()) _buildTopBar(),
          
          // コンテンツ
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.text, width: 1),
                    right: BorderSide(color: AppColors.text, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _getBodyContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// トップバーの構築
  Widget _buildTopBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.text, width: 1),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              _getAppBarTitle(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// テーマ切り替えボタンの構築
  Widget _buildThemeToggleButton() {
    return const Positioned(
      top: 20,
      right: 20,
      child: ThemeToggleButton(),
    );
  }

  /// アプリバータイトルの取得
  String _getAppBarTitle() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) {
      return '地域活性化プラットフォーム';
    } else if (location.startsWith('/posts')) {
      return '気づき・アイデア';
    } else if (location.startsWith('/user/')) {
      return 'ユーザーページ';
    } else if (location.startsWith('/my-page')) {
      return 'マイページ';
    } else {
      return '地域活性化プラットフォーム';
    }
  }

  /// タイトル非表示判定
  bool _shouldHideTitle() {
    // ホーム、投稿画面、マイページ画面、ユーザーページ画面ではタイトルを非表示
    switch (_currentIndex) {
      case 0: // ホーム
      case 1: // 投稿画面
      case 2: // マイページ/ユーザーページ
        return true;
      default:
        return false;
    }
  }

  /// ボディコンテンツの取得
  Widget _getBodyContent() {
    return widget.child;
  }
}