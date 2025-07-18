import 'package:flutter/material.dart';
import 'package:flutter_frame/features/asr/presentation/pages/recognition_page.dart';
import 'package:flutter_frame/presentation/pages/speech/speech_page.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../dev/mock_login_page.dart';
import '../../dev/dev_tools_button.dart';
import 'route_guards.dart';

/// A service for app navigation
class AppRouter {
  final RouteGuards _routeGuards;
  final List<GoRoute> _dynamicRoutes; // 接收动态路由
  final Listenable? _refreshListenable; // 新增

  /// Creates a new [AppRouter]
  AppRouter({
    required RouteGuards routeGuards,
    List<GoRoute>? dynamicRoutes,
    Listenable? refreshListenable, // 新增
  })  : _routeGuards = routeGuards,
        _dynamicRoutes = dynamicRoutes ?? [],
        _refreshListenable = refreshListenable;

  /// The GoRouter instance
  late final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: _routeGuards.globalRedirect,
    refreshListenable: _refreshListenable,
    errorBuilder: (context, state) => _notFoundPage(context, state),
    routes: [
      // Splash route
      GoRoute(
        path: Routes.splash,
        name: Routes.splash.substring(1),
        builder: (context, state) => const SplashPage(),
      ),

      // Auth routes
      GoRoute(
        path: Routes.login,
        name: Routes.login.substring(1),
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.register,
        name: Routes.register.substring(1),
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: Routes.mockLogin,
        name: Routes.mockLogin.substring(1),
        builder: (context, state) => const MockLoginPage(),
      ),
      // App shell with nested routes
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          // Home route and nested routes
          GoRoute(
            path: Routes.home,
            name: Routes.home.substring(1),
            builder: (context, state) => const HomePage(),
            routes: [
              // Example of a nested route
              GoRoute(
                path: 'details/:id',
                name: 'details',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DetailsPage(id: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.test,
            name: Routes.test.substring(1),
            builder: (context, state) => const SpeechPage(),
          ),
          // Settings route
          GoRoute(
            path: Routes.settings,
            name: Routes.settings.substring(1),
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      //动态路由
      ..._dynamicRoutes, 
    ],
  );

  /// 404 page for unknown routes
  Widget _notFoundPage(BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('The page you are looking for does not exist.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go(Routes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Route path constants
class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String test = '/test';
  static const String settings = '/settings';
  static const String mockLogin = '/mock-login';

  // Private constructor to prevent instantiation
  Routes._();
}

/// Route name constants
class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String home = 'home';
  static const String settings = 'settings';
  static const String details = 'details';
  static const String mockLogin = 'mock-login';
  static const String test = 'test';

  // Private constructor to prevent instantiation
  RouteNames._();
}

/// A scaffold with a bottom navigation bar
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          const DevToolsButton(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_sharp),
            label: 'Test',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouter route = GoRouter.of(context);
    final String location =
        route.routerDelegate.currentConfiguration.uri.toString();

    if (location.startsWith(Routes.home)) {
      return 0;
    }
    if (location.startsWith(Routes.settings)) {
      return 1;
    }

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go(Routes.home);
        break;
      case 1:
        GoRouter.of(context).go(Routes.test);
        break;
      case 2:
        GoRouter.of(context).go(Routes.settings);
        break;
    }
  }
}

/// A details page example
class DetailsPage extends StatelessWidget {
  final String id;

  const DetailsPage({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Details for item $id',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go(Routes.home),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
