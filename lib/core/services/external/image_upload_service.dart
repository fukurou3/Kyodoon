import 'dart:typed_data';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../errors/app_exceptions.dart';
import '../../../utils/app_logger.dart';

/// 画像アップロードサービス
/// 
/// Firebase Storage での画像管理
class ImageUploadService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  ImageUploadService({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const int _maxImageSize = 5 * 1024 * 1024; // 5MB

  /// プロフィール画像をアップロード
  Future<String> uploadProfileImage(List<int> imageData) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    return await _uploadImage(
      imageData,
      'profile_images/${user.uid}',
      'profile_image',
    );
  }

  /// 投稿画像をアップロード
  Future<String> uploadPostImage(List<int> imageData) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    return await _uploadImage(
      imageData,
      'post_images/${user.uid}',
      'post_image',
    );
  }

  /// 一時画像をアップロード
  Future<String> uploadTempImage(List<int> imageData) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('ログインが必要です');
    }

    return await _uploadImage(
      imageData,
      'temp_images/${user.uid}',
      'temp_image',
      deleteAfter: const Duration(hours: 24),
    );
  }

  /// 画像をアップロード（内部メソッド）
  Future<String> _uploadImage(
    List<int> imageData,
    String folder,
    String prefix, {
    Duration? deleteAfter,
  }) async {
    try {
      // 画像データの検証
      _validateImageData(imageData);

      // ファイル名を生成
      final fileName = _generateFileName(prefix);
      final filePath = '$folder/$fileName.jpg';

      // Firebase Storage にアップロード
      final ref = _storage.ref().child(filePath);
      
      // メタデータを設定
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': _auth.currentUser?.uid ?? 'unknown',
          'uploadedAt': DateTime.now().toIso8601String(),
          if (deleteAfter != null) 
            'deleteAfter': DateTime.now().add(deleteAfter).toIso8601String(),
        },
      );

      // アップロード実行
      final uploadTask = ref.putData(Uint8List.fromList(imageData), metadata);
      
      // アップロード進行状況を監視
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        AppLogger.debug('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('Image uploaded successfully: $filePath');
      return downloadUrl;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error during upload', e);
      _handleStorageError(e);

    } catch (e) {
      AppLogger.error('Failed to upload image', e);
      throw DataException('画像のアップロードに失敗しました');
    }
  }

  /// 画像を削除
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      AppLogger.info('Image deleted successfully: ${ref.fullPath}');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        AppLogger.warning('Image not found for deletion: $imageUrl');
        return; // ファイルが存在しない場合は正常終了
      }
      
      AppLogger.error('Firebase Storage error during deletion', e);
      _handleStorageError(e);

    } catch (e) {
      AppLogger.error('Failed to delete image: $imageUrl', e);
      throw DataException('画像の削除に失敗しました');
    }
  }

  /// ユーザーの画像をすべて削除
  Future<void> deleteAllUserImages(String userId) async {
    try {
      final folders = ['profile_images', 'post_images', 'temp_images'];
      
      for (final folder in folders) {
        try {
          final listResult = await _storage.ref().child('$folder/$userId').listAll();
          
          for (final item in listResult.items) {
            try {
              await item.delete();
              AppLogger.debug('Deleted user image: ${item.fullPath}');
            } catch (e) {
              AppLogger.warning('Failed to delete user image: ${item.fullPath}', e);
            }
          }
        } catch (e) {
          AppLogger.warning('Failed to list images in folder: $folder/$userId', e);
        }
      }
      
      AppLogger.info('All user images deletion completed: $userId');
    } catch (e) {
      AppLogger.error('Failed to delete all user images: $userId', e);
      throw DataException('ユーザー画像の削除に失敗しました');
    }
  }

  /// 期限切れの一時画像を削除
  Future<void> cleanupExpiredTempImages() async {
    try {
      final tempRef = _storage.ref().child('temp_images');
      final listResult = await tempRef.listAll();
      
      final now = DateTime.now();
      int deletedCount = 0;

      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          final deleteAfterStr = metadata.customMetadata?['deleteAfter'];
          
          if (deleteAfterStr != null) {
            final deleteAfter = DateTime.parse(deleteAfterStr);
            if (now.isAfter(deleteAfter)) {
              await item.delete();
              deletedCount++;
              AppLogger.debug('Deleted expired temp image: ${item.fullPath}');
            }
          }
        } catch (e) {
          AppLogger.warning('Failed to process temp image: ${item.fullPath}', e);
        }
      }
      
      if (deletedCount > 0) {
        AppLogger.info('Cleaned up $deletedCount expired temp images');
      }
    } catch (e) {
      AppLogger.error('Failed to cleanup expired temp images', e);
    }
  }

  /// 画像のメタデータを取得
  Future<Map<String, dynamic>?> getImageMetadata(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'created': metadata.timeCreated?.toIso8601String(),
        'updated': metadata.updated?.toIso8601String(),
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      AppLogger.error('Failed to get image metadata: $imageUrl', e);
      return null;
    }
  }

  /// Storage使用量を取得
  Future<Map<String, int>> getStorageUsage(String userId) async {
    try {
      final folders = ['profile_images', 'post_images', 'temp_images'];
      final usage = <String, int>{};
      
      for (final folder in folders) {
        int folderSize = 0;
        try {
          final listResult = await _storage.ref().child('$folder/$userId').listAll();
          
          for (final item in listResult.items) {
            try {
              final metadata = await item.getMetadata();
              folderSize += (metadata.size ?? 0).toInt();
            } catch (e) {
              AppLogger.debug('Failed to get metadata for: ${item.fullPath}', e);
            }
          }
        } catch (e) {
          AppLogger.debug('Failed to list folder: $folder/$userId', e);
        }
        
        usage[folder] = folderSize;
      }
      
      return usage;
    } catch (e) {
      AppLogger.error('Failed to get storage usage: $userId', e);
      return {};
    }
  }

  /// 画像データの検証
  void _validateImageData(List<int> imageData) {
    if (imageData.isEmpty) {
      throw ValidationException('画像データが空です');
    }

    if (imageData.length > _maxImageSize) {
      throw ValidationException('画像サイズが大きすぎます（最大5MB）');
    }

    // 簡単なファイル形式チェック（JPEG, PNG の magic number）
    if (!_isValidImageFormat(imageData)) {
      throw ValidationException('サポートされていない画像形式です');
    }
  }

  /// 有効な画像形式かチェック
  bool _isValidImageFormat(List<int> imageData) {
    if (imageData.length < 4) return false;

    // JPEG magic number: FF D8 FF
    if (imageData[0] == 0xFF && imageData[1] == 0xD8 && imageData[2] == 0xFF) {
      return true;
    }

    // PNG magic number: 89 50 4E 47
    if (imageData.length >= 8 &&
        imageData[0] == 0x89 &&
        imageData[1] == 0x50 &&
        imageData[2] == 0x4E &&
        imageData[3] == 0x47) {
      return true;
    }

    return false;
  }

  /// ファイル名を生成
  String _generateFileName(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '${prefix}_${timestamp}_$random';
  }

  /// Storage エラーを処理
  Never _handleStorageError(FirebaseException e) {
    AppLogger.error('Firebase Storage error: ${e.code}', e);
    
    switch (e.code) {
      case 'unauthorized':
        throw PermissionException('ストレージへのアクセス権限がありません');
      case 'canceled':
        throw DataException('アップロードがキャンセルされました');
      case 'unknown':
        throw NetworkException('不明なエラーが発生しました');
      case 'object-not-found':
        throw DataException('ファイルが見つかりません');
      case 'quota-exceeded':
        throw DataException('ストレージの容量制限に達しました');
      case 'unauthenticated':
        throw AuthException('認証が必要です');
      default:
        throw DataException('ストレージエラー: ${e.message ?? e.code}');
    }
  }
}