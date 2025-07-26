/// アプリケーション例外の基底クラス
abstract class AppException implements Exception {
  final String message;
  final String code;

  const AppException(this.message, this.code);

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

/// 認証関連の例外
class AuthException extends AppException {
  const AuthException(String message) : super(message, 'AUTH_ERROR');
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

/// データ関連の例外
class DataException extends AppException {
  const DataException(String message) : super(message, 'DATA_ERROR');
}

/// バリデーション関連の例外
class ValidationException extends AppException {
  const ValidationException(String message) : super(message, 'VALIDATION_ERROR');
}

/// レート制限関連の例外
class RateLimitException extends AppException {
  const RateLimitException(String message) : super(message, 'RATE_LIMIT_ERROR');
}

/// 権限関連の例外
class PermissionException extends AppException {
  const PermissionException(String message) : super(message, 'PERMISSION_ERROR');
}

/// サーバー関連の例外
class ServerException extends AppException {
  const ServerException(String message) : super(message, 'SERVER_ERROR');
}