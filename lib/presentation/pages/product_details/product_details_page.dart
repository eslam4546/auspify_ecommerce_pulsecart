import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_cubit.dart';

final NumberFormat _detailsCurrency = NumberFormat.simpleCurrency(
  name: 'USD',
  decimalDigits: 2,
);

/// Stitch Screen 4 — PulseCart Product Details & Recommendations.
class ProductDetailsPage extends StatefulWidget {
  final ProductEntity product;
  final VoidCallback? onOpenCart;

  const ProductDetailsPage({super.key, required this.product, this.onOpenCart});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;
  bool _isWishlisted = false;
  bool _isSpecsExpanded = true;

  @override
  void initState() {
    super.initState();
    // Record category affinity when inspecting a product to enrich recommendations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthCubit>().currentUser?.uid;
      context.read<ProductCubit>().trackCategoryInteraction(
        widget.product.category,
        uid: uid,
      );
    });
  }

  void _decrementQty() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
  }

  void _incrementQty() {
    if (_quantity >= 99) return;
    setState(() => _quantity++);
  }

  Future<void> _handleAddToCart({bool openCartAfter = false}) async {
    final uid = context.read<AuthCubit>().currentUser?.uid;
    await context.read<CartCubit>().addToCart(
      widget.product,
      quantity: _quantity,
      uid: uid,
    );
    if (!mounted) return;
    context.read<ProductCubit>().loadAndRefreshRecommendations(uid);

    if (openCartAfter) {
      Navigator.of(context).pop();
      widget.onOpenCart?.call();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Added $_quantity x "${widget.product.title}" to cart'),
          action: widget.onOpenCart == null
              ? null
              : SnackBarAction(
                  label: 'VIEW CART',
                  textColor: AppColors.secondaryContainer,
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onOpenCart?.call();
                  },
                ),
        ),
      );
  }

  void _openSimilarProduct(ProductEntity similar) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductDetailsPage(product: similar, onOpenCart: widget.onOpenCart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final product = widget.product;
    final similarProducts = context.read<ProductCubit>().getSimilarProducts(
      product,
    );
    final liveTotal = product.price * _quantity;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Product Details'),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final count = cartState is CartLoaded
                  ? cartState.totalItemCount
                  : 0;
              return IconButton(
                tooltip: 'Shopping Cart',
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onOpenCart?.call();
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.local_mall_outlined),
                    if (count > 0)
                      Positioned(
                        top: -5,
                        right: -7,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              152,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category pill & Share / Wishlist actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                            Icons.category_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.formattedCategory,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.share_outlined,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ready to share "${product.title}"',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _CircleIconButton(
                          icon: _isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor: _isWishlisted
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                          onTap: () =>
                              setState(() => _isWishlisted = !_isWishlisted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Hero Product Gallery Card
                Container(
                  padding: const EdgeInsets.all(14),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'In Stock • Ships in 24h',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              'Pinch to zoom',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 260,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightSurfaceLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 3.0,
                          child: Hero(
                            tag: 'product-image-${product.id}',
                            child: CachedNetworkImage(
                              imageUrl: product.image,
                              fit: BoxFit.contain,
                              errorWidget: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Rating & Reviews Strip
                Row(
                  children: [
                    _StarRatingBar(rating: product.ratingRate),
                    const SizedBox(width: 6),
                    Text(
                      product.ratingRate.toStringAsFixed(1),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${product.ratingCount} global reviews)',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Product Title
                Text(
                  product.title,
                  style: theme.textTheme.headlineMedium?.copyWith(height: 1.25),
                ),
                const SizedBox(height: 8),

                // Price + Free Shipping eligibility badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _detailsCurrency.format(product.price),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (product.price >= 100)
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
                        child: Text(
                          'FREE SHIPPING',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Feature Pillars
                Row(
                  children: [
                    Expanded(
                      child: _FeaturePillar(
                        icon: Icons.local_shipping_outlined,
                        title: 'Express',
                        subtitle: '24h dispatch',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FeaturePillar(
                        icon: Icons.verified_user_outlined,
                        title: 'Authentic',
                        subtitle: 'Verified item',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FeaturePillar(
                        icon: Icons.replay_rounded,
                        title: '30-Day',
                        subtitle: 'Easy returns',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Expandable Product Specifications & Description Card
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => setState(
                          () => _isSpecsExpanded = !_isSpecsExpanded,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Product Specifications',
                              style: theme.textTheme.headlineSmall,
                            ),
                            AnimatedRotation(
                              turns: _isSpecsExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 220),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.expand_more_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 240),
                        crossFadeState: _isSpecsExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              product.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _SpecRow(
                                    label: 'Category',
                                    value: product.formattedCategory,
                                  ),
                                  const SizedBox(height: 6),
                                  _SpecRow(
                                    label: 'Customer Score',
                                    value:
                                        '${product.ratingRate.toStringAsFixed(1)} / 5.0 (${product.ratingCount})',
                                  ),
                                  const SizedBox(height: 6),
                                  _SpecRow(
                                    label: 'Catalog SKU',
                                    value:
                                        'PC-${product.id.toString().padLeft(4, '0')}',
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
                ),

                // Similar Products Carousel
                if (similarProducts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Similar Products',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Handpicked items in ${product.formattedCategory}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 214,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: similarProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = similarProducts[index];
                        return _SimilarProductTile(
                          product: item,
                          onTap: () => _openSimilarProduct(item),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sticky Glassmorphic Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    12,
                    AppSpacing.md,
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.92),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // Quantity Stepper Pill
                            Container(
                              height: 50,
                              width: 114,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _StepperCircleButton(
                                    icon: Icons.remove_rounded,
                                    enabled: _quantity > 1,
                                    onTap: _decrementQty,
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  _StepperCircleButton(
                                    icon: Icons.add_rounded,
                                    enabled: _quantity < 99,
                                    onTap: _incrementQty,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Add to Cart Gradient CTA with live total
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _handleAddToCart(),
                                child: Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Colors.white,
                                            size: 19,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Add to Cart',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _detailsCurrency.format(liveTotal),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Instant Buy Express Action
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: TextButton.icon(
                            onPressed: () =>
                                _handleAddToCart(openCartAfter: true),
                            style: TextButton.styleFrom(
                              backgroundColor: colorScheme.secondaryContainer,
                              foregroundColor: colorScheme.onSecondaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.bolt_rounded, size: 17),
                            label: const Text('Instant Buy — Go to Checkout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 19,
            color: iconColor ?? colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _StarRatingBar extends StatelessWidget {
  final double rating;

  const _StarRatingBar({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starPos = index + 1;
        IconData icon;
        if (rating >= starPos) {
          icon = Icons.star_rounded;
        } else if (rating >= starPos - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: 17, color: AppColors.tertiary);
      }),
    );
  }
}

class _FeaturePillar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeaturePillar({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SimilarProductTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  const _SimilarProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 152,
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSubtleBorder
                    : AppColors.lightSubtleBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 112,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.lightSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.image,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      product.ratingRate.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _detailsCurrency.format(product.price),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
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

class _StepperCircleButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperCircleButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: enabled
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surfaceContainerLowest.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
