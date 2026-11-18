/// Thrown when a remote REST API or Cloud Firestore request fails.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, message: $message)';
}

/// Thrown when a local Hive persistence operation fails or cached data is missing.
class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException(message: $message)';
}

/// Thrown when Firebase Authentication or Google Sign-In encounters an error.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({required this.message, this.code});

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

/// Thrown when the device is offline or a network timeout occurs.
class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'Network error. Please check your internet connection.',
  });

  @override
  String toString() => 'NetworkException(message: $message)';
}
