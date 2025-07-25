import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../themes/app_theme.dart';
import '../constants/app_constants.dart';
import '../utils/error_handler.dart';
import '../utils/validators.dart';
import 'login_modal.dart';

class CasualPostModal extends StatefulWidget {
  const CasualPostModal({super.key});

  @override
  State<CasualPostModal> createState() => _CasualPostModalState();
}

class _CasualPostModalState extends State<CasualPostModal> {
  final _tweetController = TextEditingController();
  bool _isPosting = false;
  bool _isAnnouncement = false;

  @override
  void initState() {
    super.initState();
    _tweetController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tweetController.dispose();
    super.dispose();
  }

  Future<void> _showLoginModal() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LoginModal(),
    );
    
    if (result == true) {
      _postTweet();
    }
  }

  Future<void> _postTweet() async {
    // バリデーションチェック
    final contentError = Validators.validatePostContent(
      _tweetController.text, 
      maxLength: AppConstants.maxTweetLength,
    );
    
    if (contentError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contentError),
          backgroundColor: AppColors.text,
        ),
      );
      return;
    }
    
    if (!AuthService.isLoggedIn) {
      _showLoginModal();
      return;
    }
    
    setState(() => _isPosting = true);
    
    final result = await FirestoreService.createCasualPost(
      _tweetController.text.trim(),
      isAnnouncement: _isAnnouncement,
    );
    
    if (mounted) {
      setState(() => _isPosting = false);
      
      if (result.isSuccess) {
        _tweetController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getSuccessMessage('投稿'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? ErrorHandler.handleError('不明なエラーが発生しました')),
            backgroundColor: AppColors.text,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.modalMaxWidth),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.modalMargin),
            padding: const EdgeInsets.all(AppConstants.modalPadding),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '気づき・つぶやき',
                  style: GoogleFonts.inter(
                    fontSize: AppConstants.fontSizeTitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder(
                  stream: AuthService.authStateChanges,
                  builder: (context, snapshot) {
                    return CircleAvatar(
                      backgroundColor: snapshot.hasData ? AppColors.background : AppColors.background,
                      child: Icon(
                        Icons.person, 
                        color: snapshot.hasData ? AppColors.text : AppColors.text,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      StreamBuilder(
                        stream: AuthService.authStateChanges,
                        builder: (context, snapshot) {
                          return TextField(
                            controller: _tweetController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: snapshot.hasData ? 'いまどうしてる？' : 'ツイートするにはログインしてください',
                              border: const OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: AppConstants.fontSizeBody),
                            onTap: snapshot.hasData ? null : _showLoginModal,
                            readOnly: !snapshot.hasData,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // 告知選択ボタン
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAnnouncement = !_isAnnouncement;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isAnnouncement ? AppColors.text : AppColors.background,
                                borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                              ),
                              child: Text(
                                _isAnnouncement ? '告知する' : '告知しない',
                                style: TextStyle(
                                  color: _isAnnouncement ? AppColors.background : AppColors.text,
                                  fontSize: AppConstants.fontSizeSmall,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppConstants.maxTweetLength - _tweetController.text.length}',
                            style: TextStyle(
                              color: _tweetController.text.length > AppConstants.maxTweetLength 
                                  ? AppColors.text 
                                  : AppColors.text,
                            ),
                          ),
                          StreamBuilder(
                            stream: AuthService.authStateChanges,
                            builder: (context, snapshot) {
                              final isLoggedIn = snapshot.hasData;
                              final hasText = _tweetController.text.trim().isNotEmpty;
                              
                              return ElevatedButton(
                                onPressed: (_isPosting || !hasText) ? null : _postTweet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (isLoggedIn && hasText) ? AppColors.text : AppColors.text,
                                  foregroundColor: AppColors.background,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: AppConstants.buttonPadding),
                                ),
                                child: _isPosting
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.background,
                                        ),
                                      )
                                    : Text(isLoggedIn ? 'ツイート' : 'ログインして投稿'),
                              );
                            },
                          ),
                        ],
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
      ),
    );
  }
}