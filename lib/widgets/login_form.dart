import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';
import '../constants/app_constants.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

/// ログイン・新規登録フォームのウィジェット
class LoginForm extends StatefulWidget {
  final bool isLogin;
  final VoidCallback? onSuccess;
  
  const LoginForm({
    super.key,
    this.isLogin = true,
    this.onSuccess,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      if (widget.isLogin) {
        final result = await AuthService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (result.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ErrorHandler.getSuccessMessage('ログイン')),
                backgroundColor: AppColors.text,
              ),
            );
            widget.onSuccess?.call();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.error!),
                backgroundColor: AppColors.text,
              ),
            );
          }
        }
      } else {
        final result = await AuthService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _usernameController.text.trim(),
        );
        
        if (result.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('アカウントが作成されました'),
                backgroundColor: AppColors.text,
              ),
            );
            widget.onSuccess?.call();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.error!),
                backgroundColor: AppColors.text,
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // ユーザー名（新規登録時のみ）
          if (!widget.isLogin) ...[
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'ユーザー名',
                hintText: 'ユーザー名を入力してください',
                prefixIcon: Icon(Icons.person, color: AppColors.text),
                border: const OutlineInputBorder(),
                errorStyle: TextStyle(color: AppColors.text),
              ),
              validator: Validators.validateUsername,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
          ],
          
          // メールアドレス
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'メールアドレス',
              hintText: 'example@domain.com',
              prefixIcon: Icon(Icons.email, color: AppColors.text),
              border: const OutlineInputBorder(),
              errorStyle: TextStyle(color: AppColors.text),
            ),
            validator: Validators.validateEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          
          // パスワード
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'パスワード',
              hintText: '6文字以上の英数字',
              prefixIcon: Icon(Icons.lock, color: AppColors.text),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.text,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: const OutlineInputBorder(),
              errorStyle: TextStyle(color: AppColors.text),
            ),
            validator: Validators.validatePassword,
            obscureText: _obscurePassword,
            textInputAction: widget.isLogin ? TextInputAction.done : TextInputAction.next,
          ),
          
          // パスワード確認（新規登録時のみ）
          if (!widget.isLogin) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'パスワード確認',
                hintText: '同じパスワードを入力してください',
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.text),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.text,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
                border: const OutlineInputBorder(),
                errorStyle: TextStyle(color: AppColors.text),
              ),
              validator: (value) => Validators.validateConfirmPassword(
                value,
                _passwordController.text,
              ),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
            ),
          ],
          
          const SizedBox(height: 24),
          
          // 送信ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.text,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    )
                  : Text(
                      widget.isLogin ? 'ログイン' : 'アカウント作成',
                      style: GoogleFonts.inter(
                        fontSize: AppConstants.fontSizeBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}