import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/login_modal.dart';
import '../widgets/theme_toggle_button.dart';
import '../screens/home_screen.dart';
import '../screens/posts_screen.dart';
import '../screens/my_page_screen.dart';
import '../utils/navigation_helper.dart';
import '../constants/app_colors.dart';

/// メインナビゲーション画面
/// 
/// サイドバーナビゲーションとコンテンツエリアを管理
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _viewingUserId; // 他人のマイページを見る時のユーザーID

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupNavigationCallbacks();
  }

  /// 認証状態変化の監視設定
  void _setupAuthListener() {
    // Provider経由で認証状態を監視するため、このメソッドは簡略化
    // 実際の監視はConsumer<AuthProvider>で行う
  }

  /// ナビゲーションコールバックの設定
  void _setupNavigationCallbacks() {
    NavigationHelper.setShowUserPageCallback(showUserPage);
    NavigationHelper.setShowMyPageCallback(showMyPage);
  }

  /// ログインモーダルの表示
  Future<void> _showLoginModal() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LoginModal(),
    );
    
    // ログイン成功時にマイページに遷移
    if (result == true) {
      setState(() {
        _currentIndex = 2;
      });
    }
  }

  /// 他人のマイページを表示
  void showUserPage(String userId) {
    setState(() {
      _currentIndex = 2;
      _viewingUserId = userId;
    });
  }

  /// 自分のマイページを表示
  void showMyPage() {
    setState(() {
      _currentIndex = 2;
      _viewingUserId = null;
    });
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
    // 他人のユーザーページを見ている場合は、マイページタブをハイライトしない
    final isSelected = _currentIndex == index && 
                      !(index == 2 && _viewingUserId != null);
    
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
    // マイページタブに切り替える際の処理
    if (index == 2) {
      // ログインしていない場合の処理
      if (!Provider.of<AuthProvider>(context, listen: false).isLoggedIn) {
        // 現在他人のページを見ている場合は、そのまま維持
        if (_viewingUserId != null) {
          setState(() {
            _currentIndex = index;
          });
        } else {
          // 自分のページに行こうとした場合はログインモーダルを表示
          _showLoginModal();
        }
        return;
      }
    }
    
    setState(() {
      _currentIndex = index;
      // マイページタブに切り替える際は自分のページに戻す
      if (index == 2) {
        _viewingUserId = null;
      }
    });
  }

  /// 認証ボタンの構築
  Widget _buildAuthButton(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoggedIn) {
            return _buildLogoutButton(isCompact);
          } else {
            return _buildLoginButton(isCompact);
          }
        },
      ),
    );
  }

  /// ログアウトボタンの構築
  Widget _buildLogoutButton(bool isCompact) {
    return SizedBox(
      width: double.infinity,
      child: isCompact
          ? IconButton(
              onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
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
              onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
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
    switch (_currentIndex) {
      case 0:
        return '地域活性化プラットフォーム';
      case 1:
        return '気づき・アイデア';
      case 2:
        if (_viewingUserId != null) {
          return 'ユーザーページ';
        }
        return 'マイページ';
      default:
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
    switch (_currentIndex) {
      case 0:
        return const HomePageContent();
      case 1:
        return const PostsScreen();
      case 2:
        // 他人のページを見ている場合
        if (_viewingUserId != null) {
          return MyPageScreen(userId: _viewingUserId, isOwnPage: false);
        }
        // 自分のページを見る場合はログインが必要
        if (!Provider.of<AuthProvider>(context, listen: false).isLoggedIn) {
          return const HomePageContent();
        }
        return const MyPageScreen(isOwnPage: true);
      default:
        return const HomePageContent();
    }
  }
}