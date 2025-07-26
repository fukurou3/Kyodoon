import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';
import '../constants/app_constants.dart';

/// 利用規約画面
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '利用規約',
          style: GoogleFonts.inter(
            fontSize: AppConstants.fontSizeHeading,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'はじめに',
              'この利用規約（以下「本規約」）は、Kyodoon（地域活性化プラットフォーム）の利用条件を定めるものです。本サービスをご利用いただくにあたり、本規約にご同意いただく必要があります。',
            ),
            _buildSection(
              'サービスの概要',
              '本サービスは、地域の課題解決やアイデア共有を目的としたプラットフォームです。ユーザーは投稿の作成、閲覧、コメントなどの機能をご利用いただけます。',
            ),
            _buildSection(
              '利用者の責任',
              '''• 正確な情報を提供し、虚偽の情報を投稿しないこと
• 他のユーザーや第三者の権利を尊重すること
• 法令を遵守し、公序良俗に反する行為を行わないこと
• 本サービスの運営を妨害する行為を行わないこと''',
            ),
            _buildSection(
              '禁止事項',
              '''本サービスにおいて、以下の行為を禁止します：
• 違法な内容の投稿
• 他者への嫌がらせや誹謗中傷
• 商業的な宣伝・勧誘
• システムへの不正アクセス
• その他、運営者が不適切と判断する行為''',
            ),
            _buildSection(
              '知的財産権',
              'ユーザーが投稿したコンテンツの著作権はユーザーに帰属しますが、本サービス内での表示・配信についてKyodoonに必要な権利を許諾していただきます。',
            ),
            _buildSection(
              'プライバシー',
              '個人情報の取り扱いについては、別途定めるプライバシーポリシーをご確認ください。',
            ),
            _buildSection(
              '免責事項',
              '''Kyodoonは以下について責任を負いません：
• ユーザー間のトラブル
• サービスの中断や停止
• ユーザーが投稿したコンテンツの内容
• 技術的な不具合による損害''',
            ),
            _buildSection(
              '規約の変更',
              '本規約は必要に応じて変更される場合があります。重要な変更については事前にユーザーに通知いたします。',
            ),
            _buildSection(
              'お問い合わせ',
              '本規約に関するご質問は、アプリ内のお問い合わせ機能をご利用ください。',
            ),
            const SizedBox(height: 32),
            Text(
              '最終更新日：2025年7月26日',
              style: GoogleFonts.inter(
                fontSize: AppConstants.fontSizeCaption,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: AppConstants.fontSizeHeading,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: AppConstants.fontSizeBody,
              color: AppColors.text,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}