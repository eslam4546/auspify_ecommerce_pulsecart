import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_shopping_app/core/navigation/app_router.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/app_user_entity.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/widgets/order_history_card.dart';

final NumberFormat _profileCurrency = NumberFormat.simpleCurrency(
  name: 'USD',
  decimalDigits: 0,
);

/// Stitch Screen 6 — PulseCart User Profile, Order History & Theme Preferences.
class ProfilePage extends StatelessWidget {
  final VoidCallback onOpenCartTab;

  const ProfilePage({super.key, required this.onOpenCartTab});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out of your PulseCart account? Your cloud cart and orders remain safely synced in Firestore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                minimumSize: const Size(110, 42),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<CartCubit>().resetOnSignOut();
    if (!context.mounted) return;
    await context.read<AuthCubit>().signOut();
  }

  Future<void> _reorderItems(BuildContext context, OrderEntity order) async {
    final uid = context.read<AuthCubit>().currentUser?.uid;
    final cartCubit = context.read<CartCubit>();
    for (final item in order.items) {
      await cartCubit.addToCart(
        item.product,
        quantity: item.quantity,
        uid: uid,
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Added ${order.totalItemCount} item${order.totalItemCount == 1 ? '' : 's'} back to your cart',
          ),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: AppColors.secondaryContainer,
            onPressed: onOpenCartTab,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = context.watch<ThemeCubit>().isDarkMode;
    final authState = context.watch<AuthCubit>().state;
    final AppUserEntity? user = authState is Authenticated
        ? authState.user
        : null;
    final isSigningOut = authState is AuthLoading;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          AppRouter.navigateToLogin(context);
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
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: AppSpacing.md,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PULSECART',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Profile',
                style: theme.textTheme.titleLarge?.copyWith(height: 1.1),
              ),
            ],
          ),
        ),
        body: BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            final orders = cartState is CartLoaded
                ? cartState.orders
                : const <OrderEntity>[];
            final cartCount = cartState is CartLoaded
                ? cartState.totalItemCount
                : 0;
            final totalSpent = orders.fold<double>(
              0.0,
              (sum, order) => sum + order.totalAmount,
            );

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  context.read<CartCubit>().loadOrderHistory(uid: user?.uid),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  116,
                ),
                children: [
                  // Identity Card with Gradient Ring Avatar & Quick Stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSubtleBorder
                            : AppColors.lightSubtleBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Gradient-ring Avatar
                        Container(
                          width: 92,
                          height: 92,
                          padding: const EdgeInsets.all(3.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryDeep,
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: colorScheme.surfaceContainer,
                            backgroundImage:
                                (user?.photoUrl != null &&
                                    user!.photoUrl!.isNotEmpty)
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child:
                                (user?.photoUrl == null ||
                                    user!.photoUrl!.isEmpty)
                                ? Text(
                                    (user?.name.trim().isNotEmpty ?? false)
                                        ? user!.name.trim()[0].toUpperCase()
                                        : 'P',
                                    style: theme.textTheme.headlineLarge
                                        ?.copyWith(color: colorScheme.primary),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                user?.name ?? 'PulseCart Shopper',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineMedium,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.verified_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            if (user?.email.isNotEmpty ?? false)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.mail_outline_rounded,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      user!.email,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    size: 13,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Firebase Auth Verified',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Quick Stats Metric Bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ProfileMetric(
                                  value: '${orders.length}',
                                  label: 'ORDERS PLACED',
                                  valueColor: colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: _ProfileMetric(
                                  value: _profileCurrency.format(totalSpent),
                                  label: 'TOTAL SPENT',
                                  valueColor: AppColors.secondary,
                                ),
                              ),
                              Expanded(
                                child: _ProfileMetric(
                                  value: '$cartCount',
                                  label: 'IN CART',
                                  valueColor: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // My Orders Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'My Orders',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Firestore Synced',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkSubtleBorder
                              : AppColors.lightSubtleBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 36,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No orders placed yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed checkouts will appear here and stay synced across devices.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  else
                    for (final order in orders) ...[
                      OrderHistoryCard(
                        order: order,
                        onReorder: () => _reorderItems(context, order),
                      ),
                      const SizedBox(height: 10),
                    ],

                  const SizedBox(height: AppSpacing.md),

                  // Settings & Preferences Card
                  Text(
                    'Settings & Preferences',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSubtleBorder
                            : AppColors.lightSubtleBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Dark Mode',
                            style: theme.textTheme.labelLarge,
                          ),
                          subtitle: Text(
                            'Persisted locally in Hive settings',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Switch(
                            value: isDark,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.primary,
                            onChanged: (_) =>
                                context.read<ThemeCubit>().toggleTheme(),
                          ),
                        ),
                        const Divider(indent: 68, endIndent: 16),
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer.withValues(
                                alpha: 0.6,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_sync_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Hybrid Cloud Persistence',
                            style: theme.textTheme.labelLarge,
                          ),
                          subtitle: Text(
                            'Hive NoSQL offline + Cloud Firestore sync',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Sign Out Button
                  ElevatedButton.icon(
                    onPressed: isSigningOut
                        ? null
                        : () => _confirmSignOut(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      elevation: 0,
                    ),
                    icon: isSigningOut
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onErrorContainer,
                            ),
                          )
                        : const Icon(Icons.logout_rounded, size: 20),
                    label: Text(
                      isSigningOut
                          ? 'Signing Out...'
                          : 'Sign Out of Firebase Account',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PulseCart • Auspify Technologies Capstone',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _ProfileMetric({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
