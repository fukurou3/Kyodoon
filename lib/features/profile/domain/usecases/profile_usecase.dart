import '../entities/profile_entity.dart';
import '../entities/user_preferences_entity.dart';
import '../repositories/profile_repository.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/security_validator.dart';

/// プロフィールユースケース
/// 
/// プロフィールに関するビジネスロジックを管理
class ProfileUseCase {
  final ProfileRepository _repository;

  ProfileUseCase(this._repository);

  /// プロフィールを取得
  Future<ProfileEntity?> getProfile(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    return await _repository.getProfile(userId);
  }

  /// 現在のユーザーのプロフィールを取得
  Future<ProfileEntity?> getCurrentUserProfile() async {
    return await _repository.getCurrentUserProfile();
  }

  /// プロフィールを更新
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? municipality,
    List<String>? interests,
    bool? isPublic,
  }) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    // 既存のプロフィールを取得
    final existingProfile = await _repository.getProfile(userId);
    if (existingProfile == null) {
      throw DataException('プロフィールが見つかりません');
    }

    // 入力検証
    if (displayName != null && displayName.isNotEmpty) {
      final nameValidation = SecurityValidator.validateUsername(displayName);
      if (!nameValidation.isValid) {
        throw ValidationException(nameValidation.errorMessage!);
      }
    }

    if (bio != null && bio.isNotEmpty) {
      final bioValidation = _validateBio(bio);
      if (!bioValidation.isValid) {
        throw ValidationException(bioValidation.errorMessage!);
      }
    }

    if (municipality != null && municipality.isNotEmpty) {
      final municipalityValidation = _validateMunicipality(municipality);
      if (!municipalityValidation.isValid) {
        throw ValidationException(municipalityValidation.errorMessage!);
      }
    }

    if (interests != null) {
      final interestsValidation = _validateInterests(interests);
      if (!interestsValidation.isValid) {
        throw ValidationException(interestsValidation.errorMessage!);
      }
    }

    // プロフィールを更新
    final updatedProfile = existingProfile.copyWith(
      displayName: displayName,
      bio: bio != null ? SecurityValidator.sanitizeHtml(bio) : existingProfile.bio,
      municipality: municipality,
      interests: interests,
      isPublic: isPublic,
      updatedAt: DateTime.now(),
    );

    await _repository.updateProfile(updatedProfile);
  }

  /// プロフィール画像を更新
  Future<String> updateProfileImage(String userId, List<int> imageData) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    if (imageData.isEmpty) {
      throw ValidationException('画像データが指定されていません');
    }

    // 画像サイズの検証（5MB制限）
    if (imageData.length > 5 * 1024 * 1024) {
      throw ValidationException('画像サイズは5MB以下にしてください');
    }

    return await _repository.updateProfileImage(userId, imageData);
  }

  /// プロフィール画像を削除
  Future<void> deleteProfileImage(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    await _repository.deleteProfileImage(userId);
  }

  /// ユーザー設定を取得
  Future<UserPreferencesEntity> getUserPreferences(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    return await _repository.getUserPreferences(userId);
  }

  /// ユーザー設定を更新
  Future<void> updateUserPreferences(UserPreferencesEntity preferences) async {
    if (preferences.userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    // 設定値の検証
    final validationResult = _validatePreferences(preferences);
    if (!validationResult.isValid) {
      throw ValidationException(validationResult.errorMessage!);
    }

    final updatedPreferences = preferences.copyWith(
      updatedAt: DateTime.now(),
    );

    await _repository.updateUserPreferences(updatedPreferences);
  }

  /// ユーザーを検索
  Future<List<ProfileEntity>> searchUsers(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      throw ValidationException('検索クエリを入力してください');
    }

    if (query.trim().length < 2) {
      throw ValidationException('検索クエリは2文字以上で入力してください');
    }

    if (limit <= 0 || limit > 50) {
      throw ValidationException('取得件数は1〜50の範囲で指定してください');
    }

    // 検索クエリのサニタイズ
    final sanitizedQuery = SecurityValidator.sanitizeHtml(query.trim());

    return await _repository.searchUsers(sanitizedQuery, limit: limit);
  }

  /// ユーザーをブロック
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    if (currentUserId.isEmpty) {
      throw ValidationException('現在のユーザーIDが指定されていません');
    }

    if (targetUserId.isEmpty) {
      throw ValidationException('ブロック対象のユーザーIDが指定されていません');
    }

    if (currentUserId == targetUserId) {
      throw ValidationException('自分自身をブロックすることはできません');
    }

    await _repository.blockUser(currentUserId, targetUserId);
  }

  /// ユーザーのブロックを解除
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    if (currentUserId.isEmpty) {
      throw ValidationException('現在のユーザーIDが指定されていません');
    }

    if (targetUserId.isEmpty) {
      throw ValidationException('ブロック解除対象のユーザーIDが指定されていません');
    }

    await _repository.unblockUser(currentUserId, targetUserId);
  }

  /// ブロックされているユーザーの一覧を取得
  Future<List<ProfileEntity>> getBlockedUsers(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    return await _repository.getBlockedUsers(userId);
  }

  /// プロフィールの統計情報を更新
  Future<void> refreshProfileStats(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    await _repository.refreshProfileStats(userId);
  }

  /// アカウントを削除
  Future<void> deleteAccount(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException('ユーザーIDが指定されていません');
    }

    await _repository.deleteAccount(userId);
  }

  /// 自己紹介文のバリデーション
  ValidationResult _validateBio(String bio) {
    if (bio.length > 500) {
      return ValidationResult(false, '自己紹介は500文字以内で入力してください');
    }

    if (SecurityValidator.containsXssThreats(bio)) {
      return ValidationResult(false, '不正なコンテンツが検出されました');
    }

    return ValidationResult(true, null);
  }

  /// 自治体名のバリデーション
  ValidationResult _validateMunicipality(String municipality) {
    if (municipality.length > 50) {
      return ValidationResult(false, '自治体名は50文字以内で入力してください');
    }

    if (SecurityValidator.containsXssThreats(municipality)) {
      return ValidationResult(false, '不正な文字が含まれています');
    }

    // 日本語の自治体名として適切かチェック
    if (!RegExp(r'^[a-zA-Z\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF\s\-]+$').hasMatch(municipality)) {
      return ValidationResult(false, '自治体名に使用できない文字が含まれています');
    }

    return ValidationResult(true, null);
  }

  /// 興味・関心のバリデーション
  ValidationResult _validateInterests(List<String> interests) {
    if (interests.length > 10) {
      return ValidationResult(false, '興味・関心は10個以内で設定してください');
    }

    for (final interest in interests) {
      if (interest.isEmpty) {
        return ValidationResult(false, '空の興味・関心は設定できません');
      }

      if (interest.length > 30) {
        return ValidationResult(false, '各興味・関心は30文字以内で入力してください');
      }

      if (SecurityValidator.containsXssThreats(interest)) {
        return ValidationResult(false, '興味・関心に不正な文字が含まれています');
      }
    }

    return ValidationResult(true, null);
  }

  /// ユーザー設定のバリデーション
  ValidationResult _validatePreferences(UserPreferencesEntity preferences) {
    // 表示設定の検証
    if (preferences.display.postsPerPage < 5 || preferences.display.postsPerPage > 100) {
      return ValidationResult(false, '1ページあたりの投稿数は5〜100の範囲で設定してください');
    }

    if (!['ja', 'en'].contains(preferences.display.language)) {
      return ValidationResult(false, 'サポートされていない言語です');
    }

    if (!['light', 'dark', 'system'].contains(preferences.display.theme)) {
      return ValidationResult(false, 'サポートされていないテーマです');
    }

    // ミュートキーワードの検証
    if (preferences.mutedKeywords.length > 50) {
      return ValidationResult(false, 'ミュートキーワードは50個以内で設定してください');
    }

    for (final keyword in preferences.mutedKeywords) {
      if (keyword.isEmpty) {
        return ValidationResult(false, '空のキーワードは設定できません');
      }

      if (keyword.length > 20) {
        return ValidationResult(false, 'ミュートキーワードは20文字以内で入力してください');
      }
    }

    return ValidationResult(true, null);
  }
}

/// バリデーション結果クラス
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult(this.isValid, this.errorMessage);
}