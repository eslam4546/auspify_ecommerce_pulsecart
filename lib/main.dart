import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/di/injection_container.dart';
import 'package:e_commerce_shopping_app/core/navigation/app_router.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/core/theme/app_theme.dart';
import 'package:e_commerce_shopping_app/firebase_options.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/theme/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final dependencies = await AppDependencies.init();

  runApp(PulseCartApp(dependencies: dependencies));
}

/// Root widget providing global Cubits and applying Stitch Light/Dark themes.
class PulseCartApp extends StatelessWidget {
  final AppDependencies dependencies;

  const PulseCartApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => dependencies.createThemeCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => dependencies.createAuthCubit()..checkAuthStatus(),
        ),
        BlocProvider<ProductCubit>(
          create: (_) => dependencies.createProductCubit(),
        ),
        BlocProvider<CartCubit>(create: (_) => dependencies.createCartCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Initial boot splash gate that checks persisted Firebase Auth status once
/// and hands off cleanly via [AppRouter] (`pushAndRemoveUntil`) to either
/// `MainShellPage` or `LoginPage`.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _hasRouted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleAuthState(context.read<AuthCubit>().state);
    });
  }

  void _handleAuthState(AuthState state) {
    if (_hasRouted || !mounted) return;

    if (state is Authenticated) {
      _hasRouted = true;
      AppRouter.navigateToHome(context, state.user.uid);
    } else if (state is Unauthenticated || state is AuthError) {
      _hasRouted = true;
      AppRouter.navigateToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (_, state) => _handleAuthState(state),
      child: const _PulseCartSplashView(),
    );
  }
}

class _PulseCartSplashView extends StatelessWidget {
  const _PulseCartSplashView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
