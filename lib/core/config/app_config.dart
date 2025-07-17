import 'package:flutter/foundation.dart';

/// Enum representing different environment configurations
enum Environment {
  development,
  staging,
  production,
}

/// A class that holds application configuration
class AppConfig {
  /// The current environment
  final Environment environment;

  /// Base URL for API requests
  final String apiBaseUrl;

  /// API key for authentication (if needed)
  final String? apiKey;

  /// Timeout duration for network requests in seconds
  final int networkTimeoutSeconds;

  /// Whether to enable detailed logging
  final bool enableDetailedLogs;

  /// Whether to enable crash reporting
  final bool enableCrashReporting;

  /// App version
  final String appVersion;

  /// Build number
  final String buildNumber;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.apiKey,
    this.networkTimeoutSeconds = 30,
    this.enableDetailedLogs = false,
    this.enableCrashReporting = false,
    required this.appVersion,
    required this.buildNumber,
  });

  /// Development environment configuration
  factory AppConfig.development() {
    return const AppConfig(
      environment: Environment.development,
      apiBaseUrl: 'https://api-dev.example.com',
      apiKey: 'dev-api-key',
      networkTimeoutSeconds: 60,
      enableDetailedLogs: true,
      enableCrashReporting: false,
      appVersion: '1.0.0',
      buildNumber: '1',
    );
  }

  /// Staging environment configuration
  factory AppConfig.staging() {
    return const AppConfig(
      environment: Environment.staging,
      apiBaseUrl: 'https://api-staging.example.com',
      apiKey: 'staging-api-key',
      networkTimeoutSeconds: 45,
      enableDetailedLogs: true,
      enableCrashReporting: true,
      appVersion: '1.0.0',
      buildNumber: '1',
    );
  }

  /// Production environment configuration
  factory AppConfig.production() {
    return const AppConfig(
      environment: Environment.production,
      apiBaseUrl: 'https://api.example.com',
      apiKey: 'prod-api-key',
      networkTimeoutSeconds: 30,
      enableDetailedLogs: false,
      enableCrashReporting: true,
      appVersion: '1.0.0',
      buildNumber: '1',
    );
  }

  /// Returns true if the current environment is development
  bool get isDevelopment => environment == Environment.development;

  /// Returns true if the current environment is staging
  bool get isStaging => environment == Environment.staging;

  /// Returns true if the current environment is production
  bool get isProduction => environment == Environment.production;

  /// Returns true if detailed logs are enabled
  bool get isDetailedLoggingEnabled => enableDetailedLogs || isDevelopment;

  /// Returns a copy of this AppConfig with the specified fields replaced with new values
  AppConfig copyWith({
    Environment? environment,
    String? apiBaseUrl,
    String? apiKey,
    int? networkTimeoutSeconds,
    bool? enableDetailedLogs,
    bool? enableCrashReporting,
    String? appVersion,
    String? buildNumber,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiKey: apiKey ?? this.apiKey,
      networkTimeoutSeconds:
          networkTimeoutSeconds ?? this.networkTimeoutSeconds,
      enableDetailedLogs: enableDetailedLogs ?? this.enableDetailedLogs,
      enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
    );
  }

  @override
  String toString() {
    return '''
    AppConfig:
      environment: $environment
      apiBaseUrl: $apiBaseUrl
      apiKey: ${kReleaseMode ? '***' : apiKey}
      networkTimeoutSeconds: $networkTimeoutSeconds
      enableDetailedLogs: $enableDetailedLogs
      enableCrashReporting: $enableCrashReporting
      appVersion: $appVersion
      buildNumber: $buildNumber
    ''';
  }
}
