import 'package:e_commerce_shopping_app/domain/entities/app_user_entity.dart';

/// Contract for user authentication and session management.
///
/// Implementations throw [AuthFailure] or [ServerFailure] on error.
abstract class AuthRepository {
  /// Returns the currently authenticated user, or `null` if signed out.
  Future<AppUserEntity?> getCurrentUser();

  /// Stream notifying listeners of authentication state changes.
  Stream<AppUserEntity?> authStateChanges();

  /// Authenticates an existing user with email and password.
  Future<AppUserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new user with display name, email, and password,
  /// and initializes their Cloud Firestore profile document.
  Future<AppUserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Authenticates via Google OAuth and syncs the user profile to Firestore.
  Future<AppUserEntity> signInWithGoogle();

  /// Signs out from Firebase Auth and Google Sign-In.
  Future<void> signOut();
}
