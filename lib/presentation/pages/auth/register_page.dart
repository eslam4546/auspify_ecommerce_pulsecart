import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/navigation/app_router.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_state.dart';
import 'package:e_commerce_shopping_app/presentation/pages/auth/login_page.dart';

/// Stitch Screen 1 (Create Account mode) — PulseCart Registration.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleEmailChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleEmailChanged() {
    final text = _emailController.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    if (valid != _isEmailValid) {
      setState(() => _isEmailValid = valid);
    }
  }

  void _submitSignUp() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signUpWithEmail(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _openLoginPage() {
    Navigator.of(context).pushReplacement(AppRouter.loginRoute());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              AppRouter.navigateToHome(context, state.user.uid);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: colorScheme.error,
                  ),
                );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthTopUtilityBar(),
                  const SizedBox(height: AppSpacing.sm),
                  const AuthBrandHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  AuthModeSwitcher(
                    isSignInActive: false,
                    onSelectSignIn: _openLoginPage,
                    onSelectSignUp: () {},
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Registration Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.2
                                : 0.04,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Name',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              hintText: 'Alex Rivera',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                              ),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.length < 2) {
                                return 'Please enter your full name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Text(
                            'Email Address',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              hintText: 'alex.rivera@example.com',
                              prefixIcon: const Icon(
                                Icons.alternate_email_rounded,
                                size: 20,
                              ),
                              suffixIcon: _isEmailValid
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.secondary,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'Email address is required.';
                              }
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(trimmed)) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Text(
                            'Password',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              hintText: 'At least 6 characters',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Text(
                            'Confirm Password',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            enabled: !isLoading,
                            onFieldSubmitted: (_) => _submitSignUp(),
                            decoration: InputDecoration(
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(
                                Icons.lock_reset_rounded,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: isLoading ? null : _submitSignUp,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Create PulseCart Account'),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const AuthOrDivider(),
                  const SizedBox(height: AppSpacing.md),

                  GoogleSignInButton(
                    isLoading: isLoading,
                    onPressed: () =>
                        context.read<AuthCubit>().signInWithGoogle(),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const AuthTrustFooter(),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
