import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_state.dart';
import 'package:e_commerce_shopping_app/presentation/widgets/product_card.dart';

/// Stitch Screen 3 — PulseCart Search & Advanced Filter.
class SearchFilterPage extends StatefulWidget {
  final VoidCallback onOpenCartTab;
  final ValueChanged<ProductEntity> onProductTap;

  const SearchFilterPage({
    super.key,
    required this.onOpenCartTab,
    required this.onProductTap,
  });

  @override
  State<SearchFilterPage> createState() => _SearchFilterPageState();
}

class _SearchFilterPageState extends State<SearchFilterPage> {
  final TextEditingController _searchController = TextEditingController();
  RangeValues? _priceRange;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductCubit>().state;
    if (state is ProductLoaded && state.searchQuery.isNotEmpty) {
      _searchController.text = state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _labelForCategory(String category) {
    if (category.toLowerCase() == 'all') return 'All';
    if (category.toLowerCase() == "men's clothing") return "Men's";
    if (category.toLowerCase() == "women's clothing") return "Women's";
    return category
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  int _countForCategory(List<ProductEntity> allProducts, String category) {
    if (category.toLowerCase() == AppConstants.allCategory.toLowerCase()) {
      return allProducts.length;
    }
    return allProducts
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .length;
  }

  double _maxCatalogPrice(List<ProductEntity> allProducts) {
    if (allProducts.isEmpty) return 1000.0;
    final maxVal = allProducts
        .map((p) => p.price)
        .reduce((a, b) => a > b ? a : b);
    return (maxVal / 50).ceil() * 50.0;
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() => _priceRange = null);
    context.read<ProductCubit>().resetFilters();
  }

  void _addProductToCart(ProductEntity product) {
    final uid = context.read<AuthCubit>().currentUser?.uid;
    context.read<CartCubit>().addToCart(product, uid: uid);
    context.read<ProductCubit>().loadAndRefreshRecommendations(uid);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Added "${product.title}" to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: AppColors.secondaryContainer,
            onPressed: widget.onOpenCartTab,
          ),
        ),
      );
  }

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
              'Search & Filter',
              style: theme.textTheme.titleLarge?.copyWith(height: 1.1),
            ),
          ],
        ),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final count = cartState is CartLoaded
                  ? cartState.totalItemCount
                  : 0;
              return IconButton(
                tooltip: 'Shopping Cart',
                onPressed: widget.onOpenCartTab,
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
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading || state is ProductInitial) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ProductGridShimmer(),
            );
          }

          if (state is ProductError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final loaded = state as ProductLoaded;
          final maxPrice = _maxCatalogPrice(loaded.allProducts);
          final activeRange = _priceRange ?? RangeValues(0, maxPrice);
          final clampedRange = RangeValues(
            activeRange.start.clamp(0, maxPrice),
            activeRange.end.clamp(0, maxPrice),
          );

          final hasBudgetFilter =
              _priceRange != null &&
              (clampedRange.start > 0 || clampedRange.end < maxPrice);

          final displayedProducts = loaded.filteredProducts.where((p) {
            return p.price >= clampedRange.start && p.price <= clampedRange.end;
          }).toList();

          final hasAnyFilter = loaded.hasActiveFilters || hasBudgetFilter;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instant Search Bar
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          setState(() {});
                          context.read<ProductCubit>().searchProducts(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search electronics, clothing, jewelry...',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                    context.read<ProductCubit>().searchProducts(
                                      '',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    size: 20,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Horizontal Category Filter Pills with Live Counts
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: loaded.categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = loaded.categories[index];
                            final count = _countForCategory(
                              loaded.allProducts,
                              category,
                            );
                            final isSelected =
                                loaded.selectedCategory.toLowerCase() ==
                                category.toLowerCase();

                            return Material(
                              color: isSelected
                                  ? AppColors.primary
                                  : colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                                onTap: () => context
                                    .read<ProductCubit>()
                                    .filterByCategory(category),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                      ],
                                      Text(
                                        _labelForCategory(category),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: isSelected
                                                  ? Colors.white
                                                  : colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withValues(
                                                  alpha: 0.22,
                                                )
                                              : colorScheme
                                                    .surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusFull,
                                          ),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: isSelected
                                                    ? Colors.white
                                                    : colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Interactive Refinement Card (Sort Chips + Budget RangeSlider)
                      Container(
                        padding: const EdgeInsets.all(14),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.swap_vert_rounded,
                                      size: 15,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SORT BY',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(letterSpacing: 0.7),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Active: ${loaded.sortOption.label}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: ProductSortOption.values.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final option =
                                      ProductSortOption.values[index];
                                  final isSelected =
                                      loaded.sortOption == option;
                                  return Material(
                                    color: isSelected
                                        ? AppColors.primary
                                        : colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull,
                                      ),
                                      onTap: () => context
                                          .read<ProductCubit>()
                                          .sortProducts(option),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (option ==
                                                ProductSortOption.topRated) ...[
                                              Icon(
                                                Icons.star_rounded,
                                                size: 13,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.tertiary,
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            Text(
                                              option.label,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : colorScheme
                                                              .onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Budget Bound RangeSlider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payments_outlined,
                                      size: 15,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Budget Bound',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    '\$${clampedRange.start.round()} — \$${clampedRange.end.round()}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor:
                                    colorScheme.surfaceContainerHighest,
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withValues(
                                  alpha: 0.14,
                                ),
                                trackHeight: 4,
                              ),
                              child: RangeSlider(
                                values: clampedRange,
                                min: 0,
                                max: maxPrice,
                                divisions: 20,
                                onChanged: (values) =>
                                    setState(() => _priceRange = values),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Search Meta Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
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
                                Expanded(
                                  child: Text(
                                    'Showing ${displayedProducts.length} result${displayedProducts.length == 1 ? '' : 's'}'
                                    '${loaded.selectedCategory == AppConstants.allCategory ? '' : ' in "${_labelForCategory(loaded.selectedCategory)}"'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasAnyFilter)
                            TextButton.icon(
                              onPressed: _resetAllFilters,
                              icon: const Icon(Icons.refresh_rounded, size: 15),
                              label: const Text('Reset'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Results Grid or Empty State
              if (displayedProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 110),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 34,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No matching products',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try adjusting your search keywords, category filter, or price range.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 200,
                            child: OutlinedButton.icon(
                              onPressed: _resetAllFilters,
                              icon: const Icon(Icons.filter_alt_off_rounded),
                              label: const Text('Clear Filters'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    110,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.64,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = displayedProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => widget.onProductTap(product),
                        onAddToCart: () => _addProductToCart(product),
                      );
                    }, childCount: displayedProducts.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
