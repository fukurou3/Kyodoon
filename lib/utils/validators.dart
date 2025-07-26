import 'security_validator.dart';

/// アプリケーション共通のバリデーション機能
class Validators {
  /// メールアドレスのバリデーション
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'メールアドレスの形式が正しくありません';
    }
    
    return null;
  }
  
  /// パスワードのバリデーション
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    
    if (value.length < 6) {
      return 'パスワードは6文字以上で入力してください';
    }
    
    // 英数字を含む場合の推奨チェック
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      return 'パスワードは英字と数字を組み合わせてください';
    }
    
    return null;
  }
  
  /// 投稿内容のバリデーション（XSS対策強化版）
  static String? validatePostContent(String? value, {int maxLength = 280}) {
    if (value == null || value.isEmpty) {
      return '内容を入力してください';
    }
    
    if (value.trim().isEmpty) {
      return '内容を入力してください';
    }
    
    if (value.length > maxLength) {
      return '$maxLength文字以内で入力してください';
    }
    
    // XSS対策: SecurityValidatorを使用した包括的な検証
    final securityValidation = SecurityValidator.validatePostContent(value);
    if (!securityValidation.isValid) {
      return securityValidation.errorMessage;
    }
    
    return null;
  }
  
  /// 投稿タイトルのバリデーション（XSS対策強化版）
  static String? validatePostTitle(String? value, {int maxLength = 100}) {
    if (value == null || value.isEmpty) {
      return 'タイトルを入力してください';
    }
    
    if (value.trim().isEmpty) {
      return 'タイトルを入力してください';
    }
    
    if (value.length > maxLength) {
      return '$maxLength文字以内で入力してください';
    }
    
    // XSS対策: SecurityValidatorを使用した包括的な検証
    final securityValidation = SecurityValidator.validatePostTitle(value);
    if (!securityValidation.isValid) {
      return securityValidation.errorMessage;
    }
    
    return null;
  }
  
  /// コメント内容のバリデーション（XSS対策強化版）
  static String? validateCommentContent(String? value, {int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return 'コメント内容を入力してください';
    }
    
    if (value.trim().isEmpty) {
      return 'コメント内容を入力してください';
    }
    
    if (value.length > maxLength) {
      return '$maxLength文字以内で入力してください';
    }
    
    // XSS対策: SecurityValidatorを使用した包括的な検証
    final securityValidation = SecurityValidator.validateCommentContent(value);
    if (!securityValidation.isValid) {
      return securityValidation.errorMessage;
    }
    
    return null;
  }
  
  /// ユーザー名のバリデーション
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'ユーザー名を入力してください';
    }
    
    if (value.trim().isEmpty) {
      return 'ユーザー名を入力してください';
    }
    
    if (value.length < 2) {
      return 'ユーザー名は2文字以上で入力してください';
    }
    
    if (value.length > 50) {
      return 'ユーザー名は50文字以内で入力してください';
    }
    
    // 使用可能文字のチェック（ひらがな、カタカナ、漢字、英数字、アンダースコア、ハイフン）
    if (!RegExp(r'^[a-zA-Z0-9\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF_-]+$').hasMatch(value)) {
      return 'ユーザー名に使用できない文字が含まれています';
    }
    
    return null;
  }
  
  /// URL のバリデーション
  static String? validateUrl(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'URLを入力してください' : null;
    }
    
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return '有効なURLを入力してください（http://またはhttps://）';
      }
    } catch (e) {
      return '有効なURLを入力してください';
    }
    
    return null;
  }
  
  /// 電話番号のバリデーション（日本の電話番号形式）
  static String? validatePhoneNumber(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? '電話番号を入力してください' : null;
    }
    
    // ハイフンを除去
    final cleanValue = value.replaceAll('-', '').replaceAll(' ', '');
    
    // 日本の電話番号形式をチェック
    if (!RegExp(r'^(0[5-9]\d{8}|0[1-4]\d{9})$').hasMatch(cleanValue)) {
      return '有効な電話番号を入力してください';
    }
    
    return null;
  }
  
  /// 複数の値が一致するかのバリデーション（パスワード確認用）
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return '確認用パスワードを入力してください';
    }
    
    if (value != originalPassword) {
      return 'パスワードが一致しません';
    }
    
    return null;
  }
  
  /// 必須項目のバリデーション
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return '$fieldNameを入力してください';
    }
    return null;
  }
  
  /// 数値のバリデーション
  static String? validateNumber(String? value, {bool required = true, int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return required ? '数値を入力してください' : null;
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return '有効な数値を入力してください';
    }
    
    if (min != null && number < min) {
      return '$min以上の数値を入力してください';
    }
    
    if (max != null && number > max) {
      return '$max以下の数値を入力してください';
    }
    
    return null;
  }
}

/// フォーム全体のバリデーション結果を管理するクラス
class ValidationResult {
  final Map<String, String?> _errors = {};
  
  /// エラーメッセージを追加
  void addError(String field, String? error) {
    _errors[field] = error;
  }
  
  /// 特定フィールドのエラーを取得
  String? getError(String field) {
    return _errors[field];
  }
  
  /// エラーがあるかチェック
  bool get hasErrors => _errors.values.any((error) => error != null);
  
  /// エラーの数を取得
  int get errorCount => _errors.values.where((error) => error != null).length;
  
  /// 全エラーをクリア
  void clear() {
    _errors.clear();
  }
  
  /// 特定フィールドのエラーをクリア
  void clearField(String field) {
    _errors[field] = null;
  }
}