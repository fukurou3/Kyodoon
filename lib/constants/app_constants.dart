class AppConstants {
  // アプリケーション情報
  static const String appName = 'Kyodoon';
  static const String appVersion = '1.0.0';
  
  // 投稿関連
  static const int maxTweetLength = 280;
  static const int maxTitleLength = 100;
  static const int maxContentLength = 1000;
  
  // UI関連のサイズ
  static const double modalMaxWidth = 800.0;
  static const double modalMargin = 20.0;
  static const double modalPadding = 20.0;
  static const double cardPadding = 16.0;
  static const double buttonPadding = 12.0;
  
  // フォントサイズ
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeading = 18.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeCaption = 14.0;
  static const double fontSizeSmall = 12.0;
  
  // 境界線・角丸
  static const double borderRadius = 8.0;
  static const double buttonBorderRadius = 15.0;
  static const double cardBorderRadius = 12.0;
  
  // アニメーション
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Firestore コレクション名
  static const String postsCollection = 'posts';
  static const String usersCollection = 'users';
  
  // 投稿タイプ
  static const String casualPostType = 'casual';
  static const String seriousPostType = 'serious';
  
  // エラーメッセージ
  static const String networkErrorMessage = 'ネットワークエラーが発生しました';
  static const String authErrorMessage = '認証エラーが発生しました';
  static const String unknownErrorMessage = '予期しないエラーが発生しました';
  static const String postSuccessMessage = '投稿しました';
  static const String postFailedMessage = '投稿に失敗しました';
  static const String loginRequiredMessage = 'ログインが必要です';
  static const String validationErrorMessage = '入力内容を確認してください';
}