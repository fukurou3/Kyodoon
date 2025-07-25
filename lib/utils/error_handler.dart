import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// アプリケーション共通のエラーハンドラー
class ErrorHandler {
  /// エラーをログに記録し、ユーザーフレンドリーなメッセージを返す
  static String handleError(dynamic error, {String? context}) {
    // デバッグモードでは詳細なエラー情報を出力
    if (kDebugMode) {
      print('=== ERROR ${context != null ? '[$context]' : ''} ===');
      print('Error: $error');
      print('Error Type: ${error.runtimeType}');
      if (error is Error) {
        print('Stack Trace: ${error.stackTrace}');
      }
      print('================================');
    }
    
    // エラータイプに応じてユーザーフレンドリーなメッセージを返す
    return _getErrorMessage(error);
  }
  
  /// エラータイプに応じた適切なメッセージを生成
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // ネットワーク関連エラー
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return AppConstants.networkErrorMessage;
    }
    
    // 認証関連エラー
    if (errorString.contains('auth') ||
        errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return AppConstants.authErrorMessage;
    }
    
    // バリデーション関連エラー
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required') ||
        errorString.contains('format')) {
      return AppConstants.validationErrorMessage;
    }
    
    // Firebase固有のエラー
    if (errorString.contains('firebase')) {
      return _handleFirebaseError(errorString);
    }
    
    // その他の一般的なエラー
    return AppConstants.unknownErrorMessage;
  }
  
  /// Firebaseエラーの詳細処理
  static String _handleFirebaseError(String errorString) {
    if (errorString.contains('user-not-found')) {
      return 'ユーザーが見つかりません';
    }
    if (errorString.contains('wrong-password')) {
      return 'パスワードが間違っています';
    }
    if (errorString.contains('email-already-in-use')) {
      return 'このメールアドレスは既に使用されています';
    }
    if (errorString.contains('weak-password')) {
      return 'パスワードが弱すぎます';
    }
    if (errorString.contains('invalid-email')) {
      return 'メールアドレスの形式が正しくありません';
    }
    if (errorString.contains('operation-not-allowed')) {
      return 'この操作は許可されていません';
    }
    if (errorString.contains('quota-exceeded')) {
      return 'データベースの制限に達しました。しばらく経ってから再試行してください';
    }
    
    return 'サービスでエラーが発生しました';
  }
  
  /// 成功メッセージを取得
  static String getSuccessMessage(String action) {
    switch (action.toLowerCase()) {
      case 'post':
      case '投稿':
        return AppConstants.postSuccessMessage;
      case 'login':
      case 'ログイン':
        return 'ログインしました';
      case 'logout':
      case 'ログアウト':
        return 'ログアウトしました';
      case 'save':
      case '保存':
        return '保存しました';
      case 'delete':
      case '削除':
        return '削除しました';
      case 'update':
      case '更新':
        return '更新しました';
      default:
        return '操作が完了しました';
    }
  }
  
  /// 確認ダイアログ用メッセージ
  static String getConfirmationMessage(String action) {
    switch (action.toLowerCase()) {
      case 'delete':
      case '削除':
        return '本当に削除しますか？この操作は取り消せません。';
      case 'logout':
      case 'ログアウト':
        return 'ログアウトしますか？';
      case 'discard':
      case '破棄':
        return '変更を破棄しますか？';
      default:
        return '実行しますか？';
    }
  }
}

/// エラー結果を表すクラス
class AppResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  
  const AppResult._({this.data, this.error, required this.isSuccess});
  
  /// 成功結果を作成
  factory AppResult.success(T data) {
    return AppResult._(data: data, isSuccess: true);
  }
  
  /// エラー結果を作成
  factory AppResult.error(String error) {
    return AppResult._(error: error, isSuccess: false);
  }
  
  /// エラーハンドリング付きでエラー結果を作成
  factory AppResult.fromError(dynamic error, {String? context}) {
    final message = ErrorHandler.handleError(error, context: context);
    return AppResult._(error: message, isSuccess: false);
  }
}