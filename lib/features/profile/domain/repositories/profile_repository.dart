import '../entities/profile_entity.dart';
import '../entities/user_preferences_entity.dart';

/// プロフィールリポジトリインターフェース
/// 
/// プロフィールに関するデータ操作の抽象化
abstract class ProfileRepository {
  /// プロフィールを取得
  /// 
  /// [userId] ユーザーID
  /// 戻り値: 成功時はProfileEntity、存在しない場合はnull
  Future<ProfileEntity?> getProfile(String userId);

  /// 現在のユーザーのプロフィールを取得
  /// 
  /// 戻り値: 成功時はProfileEntity、ログインしていない場合はnull
  Future<ProfileEntity?> getCurrentUserProfile();

  /// プロフィールを更新
  /// 
  /// [profile] 更新するプロフィールエンティティ
  Future<void> updateProfile(ProfileEntity profile);

  /// プロフィール画像を更新
  /// 
  /// [userId] ユーザーID
  /// [imageData] 画像データ（バイナリ）
  /// 戻り値: アップロードされた画像のURL
  Future<String> updateProfileImage(String userId, List<int> imageData);

  /// プロフィール画像を削除
  /// 
  /// [userId] ユーザーID
  Future<void> deleteProfileImage(String userId);

  /// ユーザーの投稿数を更新
  /// 
  /// [userId] ユーザーID
  /// [increment] 増減値（正の数で増加、負の数で減少）
  Future<void> updatePostsCount(String userId, int increment);

  /// ユーザーのいいね統計を更新
  /// 
  /// [userId] ユーザーID
  /// [givenIncrement] 与えたいいね数の増減
  /// [receivedIncrement] 受け取ったいいね数の増減
  Future<void> updateLikesCount(String userId, {int? givenIncrement, int? receivedIncrement});

  /// ユーザー設定を取得
  /// 
  /// [userId] ユーザーID
  /// 戻り値: 成功時はUserPreferencesEntity、存在しない場合はデフォルト設定
  Future<UserPreferencesEntity> getUserPreferences(String userId);

  /// ユーザー設定を更新
  /// 
  /// [preferences] 更新するユーザー設定エンティティ
  Future<void> updateUserPreferences(UserPreferencesEntity preferences);

  /// ユーザーを検索
  /// 
  /// [query] 検索クエリ（名前、メールアドレスなど）
  /// [limit] 取得件数制限
  /// 戻り値: マッチしたプロフィールのリスト
  Future<List<ProfileEntity>> searchUsers(String query, {int limit = 20});

  /// ユーザーをブロック
  /// 
  /// [currentUserId] 現在のユーザーID
  /// [targetUserId] ブロック対象のユーザーID
  Future<void> blockUser(String currentUserId, String targetUserId);

  /// ユーザーのブロックを解除
  /// 
  /// [currentUserId] 現在のユーザーID
  /// [targetUserId] ブロック解除対象のユーザーID
  Future<void> unblockUser(String currentUserId, String targetUserId);

  /// ブロックされているユーザーの一覧を取得
  /// 
  /// [userId] ユーザーID
  /// 戻り値: ブロックされているユーザーのプロフィールリスト
  Future<List<ProfileEntity>> getBlockedUsers(String userId);

  /// プロフィールの統計情報を更新
  /// 
  /// [userId] ユーザーID
  /// 実際の投稿数、いいね数などを集計して更新
  Future<void> refreshProfileStats(String userId);

  /// アカウントを削除
  /// 
  /// [userId] ユーザーID
  /// プロフィール情報とユーザー設定を削除
  Future<void> deleteAccount(String userId);
}