import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/domain/entities/app_user_entity.dart';
import 'package:e_commerce_shopping_app/domain/repositories/auth_repository.dart';

/// Checks whether a Firebase user session is currently active.
class CheckAuthStatusUseCase {
  final AuthRepository _repository;

  const CheckAuthStatusUseCase(this._repository);

  Future<AppUserEntity?> call() => _repository.getCurrentUser();
}

/// Exposes a stream of authenticated user changes.
class AuthStateChangesUseCase {
  final AuthRepository _repository;

  const AuthStateChangesUseCase(this._repository);

  Stream<AppUserEntity?> call() => _repository.authStateChanges();
}

/// Signs in an existing user using email and password.
class SignInWithEmailUseCase {
  final AuthRepository _repository;

  const SignInWithEmailUseCase(this._repository);

  Future<AppUserEntity> call({
    required String email,
    required String password,
  }) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw const ValidationFailure('Please enter your email address.');
    }
    if (password.isEmpty) {
      throw const ValidationFailure('Please enter your password.');
    }
    return _repository.signInWithEmail(email: trimmedEmail, password: password);
  }
}

/// Registers a new user account with display name, email, and password.
class SignUpWithEmailUseCase {
  final AuthRepository _repository;

  const SignUpWithEmailUseCase(this._repository);

  Future<AppUserEntity> call({
    required String name,
    required String email,
    required String password,
  }) {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    if (trimmedName.length < 2) {
      throw const ValidationFailure(
        'Please enter your full name (at least 2 characters).',
      );
    }
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw const ValidationFailure('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw const ValidationFailure(
        'Password must be at least 6 characters long.',
      );
    }
    return _repository.signUpWithEmail(
      name: trimmedName,
      email: trimmedEmail,
      password: password,
    );
  }
}

/// Signs in using One-Tap Google OAuth.
class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  const SignInWithGoogleUseCase(this._repository);

  Future<AppUserEntity> call() => _repository.signInWithGoogle();
}

/// Signs the current user out from Firebase and Google Sign-In.
class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  Future<void> call() => _repository.signOut();
}
