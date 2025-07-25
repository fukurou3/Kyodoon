import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';
import '../constants/app_constants.dart';

/// 共通のモーダルベースクラス
class BaseModal extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double? maxWidth;
  final double? maxHeight;
  
  const BaseModal({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? AppConstants.modalMaxWidth,
            maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.modalMargin),
            padding: const EdgeInsets.all(AppConstants.modalPadding),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.text.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: AppConstants.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.close,
            color: AppColors.text,
          ),
          onPressed: onClose ?? () => Navigator.pop(context),
          tooltip: '閉じる',
        ),
      ],
    );
  }
}

/// 共通のスクロール可能モーダル
class ScrollableModal extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double? maxWidth;
  final double? maxHeight;
  
  const ScrollableModal({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: title,
      onClose: onClose,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }
}

/// 共通のボタンスタイル
class ModalButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final double? width;
  
  const ModalButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.width,
  });

  factory ModalButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
  }) {
    return ModalButton(
      key: key,
      text: text,
      onPressed: onPressed,
      backgroundColor: AppColors.text,
      foregroundColor: AppColors.background,
      isLoading: isLoading,
      width: width,
    );
  }

  factory ModalButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
  }) {
    return ModalButton(
      key: key,
      text: text,
      onPressed: onPressed,
      backgroundColor: AppColors.text,
      foregroundColor: AppColors.background,
      isLoading: isLoading,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.text,
          foregroundColor: foregroundColor ?? AppColors.background,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: AppConstants.buttonPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Text(text),
      ),
    );
  }
}