import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/post_models.dart';
import '../widgets/post_card.dart';
import '../utils/error_handler.dart';
import '../themes/app_theme.dart';

class MyPageScreen extends StatefulWidget {
  final String? userId;
  final bool isOwnPage;

  const MyPageScreen({
    super.key,
    this.userId,
    this.isOwnPage = false,
  });

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  List<PostModel> userPosts = [];
  bool isLoading = true;
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final targetUserId = widget.userId ?? AuthService.getCurrentUserId();
      if (targetUserId != null) {
        // ユーザーの投稿を取得
        final postsResult = await FirestoreService.getUserPosts(targetUserId);
        
        setState(() {
          if (postsResult.isSuccess) {
            userPosts = postsResult.data!;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // プロフィール部分
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: AppColors.text, width: 1),
              ),
            ),
            child: FutureBuilder<AppResult<Map<String, dynamic>?>>(
              future: widget.isOwnPage
                  ? AuthService.getUserData(AuthService.getCurrentUserId() ?? '')
                  : AuthService.getUserData(widget.userId ?? ''),
              builder: (context, snapshot) {
                final userName = (snapshot.data?.isSuccess == true && snapshot.data?.data != null) 
                    ? snapshot.data!.data!['name'] ?? 'ユーザー' 
                    : 'ユーザー';
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // アイコン
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.text, AppColors.text],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // 名前とボタン部分
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 名前
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // ユーザーハンドル
                          Text(
                            '@${userName.toLowerCase().replaceAll(' ', '')}',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // 投稿数
                          Text(
                            '投稿数: ${userPosts.length}件',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // ボタン
                          Row(
                            children: [
                              // 他人のページの場合はメッセージとフォローボタン
                              if (!widget.isOwnPage && widget.userId != AuthService.getCurrentUserId()) ...[
                                // メッセージボタン
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: メッセージ機能実装
                                  },
                                  icon: const Icon(Icons.mail_outline, size: 16),
                                  label: const Text('メッセージ'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.background,
                                    foregroundColor: AppColors.text,
                                    side: BorderSide(color: AppColors.text),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // フォローボタン
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: フォロー機能実装
                                  },
                                  icon: const Icon(Icons.person_add_outlined, size: 16),
                                  label: const Text('フォロー'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.text,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                              
                              // 自分のページの場合はプロフィール編集ボタン
                              if (widget.isOwnPage) ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: プロフィール編集機能実装
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('プロフィール編集'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.background,
                                    foregroundColor: AppColors.text,
                                    side: BorderSide(color: AppColors.text),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // 投稿一覧
          Expanded(
            child: userPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.background,
                          ),
                          child: Icon(
                            Icons.post_add_outlined,
                            size: 32,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isOwnPage ? 'まだ投稿がありません' : 'このユーザーはまだ投稿していません',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isOwnPage ? '最初の投稿をしてみましょう' : '',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: userPosts.length,
                    itemBuilder: (context, index) {
                      return PostCard(post: userPosts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}