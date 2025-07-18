import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_notifier.dart';
import 'app_router.dart';

// 为新的 RouteGuards 创建一个 Provider
final routeGuardsProvider = Provider<RouteGuards>((ref) {
  return RouteGuards(ref);
});

/// A class that provides route guards and redirection logic
class RouteGuards {
  final Ref _ref;

  /// Creates a new [RouteGuards] instance that uses Riverpod's [Ref] for state access.
  RouteGuards(this._ref);

  /// Global redirection logic that is checked on every navigation.
  String? globalRedirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final isLoggedIn = authState.isAuthenticated;

    // Define which routes are part of the authentication flow (publicly accessible to unauthenticated users)
    final authFlowRoutes = [Routes.login, Routes.register, Routes.mockLogin];
    final isGoingToAuthFlow = authFlowRoutes.contains(state.matchedLocation);

    // If the app is still in its initial state (auth check hasn't completed),
    // and we are not on the splash screen, don't redirect yet. Let the splash screen handle it.
    if (authState.isInitial && state.matchedLocation != Routes.splash) {
      // Returning null means "do nothing, wait for a refresh".
      return null;
    }
    
    // If the user is logged in and tries to access a page in the auth flow (like login),
    // redirect them to the home page.
    if (isLoggedIn && isGoingToAuthFlow) {
      return Routes.home;
    }

    // If the user is NOT logged in and tries to access a protected page
    // (any page not in the auth flow and not the splash screen), redirect them to the login page.
    if (!isLoggedIn && !isGoingToAuthFlow && state.matchedLocation != Routes.splash) {
      return Routes.login;
    }

    // In all other cases, allow navigation.
    return null;
  }
}