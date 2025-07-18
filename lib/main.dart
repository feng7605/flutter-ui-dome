// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frame/core/di/app_providers.dart';
import 'package:flutter_frame/core/routing/dynamic_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'injection_container.dart' as di;

import 'core/config/app_config.dart';
import 'core/di/providers.dart';
import 'core/routing/router_provider.dart';

void main() async {
  // 保持所有同步初始化不变
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  AppConfig.development();
  final sharedPreferences = await SharedPreferences.getInstance();
  await di.init();
  final List<GoRoute> dynamicRoutes = await loadDynamicRoutes();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        dynamicRoutesProvider.overrideWithValue(dynamicRoutes),
      ],
      child: const MyApp(),
    ),
  );
}

// -----------------------------------------------------
// InitApp 和 _InitAppState 已被完全移除
// -----------------------------------------------------

/// 应用的根 Widget，负责处理启动流程中的不同状态。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听应用引导程序的 Provider
    final bootstrap = ref.watch(appBootstrapProvider);

    // 使用 .when 来优雅地处理加载、错误和数据状态
    return bootstrap.when(
      data: (_) => const MainApp(), // 初始化成功，显示主应用
      loading: () => const LoadingScreen(), // 显示加载屏幕
      error: (err, stack) => ErrorScreen(error: err), // 显示错误屏幕
    );
  }
}

/// 主应用 Widget，在所有初始化任务完成后显示。
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化错误处理
    final errorHandler = ref.watch(errorHandlerProvider);
    FlutterError.onError = errorHandler.handleFlutterError;

    // 获取主题和本地化配置
    final themeManager = ref.watch(themeManagerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localization = ref.watch(localizationProvider);
    final locale = ref.watch(localeProvider);

    // 获取路由
    final appRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Flutter Frame',
      debugShowCheckedModeBanner: false,

      // 主题
      theme: themeManager.lightTheme,
      darkTheme: themeManager.darkTheme,
      themeMode: themeMode,

      // 本地化
      locale: locale,
      supportedLocales: localization.supportedLocales.values.toList(),
      localizationsDelegates: [
        localization.createDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 路由
      routerConfig: appRouter.router,
    );
  }
}

// 辅助 Widget 保持不变
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Object error; // 接受 Object 类型更通用
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // 在开发时可以打印更详细的错误
            child: Text('Failed to initialize the app: $error'),
          ),
        ),
      ),
    );
  }
}