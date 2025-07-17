import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// 网络信息接口
abstract class NetworkInfo {
  /// 检查网络连接状态
  Future<bool> get isConnected;
}

/// 标准网络信息实现 (用于移动端)
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}

/// Web平台专用网络信息实现
/// 
/// 由于InternetConnectionChecker在Web平台不可用，
/// 此实现始终返回true，实际连接状态将由API请求时的错误处理来管理
class WebNetworkInfoImpl implements NetworkInfo {
  const WebNetworkInfoImpl();
  
  @override
  Future<bool> get isConnected async => true;
}

/// 创建合适的NetworkInfo实例
NetworkInfo createNetworkInfo() {
  if (kIsWeb) {
    return const WebNetworkInfoImpl();
  } else {
    return NetworkInfoImpl(InternetConnectionChecker());
  }
}