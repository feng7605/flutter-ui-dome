import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

/// 登录用例
///
/// 实现用户登录的业务逻辑
class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) {
    return repository.login(params.email, params.password);
  }
}

/// 登录参数
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
