import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/data/datasources/auth_remote_datasource.dart';
import 'package:e_commerce_shopping_app/domain/entities/app_user_entity.dart';
import 'package:e_commerce_shopping_app/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] delegating to [AuthRemoteDataSource].
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl({required this._remoteDataSource});

  @override
  Future<AppUserEntity?> getCurrentUser() async {
    try {
      return await _remoteDataSource.getCurrentUser();
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure('Unable to restore user session: $e');
    }
  }

  @override
  Stream<AppUserEntity?> authStateChanges() {
    return _remoteDataSource.authStateChanges();
  }

  @override
  Future<AppUserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure('Sign-in failed: $e');
    }
  }

  @override
  Future<AppUserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure('Account creation failed: $e');
    }
  }

  @override
  Future<AppUserEntity> signInWithGoogle() async {
    try {
      return await _remoteDataSource.signInWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure('Sign-out failed: $e');
    }
  }
}
