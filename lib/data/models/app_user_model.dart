import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:e_commerce_shopping_app/domain/entities/app_user_entity.dart';

/// Data model bridging Firebase Auth / Cloud Firestore user documents with [AppUserEntity].
class AppUserModel extends AppUserEntity {
  const AppUserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.photoUrl,
  });

  factory AppUserModel.fromEntity(AppUserEntity entity) {
    return AppUserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      photoUrl: entity.photoUrl,
    );
  }

  /// Creates an [AppUserModel] from a Firebase Auth [fb_auth.User].
  factory AppUserModel.fromFirebaseUser(
    fb_auth.User user, {
    String? fallbackName,
  }) {
    final resolvedEmail = (user.email ?? '').trim();
    final rawName = (user.displayName ?? fallbackName ?? '').trim();
    final resolvedName = rawName.isNotEmpty
        ? rawName
        : (resolvedEmail.contains('@')
              ? resolvedEmail.split('@').first
              : 'PulseCart Shopper');

    return AppUserModel(
      uid: user.uid,
      name: resolvedName,
      email: resolvedEmail,
      photoUrl: user.photoURL,
    );
  }

  /// Creates an [AppUserModel] from a Firestore `users/{uid}` document map.
  factory AppUserModel.fromFirestore(Map<String, dynamic> map) {
    return AppUserModel(
      uid: (map['uid'] ?? '').toString(),
      name: (map['name'] ?? 'PulseCart Shopper').toString(),
      email: (map['email'] ?? '').toString(),
      photoUrl: map['photoUrl'] as String?,
    );
  }

  /// Converts to Firestore map strictly conforming to `firestore.rules` allowlist.
  Map<String, dynamic> toFirestoreMap({bool isNewUser = false}) {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      if (isNewUser) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'name': name, 'email': email, 'photoUrl': photoUrl};
  }

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
