import 'package:flutter/material.dart';
import '../models/post_models.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../utils/navigation_helper.dart';
import '../services/auth_service.dart';
import '../themes/app_theme.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
                  if (widget.post.authorId == AuthService.getCurrentUserId()) {
                    NavigationHelper.showMyPage();
                  } else {
                    // 他人のマイページを表示
                    NavigationHelper.showUserPage(widget.post.authorId);
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
                            if (widget.post.authorId == AuthService.getCurrentUserId()) {
                              NavigationHelper.showMyPage();
                            } else {
                              // 他人のマイページを表示
                              NavigationHelper.showUserPage(widget.post.authorId);
                            }
                          },
                          child: Text(
                            widget.post.authorName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: widget.post.authorId == AuthService.getCurrentUserId()
                                  ? AppColors.text
                                  : AppColors.text, // 他人の名前
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '@${widget.post.authorName.toLowerCase().replaceAll(' ', '')}',
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
                      widget.post.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                        height: 1.3,
                      ),
                    ),

                    // 位置情報
                    if (widget.post.hasLocation) ...[
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
              widget.post.municipality!,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (widget.post.municipality != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.text, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.text),
                const SizedBox(width: 4),
                Text(
                  '詳細位置',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (widget.post.municipality != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  widget.post.municipality!,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
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