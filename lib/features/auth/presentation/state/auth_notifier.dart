import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/usecases/get_current_user_usecase.dart';
import '../../../../domain/usecases/login_usecase.dart';
import '../../../../domain/usecases/register_usecase.dart';
import '../../../../core/usecases/usecase.dart';

/// 认证状态
@immutable
class AuthState {
  /// True if a process like login or register is in progress.
  final bool isLoading;
  /// The currently authenticated user. Null if not authenticated.
  final User? user;
  /// An error message, if any auth operation failed.
  final String? errorMessage;
  /// True if the initial authentication check has not yet completed.
  final bool isInitial;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.isInitial = false,
  });

  /// The initial state of authentication before any checks are made.
  const AuthState.initial()
      : isLoading = false,
        user = null,
        errorMessage = null,
        isInitial = true;

  /// True if a user is currently authenticated.
  bool get isAuthenticated => user != null;

  /// Creates a copy of the state with optional new values.
  AuthState copyWith({
    bool? isLoading,
    User? user,
    // Use a wrapper to differentiate between setting null and not changing.
    ValueGetter<String?>? errorMessage, 
    bool? isInitial,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isInitial: isInitial ?? this.isInitial,
    );
  }
}

/// Manages the authentication state and business logic.
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        // Start with the .initial() state
        super(const AuthState.initial());
        
  // Note: The initial auth check is now handled by the appBootstrapProvider
  // to ensure it completes before the app UI loads.
  // If you want it to run when the provider is first used, you can call it here.

  /// Checks for a currently signed-in user (e.g., from a stored token).
  Future<void> checkAuth() async {
    final result = await _getCurrentUserUseCase(NoParams());
    
    // After the check, the state is no longer 'initial'.
    result.fold(
      (failure) => state = AuthState(user: null, errorMessage: failure.message),
      (user) => state = AuthState(user: user),
    );
  }

  /// Logs in a user with email and password.
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null, isInitial: false);
    
    final params = LoginParams(email: email, password: password);
    final result = await _loginUseCase(params);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: () => failure.message),
      (user) => state = state.copyWith(isLoading: false, user: user, errorMessage: () => null),
    );
  }

  /// Registers a new user.
  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null, isInitial: false);
    
    final params = RegisterParams(name: name, email: email, password: password);
    final result = await _registerUseCase(params);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: () => failure.message),
      (user) => state = state.copyWith(isLoading: false, user: user, errorMessage: () => null),
    );
  }

  /// Clears any existing error message from the state.
  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }
}