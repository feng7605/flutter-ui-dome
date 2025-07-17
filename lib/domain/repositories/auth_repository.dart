import 'package:dartz/dartz.dart';

import '../entities/user.dart';
import '../../core/error/failures.dart';

/// 认证仓库接口
/// 
/// 定义与认证相关的所有操作。
/// 这是一个抽象接口，具体实现将在data层提供。
abstract class AuthRepository {
  /// 登录用户
  ///
  /// 返回Either类型，左侧为失败，右侧为成功的User实体
  Future<Either<Failure, User>> login(String email, String password);

  /// 注册新用户
  Future<Either<Failure, User>> register(String name, String email, String password);

  /// 获取当前登录用户
  Future<Either<Failure, User?>> getCurrentUser();

  /// 登出用户
  Future<Either<Failure, void>> logout();

  /// 重置密码
  Future<Either<Failure, void>> resetPassword(String email);
}
