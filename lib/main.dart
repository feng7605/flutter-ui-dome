import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frame/core/routing/dynamic_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'injection_container.dart' as di;

import 'core/config/app_config.dart';
import 'core/di/providers.dart';
import 'core/routing/router_provider.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize app configuration for the current environment
  AppConfig.development();

  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize the app with Riverpod
  await di.init();

  final List<GoRoute> dynamicRoutes = await loadDynamicRoutes();
  
  runApp(
    ProviderScope(
      overrides: [
        // Override the SharedPreferences provider with the actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        dynamicRoutesProvider.overrideWithValue(dynamicRoutes),
      ],
      child: const InitApp(),
    ),
  );
}

/// Widget to initialize app services before showing the main app
class InitApp extends ConsumerStatefulWidget {
  /// Creates a new instance of [InitApp]
  const InitApp({super.key});

  @override
  ConsumerState<InitApp> createState() => _InitAppState();
}

class _InitAppState extends ConsumerState<InitApp> {
  late Future<void> _initServices;

  @override
  void initState() {
    super.initState();
    _initServices = _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize localization
      final localization = ref.read(localizationProvider);
      await localization.init();
      
      // Force refresh of the locale
      final currentLocale = localization.locale;
      ref.read(localeProvider.notifier).update(currentLocale);
    } catch (e) {
      debugPrint('初始化服务时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initServices,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

/// The main application widget
class MyApp extends ConsumerWidget {
  /// Creates a new instance of [MyApp]
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize error handling
    final errorHandler = ref.watch(errorHandlerProvider);
    FlutterError.onError = errorHandler.handleFlutterError;

    // Get theme manager and current theme mode
    final themeManager = ref.watch(themeManagerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Get localization manager and current locale
    final localization = ref.watch(localizationProvider);
    final locale = ref.watch(localeProvider);

    // Initialize the router
    final appRouter = ref.watch(routerProvider);
    
    
    // Check authentication state on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).checkAuth();
    });

    return MaterialApp.router(
      title: 'Flutter Frame',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: themeManager.lightTheme,
      darkTheme: themeManager.darkTheme,
      themeMode: themeMode,

      // Localization configuration
      locale: locale,
      supportedLocales: localization.supportedLocales.values.toList(),
      localizationsDelegates: [
        localization.createDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Routing configuration
      routerConfig: appRouter.router,
    );
  }
}
