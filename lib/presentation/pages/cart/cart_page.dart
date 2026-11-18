import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';
import 'package:e_commerce_shopping_app/presentation/pages/cart/checkout_bottom_sheet.dart';
import 'package:e_commerce_shopping_app/presentation/widgets/cart_item_card.dart';

final NumberFormat _summaryCurrency = NumberFormat.simpleCurrency(
  name: 'USD',
  decimalDigits: 2,
);

/// Stitch Screen 5 — PulseCart Shopping Cart & Checkout Entry.
class CartPage extends StatelessWidget {
  final VoidCallback onExploreShop;
  final ValueChanged<ProductEntity> onProductTap;

  const CartPage({
    super.key,
    required this.onExploreShop,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
              'Cart',
              style: theme.textTheme.titleLarge?.copyWith(height: 1.1),
            ),
          ],
        ),
      ),
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state is CartLoaded && state.actionError != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.actionError!),
                  backgroundColor: colorScheme.error,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is CartLoading || state is CartInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is CartError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: () {
                          final uid = context
                              .read<AuthCubit>()
                              .currentUser
                              ?.uid;
                          context.read<CartCubit>().loadCart(uid: uid);
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final loaded = state as CartLoaded;

          if (loaded.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_mall_outlined,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your shopping bag is empty',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add products to your cart — they persist offline with Hive and sync automatically to Cloud Firestore.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 210,
                      child: ElevatedButton.icon(
                        onPressed: onExploreShop,
                        icon: const Icon(Icons.storefront_rounded, size: 19),
                        label: const Text('Explore Catalog'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final shippingProgress =
              (loaded.subtotal / AppConstants.freeShippingThreshold).clamp(
                0.0,
                1.0,
              );
          final freeShippingUnlocked = loaded.shippingFee == 0.0;
          final uid = context.read<AuthCubit>().currentUser?.uid;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<CartCubit>().loadCart(uid: uid),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                116,
              ),
              children: [
                // Header & Hive + Firestore Sync Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'My Shopping Bag',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  '${loaded.totalItemCount} item${loaded.totalItemCount == 1 ? '' : 's'}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Swipe left on any item to remove',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            loaded.isSyncing
                                ? Icons.sync_rounded
                                : Icons.cloud_done_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hive + Cloud',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Free Shipping Progress Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_shipping_outlined,
                          size: 20,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    freeShippingUnlocked
                                        ? 'Unlocked Free Priority Shipping'
                                        : 'Add ${_summaryCurrency.format(loaded.amountUntilFreeShipping)} for Free Shipping',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                Text(
                                  '${(shippingProgress * 100).round()}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                              child: LinearProgressIndicator(
                                value: shippingProgress,
                                minHeight: 6,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Cart Item List
                for (final item in loaded.items) ...[
                  CartItemCard(
                    item: item,
                    onTap: () => onProductTap(item.product),
                    onIncrement: () => context.read<CartCubit>().updateQuantity(
                      item.product.id,
                      item.quantity + 1,
                      uid: uid,
                    ),
                    onDecrement: () => context.read<CartCubit>().updateQuantity(
                      item.product.id,
                      item.quantity - 1,
                      uid: uid,
                    ),
                    onRemove: () => context.read<CartCubit>().removeFromCart(
                      item.product.id,
                      uid: uid,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),

                // Order Financial Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
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
                      _PriceSummaryRow(
                        label: 'Subtotal (${loaded.totalItemCount} items)',
                        value: _summaryCurrency.format(loaded.subtotal),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Estimated Shipping',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'FREE OVER \$${AppConstants.freeShippingThreshold.round()}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            freeShippingUnlocked
                                ? 'Free'
                                : _summaryCurrency.format(loaded.shippingFee),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: freeShippingUnlocked
                                  ? AppColors.secondary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grand Total',
                                style: theme.textTheme.headlineSmall,
                              ),
                              Text(
                                'Includes estimated taxes',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Text(
                            _summaryCurrency.format(loaded.grandTotal),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Proceed to Checkout CTA
                ElevatedButton(
                  onPressed: () {
                    CheckoutBottomSheet.show(
                      context,
                      grandTotal: loaded.grandTotal,
                      onOrderConfirmed: (order) {
                        OrderConfirmationDialog.show(
                          context,
                          order: order,
                          onContinueShopping: () {
                            context.read<CartCubit>().clearLastCompletedOrder();
                            onExploreShop();
                          },
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 19),
                          SizedBox(width: 8),
                          Text('Proceed to Checkout'),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            _summaryCurrency.format(loaded.grandTotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PriceSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
