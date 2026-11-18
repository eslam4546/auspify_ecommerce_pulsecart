import 'package:equatable/equatable.dart';
import 'package:e_commerce_shopping_app/domain/entities/app_user_entity.dart';

/// Base state for [AuthCubit].
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before checking Firebase authentication persistence.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Emitted while checking session, signing in, signing up, or signing out.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Emitted when a user is signed in with Firebase Auth.
class Authenticated extends AuthState {
  final AppUserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Emitted when no user session is active.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Emitted when an authentication operation fails.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
