import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/theme/theme_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/widgets/product_card.dart';

/// Stitch Screen 2 — PulseCart Home & Product Catalog.
class CatalogHomePage extends StatelessWidget {
  final VoidCallback onOpenSearchTab;
  final VoidCallback onOpenCartTab;
  final VoidCallback onOpenProfileTab;
  final ValueChanged<ProductEntity> onProductTap;

  const CatalogHomePage({
    super.key,
    required this.onOpenSearchTab,
    required this.onOpenCartTab,
    required this.onOpenProfileTab,
    required this.onProductTap,
  });

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(AuthState state) {
    if (state is Authenticated && state.user.name.trim().isNotEmpty) {
      return state.user.name.trim().split(' ').first;
    }
    return 'Shopper';
  }

  IconData _iconForCategory(String category) {
    final slug = category.toLowerCase();
    if (slug == 'all') return Icons.grid_view_rounded;
    if (slug.contains('electronic')) return Icons.memory_rounded;
    if (slug.contains('jewel')) return Icons.diamond_outlined;
    if (slug.contains('women')) return Icons.woman_rounded;
    if (slug.contains('men')) return Icons.man_rounded;
    return Icons.category_rounded;
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

  Future<void> _showSortBottomSheet(
    BuildContext context,
    ProductSortOption currentOption,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Sort Products', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                for (final option in ProductSortOption.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label, style: theme.textTheme.bodyLarge),
                    trailing: option == currentOption
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      context.read<ProductCubit>().sortProducts(option);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addProductToCart(BuildContext context, ProductEntity product) {
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
            onPressed: onOpenCartTab,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;
    final isDark = context.watch<ThemeCubit>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
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
                  'Shop',
                  style: theme.textTheme.titleLarge?.copyWith(height: 1.1),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search & Filter',
            onPressed: onOpenSearchTab,
            icon: const Icon(Icons.search_rounded),
          ),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final count = cartState is CartLoaded
                  ? cartState.totalItemCount
                  : 0;
              return IconButton(
                tooltip: 'Shopping Cart',
                onPressed: onOpenCartTab,
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
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md, left: 4),
            child: GestureDetector(
              onTap: onOpenProfileTab,
              child: _UserAvatarCircle(authState: authState),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () {
          final uid = context.read<AuthCubit>().currentUser?.uid;
          return context.read<ProductCubit>().fetchProductsAndCategories(
            uid: uid,
          );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Greeting Header + Quick Search Trigger
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
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
                                      Icons.bolt_rounded,
                                      size: 13,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Synced to Hive & Firestore',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_timeGreeting()}, ${_firstName(authState)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Discover today's curated deals",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: colorScheme.surfaceContainerHigh,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                context.read<ThemeCubit>().toggleTheme(),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                size: 21,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Quick Search Pill Trigger
                    Material(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: onOpenSearchTab,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Search products, brands, categories...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Filter',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic Catalog Body from ProductCubit
            BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading || state is ProductInitial) {
                  return const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    sliver: SliverToBoxAdapter(child: ProductGridShimmer()),
                  );
                }

                if (state is ProductError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 52,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Could not load catalog',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: 180,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final uid = context
                                      .read<AuthCubit>()
                                      .currentUser
                                      ?.uid;
                                  context
                                      .read<ProductCubit>()
                                      .fetchProductsAndCategories(uid: uid);
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final loaded = state as ProductLoaded;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Recommended for You Horizontal Carousel
                    if (loaded.recommendedProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Recommended for You',
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ],
                            ),
                            Text(
                              loaded.categoryScores.isEmpty
                                  ? 'Top Rated'
                                  : 'Personalized',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 274,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 4,
                          ),
                          itemCount: loaded.recommendedProducts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final product = loaded.recommendedProducts[index];
                            final matchPct = (98 - index * 2).clamp(84, 99);
                            return RecommendedProductCard(
                              product: product,
                              matchPercent: matchPct,
                              onTap: () => onProductTap(product),
                              onAddToCart: () =>
                                  _addProductToCart(context, product),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Category Filter Chips
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categories',
                            style: theme.textTheme.headlineSmall,
                          ),
                          Text(
                            'FakeStore Catalog',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: loaded.categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = loaded.categories[index];
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
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _iconForCategory(category),
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _labelForCategory(category),
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: isSelected
                                                ? Colors.white
                                                : colorScheme.onSurface,
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
                    const SizedBox(height: AppSpacing.md),

                    // Grid Section Header + Sort trigger
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                loaded.selectedCategory ==
                                        AppConstants.allCategory
                                    ? 'Trending Products'
                                    : _labelForCategory(
                                        loaded.selectedCategory,
                                      ),
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  '${loaded.filteredProducts.length} items',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _showSortBottomSheet(
                              context,
                              loaded.sortOption,
                            ),
                            icon: const Icon(Icons.sort_rounded, size: 16),
                            label: Text(loaded.sortOption.label),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2-Column Product Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: loaded.filteredProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.64,
                            ),
                        itemBuilder: (context, index) {
                          final product = loaded.filteredProducts[index];
                          return ProductCard(
                            product: product,
                            onTap: () => onProductTap(product),
                            onAddToCart: () =>
                                _addProductToCart(context, product),
                          );
                        },
                      ),
                    ),

                    // Bottom clearance for floating pill nav bar
                    const SizedBox(height: 110),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatarCircle extends StatelessWidget {
  final AuthState authState;

  const _UserAvatarCircle({required this.authState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = authState is Authenticated
        ? (authState as Authenticated).user
        : null;
    final photoUrl = user?.photoUrl;
    final initial = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()[0].toUpperCase()
        : 'P';

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : null,
        child: (photoUrl == null || photoUrl.isEmpty)
            ? Text(
                initial,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              )
            : null,
      ),
    );
  }
}
