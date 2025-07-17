import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

// 定义 UseCase 接口
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// 定义 NoParams 类
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
