// core/routing/router_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_frame/core/di/providers.dart';
import 'package:flutter_frame/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';
import 'route_guards.dart';
// 这是一个常见的辅助类，你需要把它添加到你的项目中
import 'go_router_refresh_stream.dart'; 

/// Provider for the refresh stream that GoRouter will listen to.
/// It listens to the auth state changes.
final routerRefreshListenableProvider = Provider<Listenable>((ref) {
  // 监听 authStateProvider 的变化
  // .stream 会在 authStateProvider 的状态改变时发出事件
  final stream = ref.watch(authStateProvider.notifier).stream;
  return GoRouterRefreshStream(stream);
});

/// Provider for the global AppRouter instance.
final routerProvider = Provider<AppRouter>((ref) {
  // 1. 依赖动态路由
  final dynamicRoutes = ref.watch(dynamicRoutesProvider);
  
  // 2. 依赖 RouteGuards
  final routeGuards = ref.watch(routeGuardsProvider);
  
  // 3. 依赖 refresh listenable
  final refreshListenable = ref.watch(routerRefreshListenableProvider);

  // 4. 创建 AppRouter 实例，并将所有依赖传入
  return AppRouter(
    dynamicRoutes: dynamicRoutes,
    routeGuards: routeGuards,
    refreshListenable: refreshListenable, // 将 listenable 传递给 AppRouter
  );
});