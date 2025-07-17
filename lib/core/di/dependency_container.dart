import 'package:flutter_frame/core/error/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../error/error_handler.dart';
import '../localization/app_localization.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../permissions/permission_handler_service.dart';
import '../routing/app_router.dart';
import '../storage/local_storage_service.dart';
import '../theme/app_theme.dart';

/// DependencyContainer manages all the dependencies of the application.
/// It uses Riverpod's ProviderContainer to make dependencies available throughout the app.
class DependencyContainer {
  /// The global provider container for dependency injection
  late final ProviderContainer container;

  /// Private map of dependencies registered manually
  final _dependencies = <Type, Object>{};

  /// Initializes the dependency container with all required services.
  /// This should be called early in the application startup.
  Future<void> initialize(AppConfig config) async {
    // Register the app config
    _dependencies[AppConfig] = config;

    // Create the ProviderContainer
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
    );

    // Register logger
    final logger = container.read(appLoggerProvider);
    _dependencies[AppLogger] = logger;
    logger.i('DependencyContainer: Initializing dependencies...');

    // Register error handler
    final errorHandler = container.read(errorHandlerProvider);
    _dependencies[ErrorHandler] = errorHandler;

    // Register connectivity service
    final connectivityService = container.read(connectivityServiceProvider);
    _dependencies[ConnectivityService] = connectivityService;
    await connectivityService.initialize();

    // Register API client
    final apiClient = container.read(apiClientProvider);
    _dependencies[ApiClient] = apiClient;

    // Register local storage service
    final storageService = container.read(localStorageServiceProvider);
    _dependencies[LocalStorageService] = storageService;
    await storageService.initialize();

    // Register permission handler service
    final permissionService = container.read(permissionHandlerServiceProvider);
    _dependencies[PermissionHandlerService] = permissionService;

    // Register theme manager
    final themeManager = container.read(themeManagerProvider);
    _dependencies[AppThemeManager] = themeManager;

    // Register localization manager
    final localization = container.read(appLocalizationProvider);
    _dependencies[AppLocalization] = localization;
    await localization.init();

    // Register router
    final router = container.read(appRouterProvider);
    _dependencies[AppRouter] = router;

    logger.i('DependencyContainer: All dependencies initialized');
  }

  /// Resolves a dependency of type T
  T resolve<T>() {
    final dependency = _dependencies[T];
    if (dependency == null) {
      throw Exception('Dependency of type $T not found');
    }
    return dependency as T;
  }
}

/// Provider for AppConfig
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig must be provided externally');
});

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided externally');
});

/// Provider for AppLogger
final appLoggerProvider = Provider<AppLogger>((ref) {
  final config = ref.watch(appConfigProvider);
  return AppLogger();
});

/// Provider for ErrorHandler
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return ErrorHandler(logger: logger);
});

/// Provider for ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return ConnectivityService(logger: logger);
});

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(appLoggerProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return ApiClient(
    config: config,
    logger: logger,
    errorHandler: errorHandler,
    connectivityService: connectivityService,
  );
});

/// Provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final logger = ref.watch(appLoggerProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(logger: logger, sharedPreferences: prefs);
});

/// Provider for PermissionHandlerService
final permissionHandlerServiceProvider =
    Provider<PermissionHandlerService>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return PermissionHandlerService(logger: logger);
});

/// Provider for AppThemeManager
final themeManagerProvider = Provider<AppThemeManager>((ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  return AppThemeManager(storageService: storageService);
});

/// Provider for AppLocalization
final appLocalizationProvider = Provider<AppLocalization>((ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  return AppLocalization(
    storageService: storageService,
    errorHandler: errorHandler,
  );
});

/// Provider for AppRouter
final appRouterProvider = Provider<AppRouter>((ref) {
  return AppRouter();
});
