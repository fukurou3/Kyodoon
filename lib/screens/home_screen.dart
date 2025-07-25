import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/post_card.dart';
import '../models/post_models.dart';
import '../services/firestore_service.dart';
import '../themes/app_theme.dart';
import 'landing_page.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 気づきとアイデアの統合ビュー
                _buildIntegratedPostsSection(),
                
                // フッター
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntegratedPostsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最新の投稿',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          
          // 投稿一覧
          StreamBuilder<List<PostModel>>(
            stream: FirestoreService.getAllPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      Icon(
                        Icons.forum_outlined,
                        size: 64,
                        color: AppColors.text,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'まだ投稿がありません',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '最初の投稿をしてみませんか？',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final post = snapshot.data![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PostCard(post: post),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.text, width: 1),
        ),
      ),
      child: Column(
        children: [
          // フッターリンク
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsScreen()),
                  );
                },
                child: Text(
                  '利用規約',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                ' | ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  );
                },
                child: Text(
                  'プライバシーポリシー',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                ' | ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutKyodoonPage(),
                    ),
                  );
                },
                child: Text(
                  'Kyodoonについて',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // コピーライト
          Text(
            '© 2025 地域協働kyodoonプロジェクト',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// AboutKyodoonPageのインポート用（landing_page.dartから参照）