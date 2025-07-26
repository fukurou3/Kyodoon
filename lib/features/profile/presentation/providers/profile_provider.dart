import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/usecases/profile_usecase.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../utils/app_logger.dart';

/// プロフィールプロバイダー
/// 
/// Clean Architectureのプレゼンテーション層
class ProfileProvider extends ChangeNotifier {
  final ProfileUseCase _profileUseCase;

  ProfileEntity? _currentProfile;
  ProfileEntity? _viewingProfile;
  UserPreferencesEntity? _userPreferences;
  List<ProfileEntity> _searchResults = [];
  List<ProfileEntity> _blockedUsers = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isUpdating = false;
  String? _errorMessage;

  ProfileProvider(this._profileUseCase) {
    _loadCurrentProfile();
  }

  /// 現在のユーザープロフィール
  ProfileEntity? get currentProfile => _currentProfile;

  /// 表示中のプロフィール
  ProfileEntity? get viewingProfile => _viewingProfile;

  /// ユーザー設定
  UserPreferencesEntity? get userPreferences => _userPreferences;

  /// 検索結果
  List<ProfileEntity> get searchResults => _searchResults;

  /// ブロックユーザー一覧
  List<ProfileEntity> get blockedUsers => _blockedUsers;

  /// ローディング状態
  bool get isLoading => _isLoading;

  /// 検索中状態
  bool get isSearching => _isSearching;

  /// 更新中状態
  bool get isUpdating => _isUpdating;

  /// エラーメッセージ
  String? get errorMessage => _errorMessage;

  /// エラークリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 現在のユーザープロフィールを読み込み
  Future<void> _loadCurrentProfile() async {
    _setLoading(true);
    _clearError();

    try {
      final profile = await _profileUseCase.getCurrentUserProfile();
      _currentProfile = profile;

      if (profile != null) {
        await _loadUserPreferences(profile.userId);
      }

    } catch (e) {
      _handleError('プロフィールの取得に失敗しました', e);
    } finally {
      _setLoading(false);
    }
  }

  /// 指定されたユーザーのプロフィールを読み込み
  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final profile = await _profileUseCase.getProfile(userId);
      _viewingProfile = profile;

      if (profile == null) {
        _setError('プロフィールが見つかりません');
      }

    } catch (e) {
      _handleError('プロフィールの取得に失敗しました', e);
    } finally {
      _setLoading(false);
    }
  }

  /// 現在のユーザープロフィールをリロード
  Future<void> reloadCurrentProfile() async {
    await _loadCurrentProfile();
  }

  /// プロフィールを更新
  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? municipality,
    List<String>? interests,
    bool? isPublic,
  }) async {
    if (_currentProfile == null) {
      _setError('プロフィールが読み込まれていません');
      return false;
    }

    _setUpdating(true);
    _clearError();

    try {
      await _profileUseCase.updateProfile(
        userId: _currentProfile!.userId,
        displayName: displayName,
        bio: bio,
        municipality: municipality,
        interests: interests,
        isPublic: isPublic,
      );

      // プロフィールを再読み込み
      await _loadCurrentProfile();

      AppLogger.info('Profile updated successfully');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } on DataException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('プロフィールの更新に失敗しました');
      AppLogger.error('Failed to update profile', e);
      return false;

    } finally {
      _setUpdating(false);
    }
  }

  /// プロフィール画像を更新
  Future<bool> updateProfileImage(List<int> imageData) async {
    if (_currentProfile == null) {
      _setError('プロフィールが読み込まれていません');
      return false;
    }

    _setUpdating(true);
    _clearError();

    try {
      final imageUrl = await _profileUseCase.updateProfileImage(
        _currentProfile!.userId,
        imageData,
      );

      // プロフィールを再読み込み
      await _loadCurrentProfile();

      AppLogger.info('Profile image updated successfully: $imageUrl');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('プロフィール画像の更新に失敗しました');
      AppLogger.error('Failed to update profile image', e);
      return false;

    } finally {
      _setUpdating(false);
    }
  }

  /// プロフィール画像を削除
  Future<bool> deleteProfileImage() async {
    if (_currentProfile == null) {
      _setError('プロフィールが読み込まれていません');
      return false;
    }

    _setUpdating(true);
    _clearError();

    try {
      await _profileUseCase.deleteProfileImage(_currentProfile!.userId);

      // プロフィールを再読み込み
      await _loadCurrentProfile();

      AppLogger.info('Profile image deleted successfully');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('プロフィール画像の削除に失敗しました');
      AppLogger.error('Failed to delete profile image', e);
      return false;

    } finally {
      _setUpdating(false);
    }
  }

  /// ユーザー設定を読み込み
  Future<void> _loadUserPreferences(String userId) async {
    try {
      final preferences = await _profileUseCase.getUserPreferences(userId);
      _userPreferences = preferences;
      notifyListeners();

    } catch (e) {
      AppLogger.error('Failed to load user preferences: $userId', e);
      // 設定の読み込み失敗は致命的ではないので続行
    }
  }

  /// ユーザー設定を更新
  Future<bool> updateUserPreferences(UserPreferencesEntity preferences) async {
    _clearError();

    try {
      await _profileUseCase.updateUserPreferences(preferences);
      _userPreferences = preferences;
      notifyListeners();

      AppLogger.info('User preferences updated successfully');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('設定の更新に失敗しました');
      AppLogger.error('Failed to update user preferences', e);
      return false;
    }
  }

  /// ユーザーを検索
  Future<bool> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return true;
    }

    _setSearching(true);
    _clearError();

    try {
      final results = await _profileUseCase.searchUsers(query);
      _searchResults = results;
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('ユーザー検索に失敗しました');
      AppLogger.error('Failed to search users: $query', e);
      return false;

    } finally {
      _setSearching(false);
    }
  }

  /// 検索結果をクリア
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// ユーザーをブロック
  Future<bool> blockUser(String targetUserId) async {
    if (_currentProfile == null) {
      _setError('プロフィールが読み込まれていません');
      return false;
    }

    _clearError();

    try {
      await _profileUseCase.blockUser(_currentProfile!.userId, targetUserId);

      // ブロックユーザー一覧を再読み込み
      await _loadBlockedUsers();

      AppLogger.info('User blocked successfully: $targetUserId');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('ユーザーのブロックに失敗しました');
      AppLogger.error('Failed to block user: $targetUserId', e);
      return false;
    }
  }

  /// ユーザーのブロックを解除
  Future<bool> unblockUser(String targetUserId) async {
    if (_currentProfile == null) {
      _setError('プロフィールが読み込まれていません');
      return false;
    }

    _clearError();

    try {
      await _profileUseCase.unblockUser(_currentProfile!.userId, targetUserId);

      // ブロックユーザー一覧を再読み込み
      await _loadBlockedUsers();

      AppLogger.info('User unblocked successfully: $targetUserId');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('ユーザーのブロック解除に失敗しました');
      AppLogger.error('Failed to unblock user: $targetUserId', e);
      return false;
    }
  }

  /// ブロックユーザー一覧を読み込み
  Future<void> loadBlockedUsers() async {
    await _loadBlockedUsers();
  }

  /// ブロックユーザー一覧を読み込み（内部）
  Future<void> _loadBlockedUsers() async {
    if (_currentProfile == null) return;

    try {
      final blocked = await _profileUseCase.getBlockedUsers(_currentProfile!.userId);
      _blockedUsers = blocked;
      notifyListeners();

    } catch (e) {
      AppLogger.error('Failed to load blocked users', e);
      // ブロックユーザー読み込み失敗は致命的ではないので続行
    }
  }

  /// プロフィール統計を更新
  Future<bool> refreshProfileStats() async {
    if (_currentProfile == null) {
      _setError('プロフィールが読み込まれていません');
      return false;
    }

    _clearError();

    try {
      await _profileUseCase.refreshProfileStats(_currentProfile!.userId);

      // プロフィールを再読み込み
      await _loadCurrentProfile();

      AppLogger.info('Profile stats refreshed successfully');
      return true;

    } catch (e) {
      _setError('統計情報の更新に失敗しました');
      AppLogger.error('Failed to refresh profile stats', e);
      return false;
    }
  }

  /// アカウントを削除
  Future<bool> deleteAccount() async {
    if (_currentProfile == null) {
      _setError('プロフィールが読み込まれていません');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _profileUseCase.deleteAccount(_currentProfile!.userId);

      // 状態をクリア
      _currentProfile = null;
      _viewingProfile = null;
      _userPreferences = null;
      _searchResults = [];
      _blockedUsers = [];

      AppLogger.info('Account deleted successfully');
      return true;

    } on ValidationException catch (e) {
      _setError(e.message);
      return false;

    } on AuthException catch (e) {
      _setError(e.message);
      return false;

    } catch (e) {
      _setError('アカウントの削除に失敗しました');
      AppLogger.error('Failed to delete account', e);
      return false;

    } finally {
      _setLoading(false);
    }
  }

  /// ローディング状態の設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 検索中状態の設定
  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  /// 更新中状態の設定
  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }

  /// エラー設定
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// エラークリア
  void _clearError() {
    _errorMessage = null;
  }

  /// エラーハンドリング
  void _handleError(String message, dynamic error) {
    AppLogger.error(message, error);
    _setError(message);
  }
}