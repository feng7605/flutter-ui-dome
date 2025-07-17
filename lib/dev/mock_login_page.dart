import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/app_localization.dart';
import '../core/routing/app_router.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import 'mock_auth_helper.dart';

/// 开发环境使用的模拟登录页面
class MockLoginPage extends ConsumerWidget {
  /// 创建一个 MockLoginPage 实例
  const MockLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听认证状态
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('login')),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.developer_mode,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  '开发者模式',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '当前状态: ${authState.isAuthenticated ? '已登录' : '未登录'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (authState.user != null) ...[
                  const SizedBox(height: 8),
                  Text('用户: ${authState.user!.name}'),
                  Text('邮箱: ${authState.user!.email}'),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isAuthenticated
                      ? () => MockAuthHelper.mockLogout(ref)
                      : () => MockAuthHelper.mockSuccessfulLogin(ref),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: Text(
                    authState.isAuthenticated ? '模拟退出登录' : '模拟登录成功',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                if (authState.isAuthenticated)
                  ElevatedButton(
                    onPressed: () {
                      context.go(Routes.home);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text(
                      '进入主界面',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
