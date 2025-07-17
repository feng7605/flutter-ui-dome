import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

/// 注册用例
///
/// 实现用户注册的业务逻辑
class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) {
    return repository.register(params.name, params.email, params.password);
  }
}

/// 注册参数
class RegisterParams extends Equatable {
  final String name;
  final String email;
  final String password;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, password];
}
