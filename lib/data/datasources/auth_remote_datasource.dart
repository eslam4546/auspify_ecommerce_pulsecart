import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';
import 'package:e_commerce_shopping_app/data/models/app_user_model.dart';

/// Contract for remote authentication backed by Firebase Auth, Google Sign-In,
/// and Cloud Firestore profile synchronization.
abstract class AuthRemoteDataSource {
  Future<AppUserModel?> getCurrentUser();

  Stream<AppUserModel?> authStateChanges();

  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUserModel> signInWithGoogle();

  Future<void> signOut();
}

/// Concrete implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required this._firebaseAuth,
    required this._googleSignIn,
    required this._firestore,
  });

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection(AppConstants.usersCollection).doc(uid);
  }

  @override
  Future<AppUserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final baseModel = AppUserModel.fromFirebaseUser(firebaseUser);
    try {
      final doc = await _userDoc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUserModel.fromFirestore(doc.data()!);
      }
      await _syncUserProfile(baseModel);
    } catch (_) {
      // Fall back to Firebase Auth profile when offline.
    }
    return baseModel;
  }

  @override
  Stream<AppUserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
      (user) => user == null ? null : AppUserModel.fromFirebaseUser(user),
    );
  }

  @override
  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          message: 'Sign-in succeeded, but no user account was returned.',
        );
      }

      final baseModel = AppUserModel.fromFirebaseUser(user);
      return await _syncUserProfile(baseModel);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e), code: e.code);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        message: 'Unable to sign in right now. Please try again.',
      );
    }
  }

  @override
  Future<AppUserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          message: 'Registration succeeded, but no user account was returned.',
        );
      }

      final trimmedName = name.trim();
      await user.updateDisplayName(trimmedName);
      await user.reload();

      final refreshedUser = _firebaseAuth.currentUser ?? user;
      final model = AppUserModel.fromFirebaseUser(
        refreshedUser,
        fallbackName: trimmedName,
      );

      return await _syncUserProfile(model, forceCreate: true);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e), code: e.code);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        message: 'Unable to create your account right now. Please try again.',
      );
    }
  }

  @override
  Future<AppUserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(
          message: 'Google sign-in was cancelled.',
          code: 'cancelled',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(
          message: 'Google sign-in did not return a Firebase user.',
        );
      }

      final model = AppUserModel.fromFirebaseUser(
        user,
        fallbackName: googleUser.displayName,
      );
      return await _syncUserProfile(model);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e), code: e.code);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        message: 'Google sign-in failed. Please verify your configuration and try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Ignore GoogleSignIn disconnect errors if user signed in via email.
    }
    try {
      await _firebaseAuth.signOut();
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseAuthError(e), code: e.code);
    }
  }

  /// Creates or merges the `users/{uid}` Firestore document while preserving
  /// `createdAt` immutability and existing `favoriteCategories`.
  Future<AppUserModel> _syncUserProfile(
    AppUserModel user, {
    bool forceCreate = false,
  }) async {
    try {
      final ref = _userDoc(user.uid);
      final snapshot = forceCreate ? null : await ref.get();
      final exists = snapshot?.exists ?? false;

      if (!exists) {
        await ref.set({
          ...user.toFirestoreMap(isNewUser: true),
          AppConstants.favoriteCategoriesField: <String, int>{},
        });
        return user;
      }

      final existingData = snapshot!.data() ?? const <String, dynamic>{};
      final existingName = (existingData['name'] ?? '').toString().trim();
      final resolvedUser = AppUserModel(
        uid: user.uid,
        name: existingName.isNotEmpty ? existingName : user.name,
        email: user.email,
        photoUrl: user.photoUrl ?? existingData['photoUrl'] as String?,
      );

      await ref.set(
        resolvedUser.toFirestoreMap(isNewUser: false),
        SetOptions(merge: true),
      );
      return resolvedUser;
    } catch (_) {
      // Do not block authentication if Firestore is temporarily unreachable.
      return user;
    }
  }

  String _mapFirebaseAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Console.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in provider.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
