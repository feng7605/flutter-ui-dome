import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_router.dart';
import '../core/config/app_config.dart';

/// 开发环境下的工具按钮
/// 
/// 只在开发环境中显示，用于快速访问开发工具
class DevToolsButton extends StatelessWidget {
  /// 创建 DevToolsButton 实例
  const DevToolsButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 仅在开发环境中显示
    if (!AppConfig.development().isDevelopment) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 20,
      bottom: 80,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: FloatingActionButton(
          backgroundColor: Colors.amber.shade800,
          onPressed: () {
            _showDevTools(context);
          },
          child: const Icon(
            Icons.developer_mode,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 显示开发工具菜单
  void _showDevTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('模拟登录'),
                onTap: () {
                  Navigator.pop(context);
                  context.go(Routes.mockLogin);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('关闭'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
