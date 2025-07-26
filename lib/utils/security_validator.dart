
import '../features/profile/domain/entities/user_preferences_entity.dart';

/// セキュリティ関連のバリデーションとサニタイズを行うクラス
class SecurityValidator {
  
  // 高度なXSS攻撃を検出する危険パターン（大文字小文字混在、エンコーディング対応）
  static final List<RegExp> _dangerousPatterns = [
    // HTMLタグ（大文字小文字混在、スペース、改行対応）
    RegExp(r'<\s*[sS][cC][rR][iI][pP][tT][^>]*>.*?</\s*[sS][cC][rR][iI][pP][tT]\s*>', dotAll: true),
    RegExp(r'<\s*[iI][fF][rR][aA][mM][eE][^>]*>', caseSensitive: false),
    RegExp(r'<\s*[oO][bB][jJ][eE][cC][tT][^>]*>', caseSensitive: false),
    RegExp(r'<\s*[eE][mM][bB][eE][dD][^>]*>', caseSensitive: false),
    RegExp(r'<\s*[fF][oO][rR][mM][^>]*>', caseSensitive: false),
    RegExp(r'<\s*[iI][nN][pP][uU][tT][^>]*>', caseSensitive: false),
    RegExp(r'<\s*[mM][eE][tT][aA][^>]*>', caseSensitive: false),
    RegExp(r'<\s*[lL][iI][nN][kK][^>]*>', caseSensitive: false),
    RegExp(r'<\s*[sS][tT][yY][lL][eE][^>]*>.*?</\s*[sS][tT][yY][lL][eE]\s*>', dotAll: true),
    RegExp(r'<\s*[bB][aA][sS][eE][^>]*>', caseSensitive: false),
    
    // JavaScript実行（エンコーディング対応）
    RegExp(r'[jJ][aA][vV][aA][sS][cC][rR][iI][pP][tT]\s*:'),
    RegExp(r'[vV][bB][sS][cC][rR][iI][pP][tT]\s*:'),
    RegExp(r'[dD][aA][tT][aA]\s*:'),
    RegExp(r'[mM][oO][cC][hH][aA]\s*:'),
    RegExp(r'[lL][iI][vV][eE][sS][cC][rR][iI][pP][tT]\s*:'),
    
    // イベントハンドラー（包括的）
    RegExp(r'[oO][nN]\w+\s*='),
    RegExp(r'[oO][nN][cC][lL][iI][cC][kK]\s*='),
    RegExp(r'[oO][nN][lL][oO][aA][dD]\s*='),
    RegExp(r'[oO][nN][eE][rR][rR][oO][rR]\s*='),
    RegExp(r'[oO][nN][fF][oO][cC][uU][sS]\s*='),
    RegExp(r'[oO][nN][bB][lL][uU][rR]\s*='),
    RegExp(r'[oO][nN][mM][oO][uU][sS][eE][oO][vV][eE][rR]\s*='),
    RegExp(r'[oO][nN][mM][oO][uU][sS][eE][oO][uU][tT]\s*='),
    RegExp(r'[oO][nN][kK][eE][yY][dD][oO][wW][nN]\s*='),
    RegExp(r'[oO][nN][kK][eE][yY][uU][pP]\s*='),
    RegExp(r'[oO][nN][sS][uU][bB][mM][iI][tT]\s*='),
    
    // 評価系関数
    RegExp(r'[eE][vV][aA][lL]\s*\('),
    RegExp(r'[fF][uU][nN][cC][tT][iI][oO][nN]\s*\('),
    RegExp(r'[sS][eE][tT][tT][iI][mM][eE][oO][uU][tT]\s*\('),
    RegExp(r'[sS][eE][tT][iI][nN][tT][eE][rR][vV][aA][lL]\s*\('),
    RegExp(r'[eE][xX][eE][cC][sS][cC][rR][iI][pP][tT]\s*\('),
    RegExp(r'[eE][xX][pP][rR][eE][sS][sS][iI][oO][nN]\s*\('),
    
    // HTMLエンティティエンコーディング攻撃
    RegExp(r'&#x?[0-9a-fA-F]+;'),
    RegExp(r'&[a-zA-Z][a-zA-Z0-9]+;'),
    
    // URLエンコーディング攻撃
    RegExp(r'%[0-9a-fA-F]{2}'),
    RegExp(r'\\u[0-9a-fA-F]{4}'),
    RegExp(r'\\x[0-9a-fA-F]{2}'),
    
    // Unicode制御文字
    RegExp(r'[\u0000-\u001F\u007F-\u009F]'),
    RegExp(r'[\u200B-\u200D\uFEFF]'), // Zero-width characters
    
    // Base64エンコーディングによる攻撃
    RegExp(r'[dD][aA][tT][aA]:[^;]*;[bB][aA][sS][eE]64,'),
    
    // CSS式による攻撃
    RegExp(r'[bB][eE][hH][aA][vV][iI][oO][rR]\s*:'),
    RegExp(r'-[mM][oO][zZ]-[bB][iI][nN][dD][iI][nN][gG]'),
    
    // XMLエンティティ攻撃
    RegExp(r'<!ENTITY'),
    RegExp(r'<!DOCTYPE'),
    RegExp(r'<!\[CDATA\['),
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

  /// 投稿タイトルのバリデーション
  static ValidationResult validatePostTitle(String title) {
    if (title.isEmpty) {
      return ValidationResult(false, 'タイトルを入力してください');
    }
    
    if (title.length > 100) {
      return ValidationResult(false, 'タイトルは100文字以内で入力してください');
    }
    
    if (containsXssThreats(title)) {
      return ValidationResult(false, '不正なコンテンツが検出されました');
    }
    
    // 連続する空白文字をチェック
    if (RegExp(r'\s{5,}').hasMatch(title)) {
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

  /// 強化されたHTMLエンティティエンコーディング
  static String _htmlEncode(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .replaceAll('\n', '&#10;')
        .replaceAll('\r', '&#13;')
        .replaceAll('\t', '&#9;')
        .replaceAll('\u0000', '') // NULL文字除去
        .replaceAll('\u200B', '') // Zero-width space
        .replaceAll('\u200C', '') // Zero-width non-joiner
        .replaceAll('\u200D', '') // Zero-width joiner
        .replaceAll('\uFEFF', ''); // Byte order mark
  }

  /// ブロックユーザーIDのバリデーション
  static ValidationResult validateUserIdForBlocking(String userId) {
    if (userId.isEmpty) {
      return ValidationResult(false, 'ユーザーIDが空です');
    }
    
    if (userId.length > 128) {
      return ValidationResult(false, 'ユーザーIDが長すぎます');
    }
    
    // Firebase Auth UID形式の検証
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(userId)) {
      return ValidationResult(false, '無効なユーザーID形式です');
    }
    
    return ValidationResult(true, null);
  }
  
  /// ミュートキーワードのバリデーション
  static ValidationResult validateMutedKeyword(String keyword) {
    if (keyword.isEmpty) {
      return ValidationResult(false, 'キーワードが空です');
    }
    
    if (keyword.length > 100) {
      return ValidationResult(false, 'キーワードが長すぎます（最大100文字）');
    }
    
    // XSS攻撃チェック
    if (containsXssThreats(keyword)) {
      return ValidationResult(false, '不正なコンテンツが検出されました');
    }
    
    // 制御文字のチェック
    if (RegExp(r'[\u0000-\u001F\u007F-\u009F]').hasMatch(keyword)) {
      return ValidationResult(false, '制御文字は使用できません');
    }
    
    return ValidationResult(true, null);
  }
  
  /// ブロックユーザーリストのバリデーション
  static ValidationResult validateBlockedUsersList(List<String> blockedUsers) {
    if (blockedUsers.length > 1000) {
      return ValidationResult(false, 'ブロックユーザー数が上限を超えています（最大1000ユーザー）');
    }
    
    for (final userId in blockedUsers) {
      final validation = validateUserIdForBlocking(userId);
      if (!validation.isValid) {
        return ValidationResult(false, '無効なユーザーIDが含まれています: ${validation.errorMessage}');
      }
    }
    
    // 重複チェック
    final uniqueUsers = blockedUsers.toSet();
    if (uniqueUsers.length != blockedUsers.length) {
      return ValidationResult(false, '重複したユーザーIDが含まれています');
    }
    
    return ValidationResult(true, null);
  }
  
  /// ミュートキーワードリストのバリデーション
  static ValidationResult validateMutedKeywordsList(List<String> mutedKeywords) {
    if (mutedKeywords.length > 500) {
      return ValidationResult(false, 'ミュートキーワード数が上限を超えています（最大500キーワード）');
    }
    
    for (final keyword in mutedKeywords) {
      final validation = validateMutedKeyword(keyword);
      if (!validation.isValid) {
        return ValidationResult(false, '無効なキーワードが含まれています: ${validation.errorMessage}');
      }
    }
    
    // 重複チェック
    final uniqueKeywords = mutedKeywords.toSet();
    if (uniqueKeywords.length != mutedKeywords.length) {
      return ValidationResult(false, '重複したキーワードが含まれています');
    }
    
    return ValidationResult(true, null);
  }
  
  /// プライバシー設定のバリデーション
  static ValidationResult validatePrivacySettings(PrivacySettings privacy) {
    // 基本的な設定値は boolean なので特別な検証は不要
    // ただし、将来的な拡張に備えて構造を用意
    
    return ValidationResult(true, null);
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