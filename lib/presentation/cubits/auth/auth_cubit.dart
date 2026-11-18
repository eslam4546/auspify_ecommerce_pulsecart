import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/domain/entities/app_user_entity.dart';
import 'package:e_commerce_shopping_app/domain/usecases/auth_usecases.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_state.dart';

/// Cubit managing Firebase Email/Password authentication, Google OAuth, and user session state.
class AuthCubit extends Cubit<AuthState> {
  final CheckAuthStatusUseCase _checkAuthStatus;
  final SignInWithEmailUseCase _signInWithEmail;
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;

  AuthCubit({
    required this._checkAuthStatus,
    required this._signInWithEmail,
    required this._signUpWithEmail,
    required this._signInWithGoogle,
    required this._signOut,
  }) : super(const AuthInitial());

  /// Convenience getter for the currently authenticated user, if any.
  AppUserEntity? get currentUser {
    final current = state;
    if (current is Authenticated) return current.user;
    return null;
  }

  /// Restores any persisted Firebase Auth session on app launch.
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    try {
      final user = await _checkAuthStatus();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  /// Signs in with Email & Password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _signInWithEmail(email: email, password: password);
      emit(Authenticated(user));
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    } catch (_) {
      emit(const AuthError('Unexpected error during sign-in.'));
    }
  }

  /// Creates a new account with Full Name, Email & Password.
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
      emit(Authenticated(user));
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    } catch (_) {
      emit(const AuthError('Unexpected error during account creation.'));
    }
  }

  /// Authenticates via One-Tap Google Sign-In.
  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final user = await _signInWithGoogle();
      emit(Authenticated(user));
    } on AuthFailure catch (failure) {
      if (failure.code == 'cancelled') {
        emit(const Unauthenticated());
      } else {
        emit(AuthError(failure.message));
      }
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    } catch (_) {
      emit(const AuthError('Unexpected error during Google sign-in.'));
    }
  }

  /// Signs out from Firebase Auth and Google Sign-In.
  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _signOut();
      emit(const Unauthenticated());
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    } catch (_) {
      emit(const AuthError('Failed to sign out. Please try again.'));
    }
  }
}
