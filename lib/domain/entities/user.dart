import 'package:equatable/equatable.dart';

/// 用户实体类
/// 
/// 代表系统中的用户。实体是核心业务对象，与数据源无关。
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final bool isVerified;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.isVerified,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, email, profilePicture, isVerified, createdAt];
}
