
/// セキュリティ関連のバリデーションとサニタイズを行うクラス
class SecurityValidator {
  
  // 危険なHTMLタグやJavaScriptを検出するパターン
  static final List<RegExp> _dangerousPatterns = [
    RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, multiLine: true, dotAll: true),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'on\w+\s*=', caseSensitive: false), // onclick, onerror, etc.
    RegExp(r'<iframe[^>]*>', caseSensitive: false),
    RegExp(r'<object[^>]*>', caseSensitive: false),
    RegExp(r'<embed[^>]*>', caseSensitive: false),
    RegExp(r'<link[^>]*>', caseSensitive: false),
    RegExp(r'<meta[^>]*>', caseSensitive: false),
    RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, multiLine: true, dotAll: true),
    RegExp(r'expression\s*\(', caseSensitive: false),
    RegExp(r'vbscript:', caseSensitive: false),
    RegExp(r'livescript:', caseSensitive: false),
    RegExp(r'mocha:', caseSensitive: false),
  ];

  /// テキスト内容のXSS攻撃をチェック
  static bool containsXssThreats(String content) {
    if (content.isEmpty) return false;
    
    return _dangerousPatterns.any((pattern) => pattern.hasMatch(content));
  }

  /// HTMLコンテンツをサニタイズ（危険なタグ・属性を除去）
  static String sanitizeHtml(String content) {
    if (content.isEmpty) return content;
    
    String sanitized = content;
    
    // 危険なパターンを除去
    for (final pattern in _dangerousPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }
    
    // HTMLエンティティエンコード
    sanitized = _htmlEncode(sanitized);
    
    return sanitized;
  }

  /// 投稿内容のバリデーション
  static ValidationResult validatePostContent(String content) {
    if (content.isEmpty) {
      return ValidationResult(false, '投稿内容を入力してください');
    }
    
    if (content.length > 2000) {
      return ValidationResult(false, '投稿内容は2000文字以内で入力してください');
    }
    
    if (containsXssThreats(content)) {
      return ValidationResult(false, '不正なコンテンツが検出されました');
    }
    
    // 連続する空白文字をチェック
    if (RegExp(r'\s{10,}').hasMatch(content)) {
      return ValidationResult(false, '過度な空白文字は使用できません');
    }
    
    return ValidationResult(true, null);
  }

  /// コメント内容のバリデーション
  static ValidationResult validateCommentContent(String content) {
    if (content.isEmpty) {
      return ValidationResult(false, 'コメント内容を入力してください');
    }
    
    if (content.length > 500) {
      return ValidationResult(false, 'コメントは500文字以内で入力してください');
    }
    
    if (containsXssThreats(content)) {
      return ValidationResult(false, '不正なコンテンツが検出されました');
    }
    
    return ValidationResult(true, null);
  }

  /// ユーザー名のバリデーション
  static ValidationResult validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationResult(false, 'ユーザー名を入力してください');
    }
    
    if (username.length > 50) {
      return ValidationResult(false, 'ユーザー名は50文字以内で入力してください');
    }
    
    // 使用可能文字チェック（英数字、日本語、一部記号のみ）
    if (!RegExp(r'^[a-zA-Z0-9\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF_\-\.]+$').hasMatch(username)) {
      return ValidationResult(false, 'ユーザー名に使用できない文字が含まれています');
    }
    
    // 危険なパターンチェック
    if (containsXssThreats(username)) {
      return ValidationResult(false, '不正な文字が含まれています');
    }
    
    return ValidationResult(true, null);
  }

  /// メールアドレスのバリデーション
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult(false, 'メールアドレスを入力してください');
    }
    
    // 基本的なメール形式チェック
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return ValidationResult(false, '正しいメールアドレス形式で入力してください');
    }
    
    if (email.length > 254) {
      return ValidationResult(false, 'メールアドレスが長すぎます');
    }
    
    return ValidationResult(true, null);
  }

  /// パスワードの強度チェック
  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(false, 'パスワードを入力してください');
    }
    
    if (password.length < 8) {
      return ValidationResult(false, 'パスワードは8文字以上で入力してください');
    }
    
    if (password.length > 128) {
      return ValidationResult(false, 'パスワードは128文字以内で入力してください');
    }
    
    // 強度チェック
    bool hasLower = RegExp(r'[a-z]').hasMatch(password);
    bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    bool hasDigit = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    int strength = 0;
    if (hasLower) strength++;
    if (hasUpper) strength++;
    if (hasDigit) strength++;
    if (hasSpecial) strength++;
    
    if (strength < 3) {
      return ValidationResult(false, 'パスワードは英大文字、英小文字、数字、記号のうち3種類以上を含めてください');
    }
    
    return ValidationResult(true, null);
  }

  /// 文字をHTMLエンティティにエンコード
  static String _htmlEncode(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// SQLインジェクション対策（Firestoreでは不要だが、将来的な拡張のため）
  static bool containsSqlInjectionThreats(String input) {
    final sqlPatterns = [
      RegExp(r'(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)', caseSensitive: false),
      RegExp(r'(\b(OR|AND)\s+\d+\s*=\s*\d+\b)', caseSensitive: false),
      RegExp(r'''[';\"]\s*(OR|AND|UNION)''', caseSensitive: false),
      RegExp(r'--', caseSensitive: false),
      RegExp(r'/\*.*\*/', caseSensitive: false),
    ];
    
    return sqlPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// 一般的な入力フィールドのサニタイズ
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
    // 先頭・末尾の空白除去
    String sanitized = input.trim();
    
    // 連続する空白を単一に変換
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // 制御文字を除去
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    return sanitized;
  }
}

/// バリデーション結果を格納するクラス
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  ValidationResult(this.isValid, this.errorMessage);
  
  bool get hasError => !isValid;
}