import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_frame/core/error/app_logger.dart';

import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../error/error_handler.dart';
import 'connectivity_service.dart';

/// A client for making API requests
class ApiClient {
  final Dio _dio;
  final AppConfig _config;
  final AppLogger _logger;
  final ErrorHandler _errorHandler;
  final ConnectivityService _connectivityService;

  /// Creates a new [ApiClient]
  ApiClient({
    AppConfig? config,
    required AppLogger logger,
    required ErrorHandler errorHandler,
    required ConnectivityService connectivityService,
  })  : _config = config ?? AppConfig.development(),
        _logger = logger,
        _errorHandler = errorHandler,
        _connectivityService = connectivityService,
        _dio = Dio() {
    _configureDio();
  }

  /// Configures the Dio instance
  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: _config.apiBaseUrl,
      connectTimeout: Duration(seconds: _config.networkTimeoutSeconds),
      receiveTimeout: Duration(seconds: _config.networkTimeoutSeconds),
      sendTimeout: Duration(seconds: _config.networkTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (_config.apiKey != null) {
      _dio.options.headers['Authorization'] = 'Bearer ${_config.apiKey}';
    }

    // Add logging interceptor in debug mode
    if (_config.isDetailedLoggingEnabled) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) {
            _logger.d('[HTTP] $object');
          },
        ),
      );
    }

    // Add retry interceptor
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logger: _logger,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ],
    ));

    // Add connectivity check interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (!_connectivityService.isConnected) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: 'No internet connection',
              type: DioExceptionType.connectionError,
            ),
          );
        }
        return handler.next(options);
      },
    ));
  }

  /// Updates the authorization token
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _logger.d('Updated authorization token');
  }

  /// Performs a GET request
  Future<T> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ResponseType? responseType,
    required T Function(Map<String, dynamic> response) converter,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers, responseType: responseType),
        cancelToken: cancelToken,
      );

      return _handleResponse(response, converter);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      throw _handleGenericError(e, stackTrace);
    }
  }

  /// Performs a POST request
  Future<T> post<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ResponseType? responseType,
    required T Function(Map<String, dynamic> response) converter,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers, responseType: responseType),
        cancelToken: cancelToken,
      );

      return _handleResponse(response, converter);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      throw _handleGenericError(e, stackTrace);
    }
  }

  /// Performs a POST request and returns the raw response as Map
  Future<Map<String, dynamic>> postRaw(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ResponseType? responseType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: headers, responseType: responseType),
        cancelToken: cancelToken,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      return response.data ?? {};
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      throw _handleGenericError(e, stackTrace);
    }
  }

  /// Performs a PUT request
  Future<T> put<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ResponseType? responseType,
    required T Function(Map<String, dynamic> response) converter,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers, responseType: responseType),
        cancelToken: cancelToken,
      );

      return _handleResponse(response, converter);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      throw _handleGenericError(e, stackTrace);
    }
  }

  /// Performs a DELETE request
  Future<T> delete<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ResponseType? responseType,
    required T Function(Map<String, dynamic> response) converter,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers, responseType: responseType),
        cancelToken: cancelToken,
      );

      return _handleResponse(response, converter);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      throw _handleGenericError(e, stackTrace);
    }
  }

  /// Handles the response
  T _handleResponse<T>(
    Response<Map<String, dynamic>>? response,
    T Function(Map<String, dynamic> response) converter,
  ) {
    if (response == null) {
      throw AppException.server(message: 'Null response');
    }

    if (response.data == null) {
      throw AppException.server(message: 'Null response data');
    }

    try {
      return converter(response.data!);
    } catch (e, stackTrace) {
      _logger.e('Error converting response data', e, stackTrace);
      throw AppException.parsing(message: 'Error parsing response data: $e');
    }
  }

  /// Handles Dio errors
  AppException _handleDioException(DioException exception) {
    _logger.e('DioError', exception, exception.stackTrace);
    
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException.network(
          message: 'Network timeout',
          cause: exception,
          statusCode: 0,
          stackTrace: exception.stackTrace,
        );
      case DioExceptionType.badResponse:
        final response = exception.response;
        if (response == null) {
          return AppException.network(
            message: 'Bad response with no details',
            cause: exception,
            stackTrace: exception.stackTrace,
          );
        }
        
        final statusCode = response.statusCode ?? 0;
        
        // Handle specific status codes
        switch (statusCode) {
          case 401:
            return AppException.unauthorized(
              message: 'Unauthorized',
              cause: exception,
              statusCode: statusCode,
              stackTrace: exception.stackTrace,
            );
          case 403:
            return AppException.forbidden(
              message: 'Forbidden',
              cause: exception,
              statusCode: statusCode,
              stackTrace: exception.stackTrace,
            );
          case 404:
            return AppException.notFound(
              message: 'Resource not found',
              cause: exception,
              statusCode: statusCode,
              stackTrace: exception.stackTrace,
            );
          case 500:
          case 501:
          case 502:
          case 503:
            return AppException.server(
              message: 'Server error',
              cause: exception,
              statusCode: statusCode,
              stackTrace: exception.stackTrace,
            );
          default:
            return AppException.network(
              message: 'API error',
              cause: exception,
              statusCode: statusCode,
              stackTrace: exception.stackTrace,
            );
        }
      case DioExceptionType.cancel:
        return AppException.cancelled(
          message: 'Request cancelled',
          cause: exception,
          stackTrace: exception.stackTrace,
        );
      case DioExceptionType.unknown:
      default:
        if (exception.error is SocketException) {
          return AppException.network(
            message: 'No internet connection',
            cause: exception,
            stackTrace: exception.stackTrace,
          );
        }
        return AppException.unexpected(
          message: 'Unexpected error',
          cause: exception,
          stackTrace: exception.stackTrace,
        );
    }
  }

  /// Handles generic errors
  AppException _handleGenericError(Object error, StackTrace stackTrace) {
    void handleError(Object error, StackTrace stackTrace) {
      if (error is DioException) {
        final exception = _handleDioException(error);
        _logger.e('DioError', exception, exception.stackTrace);
        throw exception;
      }
      // For any other errors
      _logger.e('Generic error', error, stackTrace);
      throw AppException.network(
        message: 'API error: ${error.toString()}',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    handleError(error, stackTrace);
    _errorHandler.recordNonFatalError(error, stackTrace);
    return AppException.unexpected(message: error.toString());
  }
}

/// A retry interceptor for Dio
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final AppLogger logger;
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    required this.logger,
    this.retries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
  })  : assert(retries > 0),
        assert(retryDelays.length >= retries);

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final shouldRetry = _shouldRetry(err);

    // Get the retry count from extra or initialize it
    final retryCount = (requestOptions.extra['retryCount'] as int?) ?? 0;

    if (shouldRetry && retryCount < retries) {
      // Increment the retry count
      requestOptions.extra['retryCount'] = retryCount + 1;

      // Log the retry attempt
      logger.d(
          'Retrying request (${retryCount + 1}/$retries): ${requestOptions.path}');

      // Delay before retrying
      await Future.delayed(retryDelays[retryCount]);

      try {
        // Create a new request with the same options
        final response = await dio.fetch(requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // If retrying also fails, continue with the error handling
        if (e is DioException) {
          return handler.next(e);
        }
        return handler
            .next(DioException(requestOptions: requestOptions, error: e));
      }
    }

    // If we shouldn't retry or have exhausted retries, continue with error handling
    return handler.next(err);
  }

  /// Determines if a request should be retried
  bool _shouldRetry(DioException err) {
    // Only retry for these error types
    final retryableErrorTypes = [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ];

    // Only retry for GET requests or idempotent requests
    final isIdempotent = err.requestOptions.method == 'GET' ||
        err.requestOptions.extra['idempotent'] == true;

    return retryableErrorTypes.contains(err.type) && isIdempotent;
  }
}
