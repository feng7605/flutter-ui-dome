/// Base class for all application exceptions
abstract class AppException implements Exception {
  /// A message describing the error
  final String message;

  /// The error code
  final String code;

  /// The original exception that caused this exception
  final dynamic cause;

  /// The stack trace associated with this exception
  final StackTrace? stackTrace;

  /// Creates a new [AppException]
  const AppException({
    required this.message,
    required this.code,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    String result = 'AppException: $code - $message';
    if (cause != null) {
      result += '\nCause: $cause';
    }
    return result;
  }

  /// Creates a network-related exception
  factory AppException.network({
    String message = 'A network error occurred',
    dynamic cause,
    int? statusCode,
    StackTrace? stackTrace,
  }) =>
      NetworkException(
        message: message,
        code: 'NETWORK_ERROR',
        cause: cause,
        statusCode: statusCode,
        stackTrace: stackTrace,
      );

  /// Creates a server-related exception
  factory AppException.server({
    String message = 'A server error occurred',
    dynamic cause,
    StackTrace? stackTrace,
    int? statusCode,
    String code = 'SERVER_ERROR',
  }) {
    return NetworkException(
      message: message,
      code: code,
      cause: cause,
      statusCode: statusCode,
      stackTrace: stackTrace,
    );
  }

  /// Creates a localization-related exception
  factory AppException.localization({
    String message = 'A localization error occurred',
    dynamic cause,
    StackTrace? stackTrace,
    String code = 'LOCALIZATION_ERROR',
  }) {
    return UnexpectedException(
      message: message,
      code: code,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Creates an unknown error exception
  factory AppException.unknown({
    String message = 'An unknown error occurred',
    dynamic cause,
  }) =>
      UnexpectedException(
        message: message,
        code: 'UNKNOWN_ERROR',
        cause: cause,
      );

  /// Creates a bad request exception
  factory AppException.badRequest({
    String message = 'Bad request',
    dynamic cause,
  }) =>
      NetworkException(
        message: message,
        code: 'BAD_REQUEST',
        statusCode: 400,
        cause: cause,
      );

  /// Creates an unauthorized exception
  factory AppException.unauthorized({
    String message = 'Unauthorized',
    dynamic cause,
    int? statusCode,
    StackTrace? stackTrace,
  }) =>
      AuthException(
        message: message,
        code: 'UNAUTHORIZED',
        cause: cause,
        statusCode: statusCode,
        stackTrace: stackTrace,
      );

  /// Creates a forbidden exception
  factory AppException.forbidden({
    String message = 'Forbidden',
    dynamic cause,
    int? statusCode,
    StackTrace? stackTrace,
  }) =>
      AuthException(
        message: message,
        code: 'FORBIDDEN',
        cause: cause,
        statusCode: statusCode,
        stackTrace: stackTrace,
      );

  /// Creates a not found exception
  factory AppException.notFound({
    String message = 'Resource not found',
    dynamic cause,
    int? statusCode,
    StackTrace? stackTrace,
  }) =>
      NetworkException(
        message: message,
        code: 'NOT_FOUND',
        statusCode: statusCode ?? 404,
        cause: cause,
        stackTrace: stackTrace,
      );

  /// Creates a validation exception
  factory AppException.validation({
    String message = 'Validation failed',
    Map<String, List<String>>? fieldErrors,
    dynamic cause,
  }) =>
      ValidationException(
        message: message,
        code: 'VALIDATION_ERROR',
        fieldErrors: fieldErrors,
        cause: cause,
      );

  /// Creates a parsing exception
  factory AppException.parsing({
    String message = 'Failed to parse data',
    dynamic cause,
  }) =>
      UnexpectedException(
        message: message,
        code: 'PARSING_ERROR',
        cause: cause,
      );

  /// Creates a permission exception
  factory AppException.permission({
    String message = 'Permission denied',
    String? permissionName,
    dynamic cause,
  }) =>
      PermissionException(
        message: message,
        code: 'PERMISSION_DENIED',
        permissionName: permissionName,
        cause: cause,
      );

  /// Creates a cache exception
  factory AppException.cache({
    String message = 'Cache error',
    dynamic cause,
    StackTrace? stackTrace,
  }) =>
      CacheException(
        message: message,
        code: 'CACHE_ERROR',
        cause: cause,
        stackTrace: stackTrace,
      );

  /// Creates an initialization exception
  factory AppException.initialization({
    String message = 'Initialization error',
    dynamic cause,
    StackTrace? stackTrace,
  }) =>
      UnexpectedException(
        message: message,
        code: 'INITIALIZATION_ERROR',
        cause: cause,
        stackTrace: stackTrace,
      );

  /// Creates a request cancellation exception
  factory AppException.cancelled({
    String message = 'Request cancelled',
    dynamic cause,
    StackTrace? stackTrace,
  }) =>
      NetworkException(
        message: message,
        code: 'REQUEST_CANCELLED',
        cause: cause,
        stackTrace: stackTrace,
      );

  /// Creates an unexpected exception
  factory AppException.unexpected({
    String message = 'An unexpected error occurred',
    dynamic cause,
    StackTrace? stackTrace,
  }) =>
      UnexpectedException(
        message: message,
        code: 'UNEXPECTED_ERROR',
        cause: cause,
        stackTrace: stackTrace,
      );
}

/// Exception thrown when a network error occurs
class NetworkException extends AppException {
  /// The HTTP status code
  final int? statusCode;

  /// Creates a new [NetworkException]
  const NetworkException({
    required super.message,
    required super.code,
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    String result = 'NetworkException: $code - $message';
    if (statusCode != null) {
      result += ' (Status Code: $statusCode)';
    }
    if (cause != null) {
      result += '\nCause: $cause';
    }
    return result;
  }
}

/// Exception thrown when a validation error occurs
class ValidationException extends AppException {
  /// The field errors
  final Map<String, List<String>>? fieldErrors;

  /// Creates a new [ValidationException]
  const ValidationException({
    required super.message,
    required super.code,
    this.fieldErrors,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    String result = 'ValidationException: $code - $message';
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      result += '\nField Errors: $fieldErrors';
    }
    if (cause != null) {
      result += '\nCause: $cause';
    }
    return result;
  }
}

/// Exception thrown when an authentication error occurs
class AuthException extends AppException {
  /// The HTTP status code
  final int? statusCode;

  /// Creates a new [AuthException]
  const AuthException({
    required super.message,
    required super.code,
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    String result = 'AuthException: $code - $message';
    if (statusCode != null) {
      result += ' (Status Code: $statusCode)';
    }
    if (cause != null) {
      result += '\nCause: $cause';
    }
    return result;
  }
}

/// Exception thrown when a permission error occurs
class PermissionException extends AppException {
  /// The name of the permission that was denied
  final String? permissionName;

  /// Creates a new [PermissionException]
  const PermissionException({
    required super.message,
    required super.code,
    this.permissionName,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    String result = 'PermissionException: $code - $message';
    if (permissionName != null) {
      result += ' (Permission: $permissionName)';
    }
    if (cause != null) {
      result += '\nCause: $cause';
    }
    return result;
  }
}

/// Exception thrown when a cache error occurs
class CacheException extends AppException {
  /// Creates a new [CacheException]
  const CacheException({
    required super.message,
    required super.code,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    String result = 'CacheException: $code - $message';
    if (cause != null) {
      result += '\nCause: $cause';
    }
    return result;
  }
}

/// Exception thrown when an unexpected error occurs
class UnexpectedException extends AppException {
  /// Creates a new [UnexpectedException]
  const UnexpectedException({
    required super.message,
    required super.code,
    super.cause,
    super.stackTrace,
  });
}
