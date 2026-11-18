import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';

final NumberFormat _cartCurrency = NumberFormat.simpleCurrency(
  name: 'USD',
  decimalDigits: 2,
);

/// Swipe-to-delete Shopping Cart line item card matching Stitch Screen 5.
class CartItemCard extends StatelessWidget {
  final CartItemEntity item;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey('cart-item-${item.product.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSubtleBorder
                    : AppColors.lightSubtleBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 82,
                  height: 82,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.lightSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: item.product.image,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details + Price + Stepper
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.product.formattedCategory,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                            onTap: onRemove,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cartCurrency.format(item.totalPrice),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (item.quantity > 1)
                                Text(
                                  '${_cartCurrency.format(item.product.price)} each',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          // Quantity Stepper Pill
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _MiniStepperBtn(
                                  icon: Icons.remove_rounded,
                                  onTap: onDecrement,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                _MiniStepperBtn(
                                  icon: Icons.add_rounded,
                                  onTap: onIncrement,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniStepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
