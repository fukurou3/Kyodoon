import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/posts/presentation/providers/posts_provider.dart';
import '../constants/japan_municipalities.dart';
import '../themes/app_theme.dart';
import '../constants/app_constants.dart';
import '../utils/error_handler.dart';
import '../utils/validators.dart';
import 'login_modal.dart';

class SeriousPostModal extends StatefulWidget {
  const SeriousPostModal({super.key});

  @override
  State<SeriousPostModal> createState() => _SeriousPostModalState();
}

class _SeriousPostModalState extends State<SeriousPostModal> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPosting = false;
  bool _isAnnouncement = false;
  
  String? _selectedMunicipality;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _showLoginModal() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LoginModal(),
    );
    
    if (result == true) {
      _postSerious();
    }
  }

  Future<void> _postSerious() async {
    // バリデーションチェック
    final titleError = Validators.validatePostTitle(
      _titleController.text,
      maxLength: AppConstants.maxTitleLength,
    );
    final contentError = Validators.validatePostContent(
      _contentController.text,
      maxLength: AppConstants.maxContentLength,
    );
    
    if (titleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(titleError),
          backgroundColor: AppColors.text,
        ),
      );
      return;
    }
    
    if (contentError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contentError),
          backgroundColor: AppColors.text,
        ),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      _showLoginModal();
      return;
    }
    
    setState(() => _isPosting = true);
    
    try {
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      await postsProvider.createSeriousPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        municipality: _selectedMunicipality,
        isAnnouncement: _isAnnouncement,
      );
      
      if (mounted) {
        _resetForm();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getSuccessMessage('投稿'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.handleError('投稿に失敗しました')),
            backgroundColor: AppColors.text,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedMunicipality = null;
      _isAnnouncement = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.modalMaxWidth),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
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
                  '課題・アイデア提案',
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
            Expanded(
              child: SingleChildScrollView(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final isLoggedIn = authProvider.isLoggedIn;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: isLoggedIn ? 'タイトル（例：○○の仲間募集、△△の課題報告）' : 'ログインして投稿',
                            border: const OutlineInputBorder(),
                            labelText: 'タイトル',
                          ),
                          onTap: isLoggedIn ? null : _showLoginModal,
                          readOnly: !isLoggedIn,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contentController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: isLoggedIn ? '詳細な内容を記入してください' : 'ログインして投稿',
                            border: const OutlineInputBorder(),
                            labelText: '内容',
                          ),
                          onTap: isLoggedIn ? null : _showLoginModal,
                          readOnly: !isLoggedIn,
                        ),
                        const SizedBox(height: 16),
                        
                        // 位置情報選択（市区町村のみ）
                        if (isLoggedIn) ...[
                          Text('位置情報（任意）', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownSearch<String>(
                            items: japanMunicipalities,
                            selectedItem: _selectedMunicipality,
                            onChanged: (value) {
                              setState(() {
                                _selectedMunicipality = value;
                              });
                            },
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: '市区町村を選択（任意）',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: const TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: '検索...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        // 告知選択ボタン
                        if (isLoggedIn) ...[
                          const SizedBox(height: 16),
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
                        ],
                        
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isLoggedIn && 
                                       _titleController.text.trim().isNotEmpty && 
                                       _contentController.text.trim().isNotEmpty && 
                                       !_isPosting) 
                                ? _postSerious 
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.text,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isPosting
                                ? CircularProgressIndicator(color: AppColors.background)
                                : Text(isLoggedIn ? '真剣投稿' : 'ログインして投稿'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}