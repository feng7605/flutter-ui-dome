import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_notifier.dart';
import 'app_router.dart';

/// A class that provides route guards and redirection logic
class RouteGuards {
  /// Refreshable listenable for auth state
  final AuthStateNotifier refreshListenable;
  
  /// Creates a new [RouteGuards]
  RouteGuards({
    AuthStateNotifier? authStateNotifier,
  }) : refreshListenable = authStateNotifier ?? AuthStateNotifier();

  /// Global redirection logic
  String? globalRedirect(BuildContext context, GoRouterState state) {
    final isSplash = state.matchedLocation == Routes.splash;
    final isAuthPage = state.matchedLocation == Routes.login ||
        state.matchedLocation == Routes.register;
    final isMockLogin = state.matchedLocation == Routes.mockLogin;

    // If the user is on the splash page or mock login page, allow it
    if (isSplash || isMockLogin) {
      return null;
    }

    // Get auth state
    final isLoggedIn = refreshListenable.isLoggedIn;

    // If the user is not logged in and not on an auth page, redirect to login
    if (!isLoggedIn && !isAuthPage) {
      return Routes.mockLogin;
    }

    // If the user is logged in and on an auth page, redirect to home
    if (isLoggedIn && isAuthPage) {
      return Routes.home;
    }

    // Allow navigation
    return null;
  }

  /// Auth required guard
  String? authGuard(BuildContext context, GoRouterState state) {
    if (!refreshListenable.isLoggedIn) {
      return Routes.login;
    }
    return null;
  }

  /// Guest only guard (for auth pages)
  String? guestGuard(BuildContext context, GoRouterState state) {
    if (refreshListenable.isLoggedIn) {
      return Routes.home;
    }
    return null;
  }
}

/// A notifier for authentication state that listens to Riverpod
class AuthStateNotifier extends ChangeNotifier {
  final Ref? _ref;
  bool _isLoggedIn = false;

  /// Whether the user is logged in
  bool get isLoggedIn => _isLoggedIn;

  /// Creates a new [AuthStateNotifier]
  AuthStateNotifier([this._ref]) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    if (_ref != null) {
      // Listen to auth state changes
      _ref.listen<AuthState>(
        authStateProvider,
        (previous, next) {
          final isAuthenticated = next.isAuthenticated;
          if (_isLoggedIn != isAuthenticated) {
            _isLoggedIn = isAuthenticated;
            notifyListeners();
          }
        },
      );
    }
  }

  /// Sets the logged in state manually (for testing or when not using Riverpod)
  set isLoggedIn(bool value) {
    if (_isLoggedIn != value) {
      _isLoggedIn = value;
      notifyListeners();
    }
  }
}
