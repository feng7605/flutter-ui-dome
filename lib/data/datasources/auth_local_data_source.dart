import 'dart:convert';

import '../../core/error/exceptions.dart';
import '../../core/storage/local_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  /// 获取本地缓存的用户
  /// 
  /// 如果没有缓存用户，则返回null
  /// 如果解析错误，抛出[CacheException]
  Future<UserModel?> getCachedUser();

  /// 缓存用户信息
  Future<void> cacheUser(UserModel user);

  /// 清除缓存的用户信息
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorageService localStorageService;
  static const String CACHED_USER_KEY = 'CACHED_USER';

  AuthLocalDataSourceImpl({required this.localStorageService});

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = await localStorageService.getString(CACHED_USER_KEY);
      if (jsonString == null) {
        return null;
      }
      return UserModel.fromJson(json.decode(jsonString));
    } catch (e) {
      throw CacheException('Failed to retrieve cached user');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await localStorageService.setString(
        CACHED_USER_KEY,
        json.encode(user.toJson()),
      );
    } catch (e) {
      throw CacheException('Failed to cache user');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await localStorageService.remove(CACHED_USER_KEY);
    } catch (e) {
      throw CacheException('Failed to clear cached user');
    }
  }
}
