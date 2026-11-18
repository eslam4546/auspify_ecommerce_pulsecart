import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/domain/entities/app_user_entity.dart';
import 'package:e_commerce_shopping_app/domain/usecases/auth_usecases.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_state.dart';

class _MockCheckAuthStatusUseCase extends Mock
    implements CheckAuthStatusUseCase {}

class _MockSignInWithEmailUseCase extends Mock
    implements SignInWithEmailUseCase {}

class _MockSignUpWithEmailUseCase extends Mock
    implements SignUpWithEmailUseCase {}

class _MockSignInWithGoogleUseCase extends Mock
    implements SignInWithGoogleUseCase {}

class _MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  late _MockCheckAuthStatusUseCase checkAuthStatus;
  late _MockSignInWithEmailUseCase signInWithEmail;
  late _MockSignUpWithEmailUseCase signUpWithEmail;
  late _MockSignInWithGoogleUseCase signInWithGoogle;
  late _MockSignOutUseCase signOut;

  const testUser = AppUserEntity(
    uid: 'uid-123',
    name: 'Alex Rivera',
    email: 'alex@pulsecart.io',
  );

  setUp(() {
    checkAuthStatus = _MockCheckAuthStatusUseCase();
    signInWithEmail = _MockSignInWithEmailUseCase();
    signUpWithEmail = _MockSignUpWithEmailUseCase();
    signInWithGoogle = _MockSignInWithGoogleUseCase();
    signOut = _MockSignOutUseCase();
  });

  AuthCubit buildCubit() => AuthCubit(
    checkAuthStatus: checkAuthStatus,
    signInWithEmail: signInWithEmail,
    signUpWithEmail: signUpWithEmail,
    signInWithGoogle: signInWithGoogle,
    signOut: signOut,
  );

  group('AuthCubit', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, Authenticated] when checkAuthStatus finds an active user',
      build: () {
        when(() => checkAuthStatus()).thenAnswer((_) async => testUser);
        return buildCubit();
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => const [AuthLoading(), Authenticated(testUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, Unauthenticated] when checkAuthStatus returns null',
      build: () {
        when(() => checkAuthStatus()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => const [AuthLoading(), Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, Authenticated] on successful email sign-in',
      build: () {
        when(
          () => signInWithEmail(
            email: 'alex@pulsecart.io',
            password: 'password123',
          ),
        ).thenAnswer((_) async => testUser);
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithEmail(
        email: 'alex@pulsecart.io',
        password: 'password123',
      ),
      expect: () => const [AuthLoading(), Authenticated(testUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when email sign-in throws AuthFailure',
      build: () {
        when(
          () => signInWithEmail(email: 'alex@pulsecart.io', password: 'wrong'),
        ).thenThrow(const AuthFailure('Incorrect email or password.'));
        return buildCubit();
      },
      act: (cubit) =>
          cubit.signInWithEmail(email: 'alex@pulsecart.io', password: 'wrong'),
      expect: () => const [
        AuthLoading(),
        AuthError('Incorrect email or password.'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, Unauthenticated] gracefully when Google Sign-In is cancelled',
      build: () {
        when(() => signInWithGoogle()).thenThrow(
          const AuthFailure('Google sign-in was cancelled.', code: 'cancelled'),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => const [AuthLoading(), Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, Unauthenticated] on signOut',
      build: () {
        when(() => signOut()).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.signOut(),
      expect: () => const [AuthLoading(), Unauthenticated()],
    );
  });
}
