import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated PulseCart user.
class AppUserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  const AppUserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  AppUserEntity copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return AppUserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [uid, name, email, photoUrl];
}
