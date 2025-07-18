// core/routing/route_guards.dart

import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'app_router.dart'; // For Routes constants

/// Provider for the RouteGuards instance.
final routeGuardsProvider = Provider<RouteGuards>((ref) {
  return RouteGuards(ref);
});

/// A class that provides route guards and redirection logic for GoRouter.
class RouteGuards {
  final Ref _ref;

  /// Creates a new [RouteGuards] instance that uses Riverpod's [Ref] for state access.
  RouteGuards(this._ref);

  /// Global redirection logic that is checked on every navigation.
  String? globalRedirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final isLoggedIn = authState.isAuthenticated;
    final currentRoute = state.matchedLocation;

    // --- START OF THE FIX ---

    // 1. Define a list of routes that are always publicly accessible, regardless of login state.
    final publicRoutes = [
      Routes.splash,
      Routes.login,
      Routes.register,
    ];

    // 2. In debug mode, add development-only routes to the public list.
    if (kDebugMode) {
      publicRoutes.add(Routes.mockLogin);
      // You can add more dev-only routes here, e.g., a dev tools page
      publicRoutes.add('/dev-tools'); 
      final isAuthPage = state.matchedLocation == Routes.login || state.matchedLocation == Routes.register;
      if (!isLoggedIn && !isAuthPage) {
        return Routes.mockLogin;
      }
    }

    final isGoingToPublicRoute = publicRoutes.contains(currentRoute);

    // --- END OF THE FIX ---
    
    // If the app is still initializing, let the splash screen handle logic.
    // Do not redirect anywhere yet.
    if (authState.isInitial) {
      return null;
    }
    
    // If the user is logged in and tries to access a standard auth page (not mock login), redirect to home.
    if (isLoggedIn && (currentRoute == Routes.login || currentRoute == Routes.register)) {
      return Routes.home;
    }

    // If the user is NOT logged in and is trying to access a page that is NOT public,
    // redirect them to the login page.
    if (!isLoggedIn && !isGoingToPublicRoute) {
      return Routes.login;
    }

    // In all other cases (e.g., logged in user accessing a protected page, or any user accessing a public page),
    // allow navigation.
    return null;
  }
}