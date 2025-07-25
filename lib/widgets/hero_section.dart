import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/serious_post_modal.dart';
import '../themes/app_theme.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.text.withValues(alpha: 0.1),
            AppColors.text.withValues(alpha: 0.1),
            AppColors.text.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 背景のイラストレーション
          Positioned(
            right: -50,
            top: 50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            left: -100,
            bottom: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.text.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          // メインコンテンツ
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // 左側：テキストコンテンツ
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // キャッチフレーズ
                        Text(
                          'あなたのアイデアで、\n地域を動かす。',
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // サブタイトル
                        Text(
                          '地域の課題を発見し、解決策を考え、\n仲間と一緒に実現する。\n未来の地域を共創するプラットフォームです。',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // CTAボタン群
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const SeriousPostModal(),
                                );
                              },
                              icon: const Icon(Icons.lightbulb_outline, size: 20),
                              label: const Text('アイデアを投稿'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.text,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                // 地域検索ページにナビゲート
                                // 地域検索機能：将来のリリースで実装予定
                              },
                              icon: const Icon(Icons.search, size: 20),
                              label: const Text('地域を探す'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.text,
                                side: BorderSide(color: AppColors.text, width: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 統計情報
                        Row(
                          children: [
                            _buildStatItem('1,234', 'アクティブユーザー'),
                            const SizedBox(width: 32),
                            _buildStatItem('567', '進行中プロジェクト'),
                            const SizedBox(width: 32),
                            _buildStatItem('89', '参加地域'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 右側：イラストレーション
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 地域活性化のアイコン群
                          Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // 中央のアイコン
                                Center(
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.text,
                                          AppColors.text,
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.groups,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                
                                // 周囲のアイコン
                                ..._buildOrbitingIcons(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOrbitingIcons() {
    final icons = [
      {
        'icon': Icons.lightbulb_outline,
        'color': AppColors.text,
        'position': const Offset(0, -100),
      },
      {
        'icon': Icons.location_city,
        'color': AppColors.text,
        'position': const Offset(100, -50),
      },
      {
        'icon': Icons.handshake_outlined,
        'color': AppColors.text,
        'position': const Offset(100, 50),
      },
      {
        'icon': Icons.trending_up,
        'color': AppColors.text,
        'position': const Offset(0, 100),
      },
      {
        'icon': Icons.forum_outlined,
        'color': AppColors.text,
        'position': const Offset(-100, 50),
      },
      {
        'icon': Icons.eco_outlined,
        'color': AppColors.text,
        'position': const Offset(-100, -50),
      },
    ];

    return icons.map((iconData) {
      return Positioned(
        left: 150 + (iconData['position']! as Offset).dx,
        top: 150 + (iconData['position']! as Offset).dy,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconData['color'] as Color,
            boxShadow: [
              BoxShadow(
                color: (iconData['color'] as Color).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            iconData['icon'] as IconData,
            color: Colors.white,
            size: 24,
          ),
        ),
      );
    }).toList();
  }
}