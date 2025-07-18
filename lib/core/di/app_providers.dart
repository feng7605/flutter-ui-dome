// core/di/app_providers.dart

import 'package:flutter_frame/core/di/providers.dart';
import 'package:flutter_frame/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 负责所有应用启动前必须完成的异步任务。
/// 它会按顺序执行，确保依赖关系正确。
final appBootstrapProvider = FutureProvider<void>((ref) async {
  // 1. 初始化本地化服务
  // 使用 read 是因为我们只需要在启动时执行一次，不需要监听它后续的变化
  final localization = ref.read(localizationProvider);
  await localization.init();
  
  // 2. 更新 locale provider 以反映初始 locale
  final currentLocale = localization.locale;
  // 这里使用 read().notifier 是安全的，因为它只是触发一个状态更新
  ref.read(localeProvider.notifier).update(currentLocale);

  // 3. 检查用户当前的认证状态 (代替旧的 addPostFrameCallback)
  // 这是另一个关键的启动任务
  await ref.read(authStateProvider.notifier).checkAuth();
  
  // 你可以在这里添加更多的异步初始化任务，比如：
  // - 从服务器获取初始配置
  // - 初始化分析服务
  // - 等等...

  // 所有任务完成后，FutureProvider 的状态会自动从 loading 变为 data
});