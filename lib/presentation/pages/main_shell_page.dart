import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';
import 'package:e_commerce_shopping_app/presentation/pages/home/catalog_home_page.dart';

/// Signature builder for injecting tabs cleanly into [MainShellPage].
typedef ShellTabBuilder = Widget Function(
  BuildContext context,
  ValueChanged<int> switchTab,
  ValueChanged<ProductEntity> openProductDetails,
);

/// Root authenticated shell featuring Stitch's floating glassmorphic pill dock
/// with 4 destinations: Shop, Search, Cart (with live emerald counter badge), and Profile.
class MainShellPage extends StatefulWidget {
  final ShellTabBuilder? searchTabBuilder;
  final ShellTabBuilder? cartTabBuilder;
  final ShellTabBuilder? profileTabBuilder;
  final void Function(
    BuildContext context,
    ProductEntity product,
    ValueChanged<int> switchTab,
  )?
  onOpenProductDetails;

  const MainShellPage({
    super.key,
    this.searchTabBuilder,
    this.cartTabBuilder,
    this.profileTabBuilder,
    this.onOpenProductDetails,
  });

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _handleProductTap(ProductEntity product) {
    widget.onOpenProductDetails?.call(context, product, _switchTab);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final pages = <Widget>[
      CatalogHomePage(
        onOpenSearchTab: () => _switchTab(1),
        onOpenCartTab: () => _switchTab(2),
        onOpenProfileTab: () => _switchTab(3),
        onProductTap: _handleProductTap,
      ),
      widget.searchTabBuilder?.call(context, _switchTab, _handleProductTap) ??
          const SizedBox.shrink(),
      widget.cartTabBuilder?.call(context, _switchTab, _handleProductTap) ??
          const SizedBox.shrink(),
      widget.profileTabBuilder?.call(context, _switchTab, _handleProductTap) ??
          const SizedBox.shrink(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest.withValues(
                  alpha: isDark ? 0.88 : 0.92,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkSubtleBorder
                      : AppColors.lightSubtleBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.2 : 0.12,
                    ),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  final cartCount = cartState is CartLoaded
                      ? cartState.totalItemCount
                      : 0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DockItem(
                        icon: Icons.storefront_outlined,
                        activeIcon: Icons.storefront_rounded,
                        label: 'Shop',
                        isSelected: _currentIndex == 0,
                        onTap: () => _switchTab(0),
                      ),
                      _DockItem(
                        icon: Icons.search_rounded,
                        activeIcon: Icons.search_rounded,
                        label: 'Search',
                        isSelected: _currentIndex == 1,
                        onTap: () => _switchTab(1),
                      ),
                      _DockItem(
                        icon: Icons.local_mall_outlined,
                        activeIcon: Icons.local_mall_rounded,
                        label: 'Cart',
                        badgeCount: cartCount,
                        isSelected: _currentIndex == 2,
                        onTap: () => _switchTab(2),
                      ),
                      _DockItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profile',
                        isSelected: _currentIndex == 3,
                        onTap: () => _switchTab(3),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 24,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -10,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surfaceContainerLowest,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
