import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../error/app_logger.dart';
import '../error/error_handler.dart';
import '../localization/app_localization.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../storage/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../network/network_info.dart';

// Storage providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(sharedPreferences: sharedPreferences);
});

// Logger providers
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger());

// Error handling providers
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return ErrorHandler(logger: logger);
});

// Network providers
final connectionCheckerProvider = Provider<InternetConnectionChecker>((ref) => InternetConnectionChecker());

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return createNetworkInfo();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return ConnectivityService(logger: logger);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(appLoggerProvider);
  return ApiClient(
    connectivityService: connectivityService,
    errorHandler: errorHandler,
    logger: logger,
  );
});

// Theme providers
final themeManagerProvider = Provider<AppThemeManager>((ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  return AppThemeManager(storageService: storageService);
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final themeManager = ref.watch(themeManagerProvider);
  return ThemeModeNotifier(ThemeMode.system);
});

// Localization providers
final localizationProvider = Provider<AppLocalization>((ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  return AppLocalization(
    storageService: storageService,
    errorHandler: errorHandler,
  );
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(const Locale('en', 'US'));
});

// External dependencies
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final dynamicRoutesProvider = Provider<List<GoRoute>>((ref) {
  throw UnimplementedError('The dynamicRoutesProvider must be overridden.');
});