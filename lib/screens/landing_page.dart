import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/hero_section.dart';
import '../features/posts/domain/entities/post_entity.dart';
import '../features/posts/presentation/providers/posts_provider.dart';
import '../widgets/post_card.dart';
import '../themes/app_theme.dart';

class AboutKyodoonPage extends StatefulWidget {
  const AboutKyodoonPage({super.key});

  @override
  State<AboutKyodoonPage> createState() => _AboutKyodoonPageState();
}

class _AboutKyodoonPageState extends State<AboutKyodoonPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ヒーローセクション
            const HeroSection(),
            
            // 新着情報・注目トピックセクション
            _buildFeaturedSection(),
            
            // サイト紹介セクション
            _buildAboutSection(),
            
            // 地域ピックアップセクション
            _buildRegionPickupSection(),
            
            // フッター
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: AppColors.background,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // セクションタイトル
              Text(
                '新着アイデア・注目トピック',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '最新の地域課題やアイデア、活発に議論されているトピックをチェック',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 48),
              
              // 投稿一覧
              Row(
                children: [
                  // カジュアル投稿
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.text,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                '気づき・つぶやき',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Consumer<PostsProvider>(
                            builder: (context, postsProvider, child) {
                              return StreamBuilder<List<PostEntity>>(
                                stream: postsProvider.getCasualPosts(limit: 3),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return _buildEmptyState(
                                  icon: Icons.chat_bubble_outline,
                                  text: 'まだ投稿がありません',
                                );
                              }
                              
                              return Column(
                                children: snapshot.data!
                                    .map((post) => PostCard(post: post))
                                    .toList(),
                              );
                            },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 32),
                  
                  // 真剣投稿
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.text,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                '課題・アイデア提案',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Consumer<PostsProvider>(
                            builder: (context, postsProvider, child) {
                              return StreamBuilder<List<PostEntity>>(
                                stream: postsProvider.getSeriousPosts(limit: 3),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return _buildEmptyState(
                                  icon: Icons.assignment_outlined,
                                  text: 'まだ提案がありません',
                                );
                              }
                              
                              return Column(
                                children: snapshot.data!
                                    .map((post) => PostCard(post: post))
                                    .toList(),
                              );
                            },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'このプラットフォームでできること',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 48),
              
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.lightbulb_outline,
                      color: AppColors.text,
                      title: 'アイデアを共有',
                      description: '地域の課題解決や活性化につながるアイデアを自由に投稿・共有できます。',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.groups_outlined,
                      color: AppColors.text,
                      title: '仲間と協力',
                      description: '同じ想いを持つ人々とつながり、一緒にプロジェクトを進めることができます。',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.trending_up_outlined,
                      color: AppColors.text,
                      title: '実現する',
                      description: 'アイデアから具体的なアクションへ。地域の変化を実際に起こします。',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionPickupSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: AppColors.background,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                '注目の地域',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '活発な活動が行われている地域をピックアップ',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 48),
              
              Row(
                children: [
                  Expanded(
                    child: _buildRegionCard(
                      '東京都渋谷区',
                      '23件のプロジェクト',
                      '156人が参加',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildRegionCard(
                      '京都府京都市',
                      '18件のプロジェクト',
                      '94人が参加',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildRegionCard(
                      '福岡県福岡市',
                      '12件のプロジェクト',
                      '78人が参加',
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      color: AppColors.text,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                '地域と人がつながり、未来を共創する',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '© 2025 地域協働kyodoonプロジェクト',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.text),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(color: AppColors.text),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.text,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(
    String region,
    String projects,
    String participants,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                region,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            projects,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            participants,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}