import 'package:flutter_frame/core/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'route_guards.dart';

/// 提供一个全局的AppRouter实例
/// 
/// 这个Provider在初始化时会将Ref传递给RouteGuards，
/// 这样RouteGuards可以监听Riverpod的状态变化
final routerProvider = Provider<AppRouter>((ref) {
  final dynamicRoutes = ref.watch(dynamicRoutesProvider);
  final routeGuards = RouteGuards(
    // 提供ref给AuthStateNotifier，使其能够监听auth状态变化
    authStateNotifier: AuthStateNotifier(ref),
  );
  
  return AppRouter(
    dynamicRoutes: dynamicRoutes,
    routeGuards: routeGuards,
  );
});
