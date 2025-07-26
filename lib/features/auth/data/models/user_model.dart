import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// ユーザーデータモデル
/// 
/// Firestoreとの連携用モデル
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    required this.isEmailVerified,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// FirestoreドキュメントからUserModelを作成
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('ユーザーデータが見つかりません');
    }

    return UserModel(
      id: snapshot.id,
      email: data['email'] ?? '',
      name: data['name'],
      photoUrl: data['photoUrl'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  /// UserModelをFirestoreドキュメント用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  /// UserModelをUserEntityに変換
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: name,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// UserEntityからUserModelを作成
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.displayName,
      photoUrl: entity.photoUrl,
      isEmailVerified: entity.isEmailVerified,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
    );
  }

  /// コピーを作成
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.photoUrl == photoUrl &&
        other.isEmailVerified == isEmailVerified &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      photoUrl,
      isEmailVerified,
      createdAt,
      lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }
}