import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.login(email, password);
        await localDataSource.cacheUser(remoteUser);
        return Right(remoteUser);
      } on ServerException {
        return const Left(ServerFailure('登录失败，请检查您的凭据'));
      }
    } else {
      return const Left(NetworkFailure('请检查您的网络连接'));
    }
  }

  @override
  Future<Either<Failure, User>> register(String name, String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.register(name, email, password);
        await localDataSource.cacheUser(remoteUser);
        return Right(remoteUser);
      } on ServerException {
        return const Left(ServerFailure('注册失败，请稍后再试'));
      }
    } else {
      return const Left(NetworkFailure('请检查您的网络连接'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final localUser = await localDataSource.getCachedUser();
      if (localUser != null) {
        return Right(localUser);
      } else {
        return const Right(null);
      }
    } on CacheException {
      return const Left(CacheFailure('无法获取用户信息'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearUser();
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure('登出失败'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPassword(email);
        return const Right(null);
      } on ServerException {
        return const Left(ServerFailure('重置密码失败'));
      }
    } else {
      return const Left(NetworkFailure('请检查您的网络连接'));
    }
  }
}
