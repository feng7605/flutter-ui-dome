import 'package:dartz/dartz.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';

/// 获取当前用户用例
///
/// 获取当前已登录用户的信息
class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
