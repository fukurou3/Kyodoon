import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_theme.dart';
import '../constants/app_constants.dart';

/// プライバシーポリシー画面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'プライバシーポリシー',
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
              'Kyodoon（地域活性化プラットフォーム）（以下「本サービス」）は、ユーザーの皆様のプライバシーを尊重し、個人情報を適切に保護することをお約束します。',
            ),
            _buildSection(
              '収集する情報',
              '''本サービスでは、以下の情報を収集させていただきます：

【アカウント情報】
• メールアドレス
• ユーザー名
• パスワード（暗号化して保存）

【投稿情報】
• 投稿内容（テキスト）
• 投稿日時
• 位置情報（任意）

【利用情報】
• アクセスログ
• 利用状況の統計情報''',
            ),
            _buildSection(
              '情報の利用目的',
              '''収集した情報は以下の目的で利用します：
• サービスの提供・運営
• ユーザーサポート
• サービスの改善・機能追加
• 不正利用の防止
• お知らせの配信''',
            ),
            _buildSection(
              '情報の共有・開示',
              '''個人情報は以下の場合を除き、第三者に開示いたしません：
• ユーザーの同意がある場合
• 法令に基づく開示が必要な場合
• 生命・身体の安全確保のため緊急の必要がある場合
• サービス運営に必要な業務委託先への提供（適切な管理の下）''',
            ),
            _buildSection(
              'データの保存・管理',
              '''• Google Firebase を利用したクラウドサービスで管理
• 適切なセキュリティ対策を実施
• 不要になった情報は適切に削除
• データセンターは主に米国・日本に所在''',
            ),
            _buildSection(
              'Cookieについて',
              'サービスの改善や利便性向上のため、Cookieを使用する場合があります。ブラウザの設定でCookieを無効にすることも可能です。',
            ),
            _buildSection(
              'ユーザーの権利',
              '''ユーザーは自身の個人情報について、以下の権利を有します：
• 個人情報の確認・修正
• 個人情報の削除
• 利用停止の請求
• データポータビリティの権利''',
            ),
            _buildSection(
              '第三者サービス',
              '''本サービスは以下の第三者サービスを利用しています：
• Google Firebase（認証・データベース）
• Google Fonts（フォント配信）

これらのサービスには各々のプライバシーポリシーが適用されます。''',
            ),
            _buildSection(
              'ポリシーの変更',
              '本プライバシーポリシーは必要に応じて変更される場合があります。重要な変更については事前にユーザーに通知いたします。',
            ),
            _buildSection(
              'お問い合わせ',
              '個人情報の取り扱いに関するご質問・ご要望は、アプリ内のお問い合わせ機能をご利用ください。',
            ),
            const SizedBox(height: 32),
            Text(
              '最終更新日：2024年12月',
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