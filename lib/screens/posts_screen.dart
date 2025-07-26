import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/posts/domain/entities/post_entity.dart';
import '../features/posts/presentation/providers/posts_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/casual_post_modal.dart';
import '../widgets/serious_post_modal.dart';
import '../themes/app_theme.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> with SingleTickerProviderStateMixin {
  PostType _selectedType = PostType.casual;

  void _showPostModal() {
    if (_selectedType == PostType.casual) {
      showDialog(
        context: context,
        builder: (context) => const CasualPostModal(),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const SeriousPostModal(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
              children: [
              // セグメントコントロール
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = PostType.casual),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == PostType.casual 
                            ? AppColors.text 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble,
                            size: 20,
                            color: _selectedType == PostType.casual 
                                ? AppColors.background 
                                : AppColors.text,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '気づき・つぶやき',
                            style: TextStyle(
                              color: _selectedType == PostType.casual 
                                  ? AppColors.background 
                                  : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = PostType.serious),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == PostType.serious 
                            ? AppColors.text 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb,
                            size: 20,
                            color: _selectedType == PostType.serious 
                                ? AppColors.background 
                                : AppColors.text,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '課題・アイデア提案',
                            style: TextStyle(
                              color: _selectedType == PostType.serious 
                                  ? AppColors.background 
                                  : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 投稿リスト
          Expanded(
            child: Consumer<PostsProvider>(
              builder: (context, postsProvider, child) {
                return StreamBuilder<List<PostEntity>>(
                  stream: postsProvider.getPostsStream(_selectedType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'エラーが発生しました: ${snapshot.error}',
                      style: TextStyle(color: AppColors.text),
                    ),
                  );
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedType == PostType.casual 
                              ? Icons.chat_bubble_outline 
                              : Icons.lightbulb_outline,
                          size: 64,
                          color: AppColors.text,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedType == PostType.casual 
                              ? 'まだ気づきがありません\n最初の投稿をしてみませんか？'
                              : 'まだアイデアがありません\n最初の提案をしてみませんか？',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(post: post),
                    );
                  },
                );
              },
                );
              },
            ),
          ),
              ],
            ),
          ),
        ),
        
        // フローティングアクションボタン（右下固定）
        Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: _showPostModal,
              backgroundColor: _selectedType == PostType.casual 
                  ? AppColors.text 
                  : AppColors.text,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}