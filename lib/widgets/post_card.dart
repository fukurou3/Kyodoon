import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/posts/domain/entities/post_entity.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'package:go_router/go_router.dart';
import '../providers/riverpod_providers.dart';
import '../themes/app_theme.dart';
import '../utils/security_validator.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostEntity post;

  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isHovered = false;

  /// セキュアなユーザー名生成（XSS対策含む）
  String _generateSafeUsername(String authorName) {
    // XSS攻撃チェック
    if (SecurityValidator.containsXssThreats(authorName)) {
      return 'user'; // 危険なコンテンツが検出された場合はデフォルト名
    }

    // HTMLエンティティをサニタイズ
    final sanitizedName = SecurityValidator.sanitizeHtml(authorName);
    
    // 安全な文字のみを使用してユーザー名を生成
    final safeName = sanitizedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]'), '')
        .replaceAll(' ', '');
    
    // 空文字列の場合はデフォルト名を返す
    if (safeName.isEmpty) {
      return 'user';
    }
    
    // 長さ制限（最大20文字）
    return safeName.length > 20 ? safeName.substring(0, 20) : safeName;
  }

  /// セキュアなテキスト表示（XSS対策含む）
  String _sanitizeDisplayText(String text) {
    // XSS攻撃チェック
    if (SecurityValidator.containsXssThreats(text)) {
      return '***'; // 危険なコンテンツが検出された場合は安全な文字列に置換
    }

    // HTMLエンティティをサニタイズ
    return SecurityValidator.sanitizeHtml(text);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.background : AppColors.background,
          border: Border(
            bottom: BorderSide(color: AppColors.text, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アバター
              GestureDetector(
                onTap: () {
                  // 自分の投稿の場合はマイページを表示
                  if (widget.post.authorId == currentUser?.id) {
                    context.go('/my-page');
                  } else {
                    // 他人のマイページを表示
                    context.go('/user/${widget.post.authorId}');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.post.type == PostType.casual 
                          ? [AppColors.text, AppColors.text]
                          : [AppColors.text, AppColors.text],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    widget.post.type == PostType.casual ? Icons.chat_bubble_outline : Icons.assignment_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // コンテンツ部分
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー情報
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // 自分の投稿の場合はマイページを表示
                            if (widget.post.authorId == currentUser?.id) {
                              context.go('/my-page');
                            } else {
                              // 他人のマイページを表示
                              context.go('/user/${widget.post.authorId}');
                            }
                          },
                          child: Text(
                            widget.post.authorName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: widget.post.authorId == currentUser?.id
                                  ? AppColors.text
                                  : AppColors.text, // 他人の名前
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '@${_generateSafeUsername(widget.post.authorName)}',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '·',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          app_date_utils.DateUtils.formatDateTime(widget.post.createdAt),
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                          ),
                        ),
                        // 告知バッジ
                        if (widget.post.isAnnouncement) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.text, width: 1),
                            ),
                            child: Text(
                              '告知',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // タイトル（真剣投稿のみ）
                    if (widget.post.title != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.text, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment, size: 14, color: AppColors.text),
                            const SizedBox(width: 4),
                            Text(
                              '真剣投稿',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.post.title!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // 内容
                    Text(
                      _sanitizeDisplayText(widget.post.content),
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                        height: 1.3,
                      ),
                    ),

                    // 位置情報
                    if (widget.post.municipality != null) ...[
                      const SizedBox(height: 12),
                      _buildLocationInfo(),
                    ],

                    // アクションボタン
                    const SizedBox(height: 12),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (widget.post.municipality != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.text, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_city, size: 14, color: AppColors.text),
            const SizedBox(width: 4),
            Text(
              _sanitizeDisplayText(widget.post.municipality!),
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          count: 0,
          color: AppColors.text,
          onTap: () {},
        ),
        const SizedBox(width: 32),
        _buildActionButton(
          icon: Icons.repeat,
          count: 0,
          color: AppColors.text,
          onTap: () {},
        ),
        const SizedBox(width: 32),
        _buildActionButton(
          icon: Icons.favorite_border,
          count: 0,
          color: AppColors.text,
          onTap: () {},
        ),
        const SizedBox(width: 32),
        _buildActionButton(
          icon: Icons.share_outlined,
          count: 0,
          color: AppColors.text,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}