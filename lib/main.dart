import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'utils/rate_limiter.dart';
import 'services/analytics_service.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'widgets/login_modal.dart';
import 'widgets/theme_toggle_button.dart';
import 'screens/home_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/my_page_screen.dart';
import 'utils/navigation_helper.dart';
import 'themes/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: "assets/.env");
  
  // Initialize app configuration
  AppConfig.initialize();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize rate limiter
  await RateLimiter.initialize();
  
  // Initialize analytics
  await AnalyticsService.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const RegionalActivationApp(),
    ),
  );
}

class RegionalActivationApp extends StatelessWidget {
  const RegionalActivationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '地域活性化共創プラットフォーム',
          theme: AppTheme.getThemeData(AppThemeMode.light).copyWith(
            textTheme: GoogleFonts.interTextTheme(),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              enableFeedback: false,
            ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          darkTheme: AppTheme.getThemeData(AppThemeMode.dark).copyWith(
            textTheme: GoogleFonts.interTextTheme(),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              enableFeedback: false,
            ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          themeMode: themeProvider.themeMode == AppThemeMode.light 
              ? ThemeMode.light 
              : ThemeMode.dark,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _viewingUserId; // 他人のマイページを見る時のユーザーID

  @override
  void initState() {
    super.initState();
    // 認証状態の変化を監視
    AuthService.authStateChanges.listen((user) {
      if (user == null && _currentIndex == 2) {
        // ログアウト時にマイページにいた場合はホームに戻す
        setState(() {
          _currentIndex = 0;
        });
      }
    });
    
    // NavigationHelperにコールバックを設定
    NavigationHelper.setShowUserPageCallback(showUserPage);
    NavigationHelper.setShowMyPageCallback(showMyPage);
  }


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


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 画面幅が狭い場合（1100px以下）はアイコンのみ表示
    final isCompact = screenWidth < 1100;
    final sidebarWidth = isCompact ? 80.0 : 250.0;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Row(
        children: [
          // 左側サイドバー
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                right: BorderSide(color: AppColors.text, width: 1),
              ),
            ),
            child: Column(
              children: [
                // ヘッダー部分
                Container(
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
                ),
                const SizedBox(height: 20),
                
                // ナビゲーションメニュー
                Expanded(
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
                ),
                
                // 下部のログイン/ログアウトボタン
                Container(
                  padding: const EdgeInsets.all(20),
                  child: StreamBuilder(
                    stream: AuthService.authStateChanges,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return SizedBox(
                          width: double.infinity,
                          child: isCompact
                              ? IconButton(
                                  onPressed: () => AuthService.signOut(),
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
                                  onPressed: () => AuthService.signOut(),
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
                      } else {
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
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // メインコンテンツエリア
          Expanded(
            child: Column(
              children: [
                // トップバー（特定画面では非表示）
                if (!_shouldHideTitle())
                  Container(
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
                  ),
                
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
          ),
          
          // 右側の非表示スペーサー（左サイドバーと同じ幅）
          Container(
            width: sidebarWidth,
            color: Colors.transparent,
          ),
        ],
      ),
      
      // 右上のテーマ切り替えボタン
      Positioned(
        top: 20,
        right: 20,
        child: const ThemeToggleButton(),
      ),
        ],
      ),
    );
  }

  // 他人のマイページを表示するメソッド
  void showUserPage(String userId) {
    setState(() {
      _currentIndex = 2;
      _viewingUserId = userId;
    });
  }

  // 自分のマイページを表示するメソッド
  void showMyPage() {
    setState(() {
      _currentIndex = 2;
      _viewingUserId = null;
    });
  }

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
        onTap: () {
          // マイページタブに切り替える際の処理
          if (index == 2) {
            // ログインしていない場合の処理
            if (!AuthService.isLoggedIn) {
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
        },
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
                    color: isSelected ? AppColors.text : AppColors.text,
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? AppColors.text : AppColors.text,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? AppColors.text : AppColors.text,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

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

  bool _shouldHideTitle() {
    // ホーム、投稿画面、マイページ画面、ユーザーページ画面ではタイトルを非表示
    switch (_currentIndex) {
      case 0: // ホーム
        return true;
      case 1: // 投稿画面
        return true;
      case 2: // マイページ/ユーザーページ
        return true;
      default:
        return false;
    }
  }

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
        if (!AuthService.isLoggedIn) {
          return const HomePageContent();
        }
        return const MyPageScreen(isOwnPage: true);
      default:
        return const HomePageContent();
    }
  }
}