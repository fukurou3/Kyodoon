import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile_entity.dart';

/// プロフィールデータモデル
/// 
/// Firestoreとの連携用モデル
class ProfileModel {
  final String userId;
  final String email;
  final String? displayName;
  final String? bio;
  final String? photoUrl;
  final String? municipality;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final int postsCount;
  final int likesGivenCount;
  final int likesReceivedCount;
  final bool isPublic;
  final bool isEmailVerified;

  const ProfileModel({
    required this.userId,
    required this.email,
    this.displayName,
    this.bio,
    this.photoUrl,
    this.municipality,
    this.interests = const [],
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.postsCount = 0,
    this.likesGivenCount = 0,
    this.likesReceivedCount = 0,
    this.isPublic = true,
    this.isEmailVerified = false,
  });

  /// FirestoreドキュメントからProfileModelを作成
  factory ProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('プロフィールデータが見つかりません');
    }

    return ProfileModel(
      userId: snapshot.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      bio: data['bio'],
      photoUrl: data['photoUrl'],
      municipality: data['municipality'],
      interests: List<String>.from(data['interests'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      postsCount: data['postsCount'] ?? 0,
      likesGivenCount: data['likesGivenCount'] ?? 0,
      likesReceivedCount: data['likesReceivedCount'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      isEmailVerified: data['isEmailVerified'] ?? false,
    );
  }

  /// ProfileModelをFirestoreドキュメント用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'photoUrl': photoUrl,
      'municipality': municipality,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'postsCount': postsCount,
      'likesGivenCount': likesGivenCount,
      'likesReceivedCount': likesReceivedCount,
      'isPublic': isPublic,
      'isEmailVerified': isEmailVerified,
    };
  }

  /// ProfileModelをProfileEntityに変換
  ProfileEntity toEntity() {
    return ProfileEntity(
      userId: userId,
      email: email,
      displayName: displayName,
      bio: bio,
      photoUrl: photoUrl,
      municipality: municipality,
      interests: interests,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
      postsCount: postsCount,
      likesGivenCount: likesGivenCount,
      likesReceivedCount: likesReceivedCount,
      isPublic: isPublic,
      isEmailVerified: isEmailVerified,
    );
  }

  /// ProfileEntityからProfileModelを作成
  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      userId: entity.userId,
      email: entity.email,
      displayName: entity.displayName,
      bio: entity.bio,
      photoUrl: entity.photoUrl,
      municipality: entity.municipality,
      interests: entity.interests,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastLoginAt: entity.lastLoginAt,
      postsCount: entity.postsCount,
      likesGivenCount: entity.likesGivenCount,
      likesReceivedCount: entity.likesReceivedCount,
      isPublic: entity.isPublic,
      isEmailVerified: entity.isEmailVerified,
    );
  }

  /// コピーを作成
  ProfileModel copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? bio,
    String? photoUrl,
    String? municipality,
    List<String>? interests,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    int? postsCount,
    int? likesGivenCount,
    int? likesReceivedCount,
    bool? isPublic,
    bool? isEmailVerified,
  }) {
    return ProfileModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      municipality: municipality ?? this.municipality,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      postsCount: postsCount ?? this.postsCount,
      likesGivenCount: likesGivenCount ?? this.likesGivenCount,
      likesReceivedCount: likesReceivedCount ?? this.likesReceivedCount,
      isPublic: isPublic ?? this.isPublic,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileModel &&
        other.userId == userId &&
        other.email == email &&
        other.displayName == displayName &&
        other.bio == bio &&
        other.photoUrl == photoUrl &&
        other.municipality == municipality &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastLoginAt == lastLoginAt &&
        other.postsCount == postsCount &&
        other.likesGivenCount == likesGivenCount &&
        other.likesReceivedCount == likesReceivedCount &&
        other.isPublic == isPublic &&
        other.isEmailVerified == isEmailVerified;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      email,
      displayName,
      bio,
      photoUrl,
      municipality,
      createdAt,
      updatedAt,
      lastLoginAt,
      postsCount,
      likesGivenCount,
      likesReceivedCount,
      isPublic,
      isEmailVerified,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(userId: $userId, displayName: $displayName, municipality: $municipality)';
  }
}