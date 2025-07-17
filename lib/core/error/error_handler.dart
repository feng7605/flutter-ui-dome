import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import 'app_exception.dart';
import 'app_logger.dart';

/// A service for handling errors
class ErrorHandler {
  final AppLogger _logger;

  /// Creates a new instance of [ErrorHandler]
  ErrorHandler({required AppLogger logger}) : _logger = logger;

  /// Records a non-fatal error
  void recordNonFatalError(Object error, StackTrace stackTrace) {
    final errorMessage = error is AppException
        ? _formatErrorMessage(error)
        : 'Error: ${error.toString()}';

    _logger.e(errorMessage, error, stackTrace);

    // TODO: Send to crash reporting service
  }

  /// Handles a Flutter error
  void handleFlutterError(FlutterErrorDetails details) {
    try {
      _logger.e(
        'Flutter error: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
    } catch (e, stackTrace) {
      _logger.e('Error handling Flutter error', e, stackTrace);
    }
  }

  /// Handles an asynchronous error
  void handleAsyncError(Object error, StackTrace stackTrace) {
    try {
      // If this is an AppException, handle it specifically
      if (error is AppException) {
        _logger.e(
            'Async error: ${_formatErrorMessage(error)}', error, stackTrace);
      } else {
        _logger.e('Async error: ${error.toString()}', error, stackTrace);
      }

      // TODO: Send to crash reporting service
    } catch (e, stackTrace) {
      _logger.e('Error handling async error', e, stackTrace);
    }
  }

  /// Shows an error snackbar
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows an error dialog
  Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(buttonText ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a network error
  void showNetworkError(BuildContext context, AppException exception) {
    showErrorSnackBar(
      context,
      exception.message,
    );
  }

  /// Shows an authentication error
  void showAuthError(BuildContext context, AppException exception) {
    showErrorDialog(
      context,
      title: 'Authentication Error',
      message: exception.message,
    );
  }

  /// Shows a validation error
  void showValidationError(
      BuildContext context, ValidationException exception) {
    showErrorDialog(
      context,
      title: 'Validation Error',
      message: exception.message,
    );
  }

  /// Runs a function within a try-catch block and handles any errors
  Future<T> runCatching<T>({
    required Future<T> Function() action,
    required BuildContext context,
    String? errorMessage,
    bool showError = true,
  }) async {
    try {
      return await action();
    } on AppException catch (e, stackTrace) {
      _logger.e(errorMessage ?? 'Error during operation', e, stackTrace);

      if (showError) {
        if (e is NetworkException) {
          showNetworkError(context, e);
        } else if (e is AuthException) {
          showAuthError(context, e);
        } else if (e is ValidationException) {
          showValidationError(context, e);
        } else {
          showErrorSnackBar(context, errorMessage ?? e.message);
        }
      }

      rethrow;
    } catch (e, stackTrace) {
      _logger.e(errorMessage ?? 'Unexpected error', e, stackTrace);

      if (showError) {
        showErrorSnackBar(
          context,
          errorMessage ?? 'An unexpected error occurred',
        );
      }

      rethrow;
    }
  }

  /// Handles provider errors for riverpod
  void handleProviderError(
      Object error, StackTrace? stackTrace, ProviderBase provider) {
    _logger.e(
      'Error in provider: ${provider.name ?? provider.runtimeType}',
      error,
      stackTrace,
    );

    // TODO: Add error reporting service integration here
  }

  void handleError(AppException exception) {
    final errorMessage = _formatErrorMessage(exception);
    _logger.e(errorMessage, exception, exception.stackTrace);
  }

  String _formatErrorMessage(AppException exception) {
    return exception.message;
  }

  /// Handles a Dart error
  void handleDartError(Object error, StackTrace stackTrace) {
    final errorMessage = 'Dart error: ${error.toString()}';
    _logger.e(errorMessage, error, stackTrace);
  }

  /// Handles a Zone error
  void handleZoneError(Object error, StackTrace stackTrace) {
    try {
      _logger.e('Zone error: ${error.toString()}', error, stackTrace);
      // TODO: Send to crash reporting service
    } catch (e, stackTrace) {
      _logger.e('Error handling zone error', e, stackTrace);
    }
  }

  /// Creates a Riverpod error listener
  void Function(Object error, StackTrace stackTrace) createErrorListener(
      String providerName) {
    return (error, stackTrace) {
      _logger.e('Provider error in $providerName', error, stackTrace);
    };
  }

  /// Creates a Riverpod error widget builder
  Widget Function(BuildContext, Object, StackTrace) createErrorBuilder(
      String providerName) {
    return (context, error, stackTrace) {
      _logger.e('Widget error in $providerName', error, stackTrace);

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'An error occurred',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  try {
                    // 简化重试逻辑 - 由于我们不知道具体的Provider类型，使用通用的刷新方法
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                      transitionDuration: Duration.zero,
                    ));
                    Navigator.of(context).pop();
                  } catch (e) {
                    _logger.e('Error refreshing provider', e);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    };
  }
}

/// Extension on WidgetRef to provide error handling
extension ErrorHandlingWidgetRef on WidgetRef {
  /// Handles Riverpod async value states
  Widget whenAsyncValue<T>({
    required AsyncValue<T> value,
    required Widget Function(T data) data,
    Widget Function()? loading,
    Widget Function(Object error, StackTrace? stackTrace)? error,
    bool skipLoadingOnReload = true,
    bool skipLoadingOnRefresh = true,
    bool skipError = false,
  }) {
    return value.when(
      data: data,
      loading:
          loading ?? () => const Center(child: CircularProgressIndicator()),
      error: error ??
          (error, stackTrace) {
            // Log the error
            final errorHandler = read(errorHandlerProvider);
            errorHandler.handleError(
              AppException.unknown(
                message: 'Provider error: ${error.toString()}',
                cause: error,
              ),
            );

            // Default error widget
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Attempt to refresh the provider
                        try {
                          // 简化重试逻辑 - 由于我们不知道具体的Provider类型，使用通用的刷新方法
                          Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                            transitionDuration: Duration.zero,
                          ));
                          Navigator.of(context).pop();
                        } catch (e) {
                          errorHandler.handleError(
                            AppException.unknown(
                              message: 'Failed to refresh: ${e.toString()}',
                              cause: e,
                            ),
                          );
                        }
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}
