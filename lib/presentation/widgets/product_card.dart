import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';

final NumberFormat _currencyFormatter = NumberFormat.simpleCurrency(
  name: 'USD',
  decimalDigits: 2,
);

/// 2-Column Grid Product Card faithfully matching Stitch Screen 2 (`PulseCart`).
class ProductCard extends StatefulWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _justAdded = false;

  Future<void> _handleQuickAdd() async {
    widget.onAddToCart();
    if (!mounted) return;
    setState(() => _justAdded = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) {
      setState(() => _justAdded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppColors.darkSubtleBorder
                  : AppColors.lightSubtleBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media container (1:1 aspect ratio on clean light studio backdrop)
              AspectRatio(
                aspectRatio: 1.05,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : AppColors.lightSurfaceLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Hero(
                    tag: 'product-image-${widget.product.id}',
                    child: _SafeProductImage(imageUrl: widget.product.image),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Category label
              Text(
                widget.product.formattedCategory.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),

              // Product title (2 lines max)
              Expanded(
                child: Text(
                  widget.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),

              // Rating row
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    widget.product.ratingRate.toStringAsFixed(1),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '(${widget.product.ratingCount})',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Price & Quick Add CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currencyFormatter.format(widget.product.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleQuickAdd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _justAdded
                            ? AppColors.secondary
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_justAdded
                                        ? AppColors.secondary
                                        : AppColors.primary)
                                    .withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _justAdded ? Icons.check_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal Carousel Card for Stitch "Recommended for You" affinity section.
class RecommendedProductCard extends StatefulWidget {
  final ProductEntity product;
  final int matchPercent;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const RecommendedProductCard({
    super.key,
    required this.product,
    required this.matchPercent,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  State<RecommendedProductCard> createState() => _RecommendedProductCardState();
}

class _RecommendedProductCardState extends State<RecommendedProductCard> {
  bool _justAdded = false;

  Future<void> _handleQuickAdd() async {
    widget.onAddToCart();
    if (!mounted) return;
    setState(() => _justAdded = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) {
      setState(() => _justAdded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 248,
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSubtleBorder
                    : AppColors.lightSubtleBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 132,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightSurfaceLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _SafeProductImage(imageUrl: widget.product.image),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.matchPercent}% Match',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      widget.product.ratingRate.toStringAsFixed(1),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${widget.product.ratingCount})',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currencyFormatter.format(widget.product.price),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleQuickAdd,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _justAdded
                              ? AppColors.secondary
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _justAdded ? Icons.check_rounded : Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for product grid cards while FakeStoreAPI loads.
class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.lightSurfaceLow;
    final highlightColor = isDark
        ? AppColors.darkSurfaceHigh
        : AppColors.lightSurfaceLowest;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _SafeProductImage extends StatelessWidget {
  final String imageUrl;

  const _SafeProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (imageUrl.isEmpty) {
      return Icon(
        Icons.image_not_supported_outlined,
        color: colorScheme.onSurfaceVariant,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      httpHeaders: const {'Accept': 'image/jpeg,image/png,image/*,*/*'},
      placeholder: (_, _) => const _ImageShimmerPlaceholder(),
      errorWidget: (_, _, _) => Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ImageShimmerPlaceholder extends StatelessWidget {
  const _ImageShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightSurfaceContainer,
      highlightColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
