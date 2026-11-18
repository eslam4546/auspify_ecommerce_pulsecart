import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures returned across Clean Architecture layers.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType: $message';
}

/// Represents a failure originating from remote REST API or cloud backend calls.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Represents a failure reading or writing to local Hive storage.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Represents a failure during Firebase Authentication or Google Sign-In.
class AuthFailure extends Failure {
  final String? code;

  const AuthFailure(super.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Represents a network connectivity or timeout failure.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

/// Represents a client-side validation failure (e.g., empty cart or invalid form input).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
