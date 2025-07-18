// core/di/app_providers.dart

import 'package:flutter_frame/core/bootstrap/module_bootstrapper.dart';
import 'package:flutter_frame/core/di/providers.dart';
import 'package:flutter_frame/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// 1. 创建一个列表，包含所有模块的引导程序 Provider
final List<Provider<ModuleBootstrap>> _moduleBootstrappers = [
  authBootstrapProvider,
];

/// 应用启动前必须完成的异步任务它会按顺序执行，确保依赖关系正确。
final appBootstrapProvider = FutureProvider<void>((ref) async {
  // 1. 初始化本地化服务
  // 使用 read 是因为我们只需要在启动时执行一次，不需要监听它后续的变化
  final localization = ref.read(localizationProvider);
  await localization.init();
  
  // 2. 更新 locale provider 以反映初始 locale
  final currentLocale = localization.locale;
  // 这里使用 read().notifier 是安全的，因为它只是触发一个状态更新
  ref.read(localeProvider.notifier).update(currentLocale);

  // 使用 Future.wait 可以并行执行所有不互相依赖的初始化任务，提高启动速度
  await Future.wait(
    _moduleBootstrappers.map((bootstrapperProvider) {
      // 读取每个 bootstrapper provider 来获取初始化函数
      final bootstrapFunction = ref.read(bootstrapperProvider);
      // 执行该函数
      return bootstrapFunction(ref);
    }),
  );

  // 所有任务完成后，FutureProvider 的状态会自动从 loading 变为 data
});