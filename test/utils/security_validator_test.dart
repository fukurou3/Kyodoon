import 'package:flutter_test/flutter_test.dart';
import 'package:kyodoon/utils/security_validator.dart';

void main() {
  group('SecurityValidator Tests', () {
    group('XSS 脅威検出テスト', () {
      test('基本的なスクリプトタグを検出する', () {
        expect(SecurityValidator.containsXssThreats('<script>alert("xss")</script>'), isTrue);
        expect(SecurityValidator.containsXssThreats('<SCRIPT>alert("xss")</SCRIPT>'), isTrue);
        expect(SecurityValidator.containsXssThreats('<Script>alert("xss")</Script>'), isTrue);
      });

      test('イベントハンドラーを検出する', () {
        expect(SecurityValidator.containsXssThreats('onclick="alert()"'), isTrue);
        expect(SecurityValidator.containsXssThreats('onload="alert()"'), isTrue);
        expect(SecurityValidator.containsXssThreats('onerror="alert()"'), isTrue);
        expect(SecurityValidator.containsXssThreats('onmouseover="alert()"'), isTrue);
      });

      test('JavaScript URIを検出する', () {
        expect(SecurityValidator.containsXssThreats('javascript:alert()'), isTrue);
        expect(SecurityValidator.containsXssThreats('JAVASCRIPT:alert()'), isTrue);
        expect(SecurityValidator.containsXssThreats('vbscript:msgbox()'), isTrue);
      });

      test('危険なHTMLタグを検出する', () {
        expect(SecurityValidator.containsXssThreats('<iframe src="evil.com">'), isTrue);
        expect(SecurityValidator.containsXssThreats('<object data="evil.swf">'), isTrue);
        expect(SecurityValidator.containsXssThreats('<embed src="evil.swf">'), isTrue);
        expect(SecurityValidator.containsXssThreats('<form action="evil.com">'), isTrue);
      });

      test('エンコーディング攻撃を検出する', () {
        expect(SecurityValidator.containsXssThreats('&#60;script&#62;'), isTrue);
        expect(SecurityValidator.containsXssThreats('%3Cscript%3E'), isTrue);
        expect(SecurityValidator.containsXssThreats('\\u003Cscript\\u003E'), isTrue);
      });

      test('安全なコンテンツを通す', () {
        expect(SecurityValidator.containsXssThreats('こんにちは、世界！'), isFalse);
        expect(SecurityValidator.containsXssThreats('Hello World!'), isFalse);
        expect(SecurityValidator.containsXssThreats('これは普通の投稿です。'), isFalse);
        expect(SecurityValidator.containsXssThreats('数字123と記号!@#'), isFalse);
      });
    });

    group('HTMLサニタイズテスト', () {
      test('危険なタグを除去する', () {
        final input = 'Hello <script>alert("xss")</script> World';
        final sanitized = SecurityValidator.sanitizeHtml(input);
        expect(sanitized.contains('<script>'), isFalse);
        expect(sanitized.contains('alert'), isFalse);
      });

      test('HTMLエンティティエンコードを適用する', () {
        final input = '<div>Hello & "World"</div>';
        final sanitized = SecurityValidator.sanitizeHtml(input);
        expect(sanitized.contains('&lt;'), isTrue);
        expect(sanitized.contains('&gt;'), isTrue);
        expect(sanitized.contains('&amp;'), isTrue);
        expect(sanitized.contains('&quot;'), isTrue);
      });
    });

    group('投稿内容バリデーションテスト', () {
      test('正常な投稿内容を受け入れる', () {
        final result = SecurityValidator.validatePostContent('これは正常な投稿です。');
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('空の投稿内容を拒否する', () {
        final result = SecurityValidator.validatePostContent('');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, '投稿内容を入力してください');
      });

      test('長すぎる投稿内容を拒否する', () {
        final longContent = 'あ' * 2001;
        final result = SecurityValidator.validatePostContent(longContent);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, '投稿内容は2000文字以内で入力してください');
      });

      test('XSS攻撃を含む投稿内容を拒否する', () {
        final result = SecurityValidator.validatePostContent('<script>alert("xss")</script>');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, '不正なコンテンツが検出されました');
      });

      test('過度な空白文字を拒否する', () {
        final result = SecurityValidator.validatePostContent('Hello          World');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, '過度な空白文字は使用できません');
      });
    });

    group('ユーザー名バリデーションテスト', () {
      test('正常なユーザー名を受け入れる', () {
        final result = SecurityValidator.validateUsername('user123');
        expect(result.isValid, isTrue);
        
        final result2 = SecurityValidator.validateUsername('太郎');
        expect(result2.isValid, isTrue);
        
        final result3 = SecurityValidator.validateUsername('user_name');
        expect(result3.isValid, isTrue);
      });

      test('空のユーザー名を拒否する', () {
        final result = SecurityValidator.validateUsername('');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'ユーザー名を入力してください');
      });

      test('長すぎるユーザー名を拒否する', () {
        final longUsername = 'あ' * 51;
        final result = SecurityValidator.validateUsername(longUsername);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'ユーザー名は50文字以内で入力してください');
      });

      test('不正な文字を含むユーザー名を拒否する', () {
        final result = SecurityValidator.validateUsername('user@name');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'ユーザー名に使用できない文字が含まれています');
      });

      test('XSS攻撃を含むユーザー名を拒否する', () {
        final result = SecurityValidator.validateUsername('<script>alert()</script>');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'ユーザー名に使用できない文字が含まれています');
      });
    });

    group('メールアドレスバリデーションテスト', () {
      test('正常なメールアドレスを受け入れる', () {
        final result = SecurityValidator.validateEmail('user@example.com');
        expect(result.isValid, isTrue);
        
        final result2 = SecurityValidator.validateEmail('test.email+tag@domain.co.jp');
        expect(result2.isValid, isTrue);
      });

      test('空のメールアドレスを拒否する', () {
        final result = SecurityValidator.validateEmail('');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'メールアドレスを入力してください');
      });

      test('不正な形式のメールアドレスを拒否する', () {
        final result = SecurityValidator.validateEmail('invalid-email');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, '正しいメールアドレス形式で入力してください');
        
        final result2 = SecurityValidator.validateEmail('user@');
        expect(result2.isValid, isFalse);
        
        final result3 = SecurityValidator.validateEmail('@domain.com');
        expect(result3.isValid, isFalse);
      });

      test('長すぎるメールアドレスを拒否する', () {
        final longEmail = 'a' * 250 + '@test.com';
        final result = SecurityValidator.validateEmail(longEmail);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'メールアドレスが長すぎます');
      });
    });

    group('パスワードバリデーションテスト', () {
      test('強力なパスワードを受け入れる', () {
        final result = SecurityValidator.validatePassword('Password123!');
        expect(result.isValid, isTrue);
        
        final result2 = SecurityValidator.validatePassword('MySecure@Pass1');
        expect(result2.isValid, isTrue);
      });

      test('空のパスワードを拒否する', () {
        final result = SecurityValidator.validatePassword('');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'パスワードを入力してください');
      });

      test('短すぎるパスワードを拒否する', () {
        final result = SecurityValidator.validatePassword('12345');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'パスワードは8文字以上で入力してください');
      });

      test('長すぎるパスワードを拒否する', () {
        final longPassword = 'a' * 129;
        final result = SecurityValidator.validatePassword(longPassword);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'パスワードは128文字以内で入力してください');
      });

      test('弱いパスワードを拒否する', () {
        final result = SecurityValidator.validatePassword('password');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'パスワードは英大文字、英小文字、数字、記号のうち3種類以上を含めてください');
        
        final result2 = SecurityValidator.validatePassword('12345678');
        expect(result2.isValid, isFalse);
      });
    });

    group('SQLインジェクション検出テスト', () {
      test('SQLインジェクション攻撃を検出する', () {
        expect(SecurityValidator.containsSqlInjectionThreats("SELECT * FROM users"), isTrue);
        expect(SecurityValidator.containsSqlInjectionThreats("1' OR '1'='1"), isTrue);
        expect(SecurityValidator.containsSqlInjectionThreats("DROP TABLE users"), isTrue);
        expect(SecurityValidator.containsSqlInjectionThreats("UNION SELECT password"), isTrue);
        expect(SecurityValidator.containsSqlInjectionThreats("-- comment"), isTrue);
        expect(SecurityValidator.containsSqlInjectionThreats("/* comment */"), isTrue);
      });

      test('安全な入力を通す', () {
        expect(SecurityValidator.containsSqlInjectionThreats("普通のテキスト"), isFalse);
        expect(SecurityValidator.containsSqlInjectionThreats("Hello World"), isFalse);
        expect(SecurityValidator.containsSqlInjectionThreats("数字123"), isFalse);
      });
    });

    group('入力サニタイズテスト', () {
      test('先頭・末尾の空白を除去する', () {
        final result = SecurityValidator.sanitizeInput('  Hello World  ');
        expect(result, 'Hello World');
      });

      test('連続する空白を単一に変換する', () {
        final result = SecurityValidator.sanitizeInput('Hello    World');
        expect(result, 'Hello World');
      });

      test('制御文字を除去する', () {
        final input = 'Hello\x00\x01\x1F\x7FWorld';
        final result = SecurityValidator.sanitizeInput(input);
        expect(result, 'HelloWorld');
      });
    });
  });
}