# Kyodoon - 要件定義書

## プロジェクト概要
Flutterを使用したWebアプリケーション開発プロジェクト（初期段階）

## 技術スタック
- **フロントエンド**: Flutter (Web)
- **バックエンド**: Firebase
- **クラウドプラットフォーム**: Google Cloud (将来拡張予定)
- **データベース**: Cloud Firestore
- **認証**: Firebase Authentication
- **ホスティング**: Firebase Hosting

## アーキテクチャ方針
- **設計パターン**: Clean Architecture + MVVM
- **状態管理**: Provider または Riverpod
- **依存性注入**: GetIt
- **ルーティング**: GoRouter

## 命名規則

### 変数・関数
- **camelCase**を使用
- 意味のある名前を付ける
- booleanには`is`, `has`, `can`などの接頭辞を使用

```dart
// 変数例
String userName;
int postCount;
bool isLoading;
bool hasPermission;

// 関数例
void createPost();
Future<User> fetchUserProfile();
bool validateEmail(String email);
```

### クラス・コンポーネント
- **PascalCase**を使用
- 役割を明確にする接尾辞を使用

```dart
// Widget
class PostCard extends StatelessWidget {}
class UserProfileScreen extends StatefulWidget {}

// Model
class UserModel {}
class PostModel {}

// Service
class AuthService {}
class DatabaseService {}

// Repository
class UserRepository {}
class PostRepository {}

// Provider/Controller
class PostProvider extends ChangeNotifier {}
class AuthController {}
```

### ファイル・ディレクトリ
- **snake_case**を使用
- 機能別にディレクトリを分割

```
lib/
├── core/
│   ├── constants/
│   ├── utils/
│   ├── services/
│   └── errors/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── posts/
│   └── user_profile/
├── shared/
│   ├── widgets/
│   ├── models/
│   └── providers/
└── main.dart
```

### 定数・列挙型
- **UPPER_SNAKE_CASE**（定数）
- **PascalCase**（列挙型）

```dart
// 定数
const String API_BASE_URL = 'https://api.example.com';
const int MAX_POST_LENGTH = 280;

// 列挙型
enum PostType { casual, serious }
enum UserRole { admin, user, moderator }
```

## 重複回避戦略

### 1. 共通コンポーネント化
```dart
// 共通ボタンコンポーネント
class KyodoonButton extends StatelessWidget {}
class KyodoonTextField extends StatelessWidget {}
class KyodoonCard extends StatelessWidget {}
```

### 2. ユーティリティクラス
```dart
class ValidationUtils {
  static bool isValidEmail(String email) {}
  static bool isValidPassword(String password) {}
}

class DateTimeUtils {
  static String formatPostDate(DateTime date) {}
  static String timeAgo(DateTime date) {}
}
```

### 3. 共通定数管理
```dart
class AppConstants {
  static const String APP_NAME = 'Kyodoon';
  static const int POST_MAX_LENGTH = 280;
}

class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF424242);
}
```

### 4. 共通型定義
```dart
typedef PostCallback = void Function(PostModel post);
typedef ValidationCallback = String? Function(String? value);
```

## ディレクトリ構造詳細

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   ├── utils/
│   │   ├── validation_utils.dart
│   │   ├── date_time_utils.dart
│   │   └── string_utils.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── auth_service.dart
│   │   └── database_service.dart
│   └── errors/
│       ├── app_exceptions.dart
│       └── error_handler.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── use_cases/
│   │   └── presentation/
│   │       ├── screens/
│   │       ├── widgets/
│   │       └── providers/
│   ├── posts/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── user_profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── widgets/
│   │   ├── kyodoon_button.dart
│   │   ├── kyodoon_text_field.dart
│   │   ├── kyodoon_card.dart
│   │   └── loading_indicator.dart
│   ├── models/
│   │   ├── base_model.dart
│   │   └── response_model.dart
│   └── providers/
│       ├── theme_provider.dart
│       └── locale_provider.dart
└── main.dart
```

## 開発ガイドライン

### 1. コード品質
- dartfmt でフォーマット統一
- flutter analyze でリント実行
- 単体テスト実装必須

### 2. 状態管理
```dart
// Provider例
class PostProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;
  
  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  
  Future<void> fetchPosts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _posts = await _postRepository.getAllPosts();
    } catch (error) {
      // エラーハンドリング
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 3. エラーハンドリング
```dart
class AppException implements Exception {
  final String message;
  final String code;
  
  AppException(this.message, this.code);
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, 'NETWORK_ERROR');
}
```

## Firebase設定

### 1. 必要なパッケージ
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
```

### 2. 初期化
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

## 次のステップ
1. Firebase プロジェクト設定
2. 基本的なディレクトリ構造作成
3. 共通コンポーネント実装
4. 認証機能実装
5. 投稿機能実装

## 注意事項
- 全ての新機能は上記命名規則に従う
- 共通コンポーネントの再利用を最優先
- コードレビューで命名規則チェック必須
- 重複コード発見時は即座にリファクタリング