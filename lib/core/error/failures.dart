// import 'package:equatable/equatable.dart'; // 移除 equatable 依赖

abstract class Failure {
  final String message;

  const Failure(this.message);

//   @override // 移除 Equatable 的 props
//   List<Object> get props => [];
}

// 通用失败
class ServerFailure extends Failure {
  const ServerFailure([super.message = '服务器错误']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = '缓存错误']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '网络错误']);
}
