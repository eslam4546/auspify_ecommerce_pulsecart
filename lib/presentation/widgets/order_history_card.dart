import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';

final NumberFormat _orderCurrency = NumberFormat.simpleCurrency(
  name: 'USD',
  decimalDigits: 2,
);
final DateFormat _orderDateFormat = DateFormat('MMM d, y • h:mm a');

/// Expandable order history card faithfully matching Stitch Screen 6 (`My Orders`).
class OrderHistoryCard extends StatefulWidget {
  final OrderEntity order;
  final VoidCallback onReorder;

  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.onReorder,
  });

  @override
  State<OrderHistoryCard> createState() => _OrderHistoryCardState();
}

class _OrderHistoryCardState extends State<OrderHistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final order = widget.order;
    final shortId = order.orderId.length >= 8
        ? order.orderId.substring(0, 8).toUpperCase()
        : order.orderId.toUpperCase();
    final isCompleted = order.status == AppConstants.orderStatusCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Order Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '#ORD-$shortId',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.done_all_rounded
                                      : Icons.schedule_rounded,
                                  size: 12,
                                  color: isCompleted
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.status,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isCompleted
                                        ? colorScheme.onSecondaryContainer
                                        : colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_orderDateFormat.format(order.createdAt)} • ${order.totalItemCount} item${order.totalItemCount == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _orderCurrency.format(order.totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Thumbnail Preview Row + Reorder Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  for (final item in order.items.take(3))
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightSurfaceLow,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: item.product.image,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.shopping_bag_outlined, size: 16),
                      ),
                    ),
                  if (order.items.length > 3)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          '+${order.items.length - 3}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
              TextButton.icon(
                onPressed: widget.onReorder,
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Reorder'),
              ),
            ],
          ),

          // Expandable Line Items & Shipping Details
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _orderCurrency.format(item.totalPrice),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment: ${order.paymentMethod}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Ship to: ${order.shippingAddress.formatted}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
