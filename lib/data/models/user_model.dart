import '../../domain/entities/user.dart';

/// 用户模型类
///
/// 实现了User实体的数据层表示，添加了序列化和反序列化方法
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.profilePicture,
    required super.isVerified,
    required super.createdAt,
  });

  /// 从JSON映射创建UserModel实例
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// 将UserModel实例转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
