import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/user_model.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../features/auth/presentation/providers/auth_providers.dart';

/// 开发环境下模拟身份验证的助手类
class MockAuthHelper {
  /// 模拟成功登录
  /// 
  /// 创建一个模拟用户并将其缓存到本地存储
  static Future<void> mockSuccessfulLogin(WidgetRef ref) async {
    try {
      // 创建一个模拟用户
      final mockUser = UserModel(
        id: const Uuid().v4(),
        name: 'Mock User',
        email: 'mock@example.com',
        profilePicture: null,
        isVerified: true,
        createdAt: DateTime.now(),
      );

      // 获取本地数据源并缓存用户
      final localDataSource = ref.read(authLocalDataSourceProvider);
      await localDataSource.cacheUser(mockUser);
      
      // 重新检查身份验证状态
      await ref.read(authStateProvider.notifier).checkAuth();

      debugPrint('Mock login successful - User: ${mockUser.name}');
    } catch (e) {
      debugPrint('Mock login failed: $e');
    }
  }

  /// 模拟退出登录
  static Future<void> mockLogout(WidgetRef ref) async {
    try {
      // 获取本地数据源并清除用户
      final localDataSource = ref.read(authLocalDataSourceProvider);
      await localDataSource.clearUser();
      
      // 重新检查身份验证状态
      await ref.read(authStateProvider.notifier).checkAuth();

      debugPrint('Mock logout successful');
    } catch (e) {
      debugPrint('Mock logout failed: $e');
    }
  }
}
