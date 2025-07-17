class ServerException implements Exception {
  final String message;
  
  ServerException([this.message = '服务器错误']);
  
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  
  CacheException([this.message = '缓存错误']);
  
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException([this.message = '网络错误']);
  
  @override
  String toString() => message;
}