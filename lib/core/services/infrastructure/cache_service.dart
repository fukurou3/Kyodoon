import 'dart:convert';
import 'dart:async';

import '../../../utils/app_logger.dart';

/// データキャッシュサービス
/// 
/// メモリ内キャッシュでアプリケーションのパフォーマンスを向上
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheItem> _cache = {};
  final Map<String, Timer> _timers = {};

  static const Duration _defaultTtl = Duration(minutes: 5);
  static const int _maxCacheSize = 1000;

  /// データをキャッシュに保存
  void put<T>(String key, T value, {Duration? ttl}) {
    if (key.isEmpty) return;

    // キャッシュサイズ制限
    if (_cache.length >= _maxCacheSize) {
      _evictOldest();
    }

    final expiresAt = DateTime.now().add(ttl ?? _defaultTtl);
    _cache[key] = _CacheItem(value, expiresAt);

    // 期限切れタイマーを設定
    _setExpirationTimer(key, ttl ?? _defaultTtl);

    AppLogger.debug('Cache put: $key (expires in ${(ttl ?? _defaultTtl).inMinutes} minutes)');
  }

  /// キャッシュからデータを取得
  T? get<T>(String key) {
    if (key.isEmpty) return null;

    final item = _cache[key];
    if (item == null) {
      return null;
    }

    // 期限切れチェック
    if (item.isExpired) {
      remove(key);
      return null;
    }

    AppLogger.debug('Cache hit: $key');
    return item.value as T?;
  }

  /// キャッシュからデータを削除
  void remove(String key) {
    if (key.isEmpty) return;

    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);

    AppLogger.debug('Cache removed: $key');
  }

  /// パターンに一致するキーのデータを削除
  void removeByPattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();
    
    for (final key in keysToRemove) {
      remove(key);
    }

    AppLogger.debug('Cache removed by pattern: $pattern (${keysToRemove.length} items)');
  }

  /// キャッシュが存在するかチェック
  bool contains(String key) {
    if (key.isEmpty) return false;

    final item = _cache[key];
    if (item == null || item.isExpired) {
      if (item?.isExpired == true) {
        remove(key);
      }
      return false;
    }

    return true;
  }

  /// キャッシュサイズを取得
  int get size => _cache.length;

  /// すべてのキャッシュをクリア
  void clear() {
    _cache.clear();
    
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    AppLogger.debug('Cache cleared');
  }

  /// 期限切れのアイテムを削除
  void evictExpired() {
    final now = DateTime.now();
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.expiresAt.isBefore(now))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.debug('Cache evicted expired items: ${expiredKeys.length}');
    }
  }

  /// キャッシュ統計を取得
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final expired = _cache.values.where((item) => item.expiresAt.isBefore(now)).length;
    
    return {
      'size': _cache.length,
      'expired': expired,
      'active': _cache.length - expired,
      'maxSize': _maxCacheSize,
    };
  }

  /// キーのリストを取得
  List<String> getKeys() {
    return _cache.keys.toList();
  }

  /// JSON形式でシリアライズ可能なオブジェクトをキャッシュ
  void putJson(String key, Map<String, dynamic> data, {Duration? ttl}) {
    try {
      final jsonString = jsonEncode(data);
      put(key, jsonString, ttl: ttl);
    } catch (e) {
      AppLogger.error('Failed to cache JSON data: $key', e);
    }
  }

  /// JSON形式のキャッシュデータを取得
  Map<String, dynamic>? getJson(String key) {
    try {
      final jsonString = get<String>(key);
      if (jsonString == null) return null;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to get JSON data from cache: $key', e);
      remove(key); // 破損したデータを削除
      return null;
    }
  }

  /// 一番古いアイテムを削除
  void _evictOldest() {
    if (_cache.isEmpty) return;

    DateTime oldest = DateTime.now();
    String? oldestKey;

    for (final entry in _cache.entries) {
      if (entry.value.expiresAt.isBefore(oldest)) {
        oldest = entry.value.expiresAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      remove(oldestKey);
    }
  }

  /// 期限切れタイマーを設定
  void _setExpirationTimer(String key, Duration ttl) {
    _timers[key]?.cancel();
    _timers[key] = Timer(ttl, () {
      remove(key);
    });
  }
}

/// キャッシュアイテムクラス
class _CacheItem {
  final dynamic value;
  final DateTime expiresAt;

  _CacheItem(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// キャッシュキーのユーティリティ
class CacheKeys {
  // 投稿関連
  static String postsList(String type, String? municipality) {
    return 'posts_${type}_${municipality ?? 'all'}';
  }

  static String post(String postId) => 'post_$postId';
  
  static String userPosts(String userId) => 'user_posts_$userId';
  
  static String postComments(String postId) => 'post_comments_$postId';

  // プロフィール関連
  static String userProfile(String userId) => 'user_profile_$userId';
  
  static String userPreferences(String userId) => 'user_preferences_$userId';
  
  static String userStats(String userId) => 'user_stats_$userId';

  // 検索関連
  static String searchUsers(String query) => 'search_users_${query.toLowerCase()}';

  // 統計関連
  static const String postStats = 'post_stats';
  static const String globalUserStats = 'global_user_stats';
}