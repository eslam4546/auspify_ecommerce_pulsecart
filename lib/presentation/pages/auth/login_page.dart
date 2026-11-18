import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/navigation/app_router.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/theme/theme_cubit.dart';

/// Stitch Screen 1 (Login mode) — PulseCart Authentication.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberSession = true;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEmailChanged() {
    final text = _emailController.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    if (valid != _isEmailValid) {
      setState(() => _isEmailValid = valid);
    }
  }

  void _submitSignIn() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _openRegisterPage() {
    Navigator.of(context).pushReplacement(AppRouter.registerRoute());
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
                    isSignInActive: true,
                    onSelectSignIn: () {},
                    onSelectSignUp: _openRegisterPage,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Credentials Form Card
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
                          const SizedBox(height: 4),
                          Text(
                            'Linked to verified Firebase User ID',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enter your registered email or use Google Sign-In.',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            enabled: !isLoading,
                            onFieldSubmitted: (_) => _submitSignIn(),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
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
                              if (value == null || value.isEmpty) {
                                return 'Password is required.';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(
                                  () => _rememberSession = !_rememberSession,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _rememberSession,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        onChanged: (val) => setState(
                                          () => _rememberSession = val ?? true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember session on device',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.security_rounded,
                                      size: 12,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SSL',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: AppColors.secondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          ElevatedButton(
                            onPressed: isLoading ? null : _submitSignIn,
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
                                      Text('Sign In to PulseCart'),
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

/// Top utility bar with Stitch "FIREBASE CLOUD SYNC" pill and Light/Dark theme toggle.
class AuthTopUtilityBar extends StatelessWidget {
  const AuthTopUtilityBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = context.watch<ThemeCubit>().isDarkMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'FIREBASE CLOUD SYNC',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: colorScheme.surfaceContainerHigh,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.read<ThemeCubit>().toggleTheme(),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 19,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Centered PulseCart squircle logo badge, bolt indicator, title, and tagline.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'PulseCart',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            'Shop smarter with instant cloud sync & personalized recommendations',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Stitch Material 3 segmented pill switcher for Sign In vs Create Account.
class AuthModeSwitcher extends StatelessWidget {
  final bool isSignInActive;
  final VoidCallback onSelectSignIn;
  final VoidCallback onSelectSignUp;

  const AuthModeSwitcher({
    super.key,
    required this.isSignInActive,
    required this.onSelectSignIn,
    required this.onSelectSignUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              icon: Icons.login_rounded,
              label: 'Sign In',
              isActive: isSignInActive,
              onTap: onSelectSignIn,
              theme: theme,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              icon: Icons.person_add_rounded,
              label: 'Create Account',
              isActive: !isSignInActive,
              onTap: onSelectSignUp,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hairline divider with "OR CONTINUE WITH" label.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Google OAuth button styled per Stitch with 4-color Google emblem.
class GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(painter: _GoogleLogoPainter()),
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    final stroke = size.width * 0.19;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Draw the 4 Google "G" arcs
    canvas.drawArc(rect, -2.55, 1.85, false, redPaint);
    canvas.drawArc(rect, 2.35, 1.38, false, yellowPaint);
    canvas.drawArc(rect, 0.72, 1.65, false, greenPaint);
    canvas.drawArc(rect, -0.05, 0.85, false, bluePaint);

    // Draw the blue horizontal crossbar of the "G"
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius + stroke * 0.48, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Trust & security micro-footer matching Stitch Screen 1.
class AuthTrustFooter extends StatelessWidget {
  const AuthTrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_rounded,
              size: 15,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Protected by Firebase Authentication & 256-bit encryption',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
