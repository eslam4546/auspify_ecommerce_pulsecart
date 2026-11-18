import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/pages/auth/login_page.dart';
import 'package:e_commerce_shopping_app/presentation/pages/auth/register_page.dart';
import 'package:e_commerce_shopping_app/presentation/pages/cart/cart_page.dart';
import 'package:e_commerce_shopping_app/presentation/pages/main_shell_page.dart';
import 'package:e_commerce_shopping_app/presentation/pages/product_details/product_details_page.dart';
import 'package:e_commerce_shopping_app/presentation/pages/profile/profile_page.dart';
import 'package:e_commerce_shopping_app/presentation/pages/search/search_filter_page.dart';

/// Centralized navigation routes and root auth-transition helpers for PulseCart.
abstract final class AppRouter {
  /// Builds the fully wired 4-tab [MainShellPage] (Shop, Search, Cart, Profile).
  static Widget buildMainShell() {
    return MainShellPage(
      searchTabBuilder: (ctx, switchTab, openDetails) => SearchFilterPage(
        onOpenCartTab: () => switchTab(2),
        onProductTap: openDetails,
      ),
      cartTabBuilder: (ctx, switchTab, openDetails) => CartPage(
        onExploreShop: () => switchTab(0),
        onProductTap: openDetails,
      ),
      profileTabBuilder: (ctx, switchTab, _) =>
          ProfilePage(onOpenCartTab: () => switchTab(2)),
      onOpenProductDetails: (ctx, product, switchTab) =>
          _openProductDetails(ctx, product, switchTab),
    );
  }

  static Route<void> mainShellRoute() {
    return MaterialPageRoute<void>(builder: (_) => buildMainShell());
  }

  static Route<void> loginRoute() {
    return MaterialPageRoute<void>(builder: (_) => const LoginPage());
  }

  static Route<void> registerRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const RegisterPage(),
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  /// Hydrates the authenticated user's Hybrid Cart & Catalog and routes
  /// directly to [MainShellPage], clearing the entire back stack.
  static void navigateToHome(BuildContext context, String uid) {
    context.read<CartCubit>().loadCart(uid: uid);
    context.read<ProductCubit>().fetchProductsAndCategories(uid: uid);
    Navigator.of(context).pushAndRemoveUntil(mainShellRoute(), (_) => false);
  }

  /// Routes back to [LoginPage] and clears the entire navigation stack.
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(loginRoute(), (_) => false);
  }

  static void _openProductDetails(
    BuildContext context,
    ProductEntity product,
    ValueChanged<int> switchTab,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsPage(
          product: product,
          onOpenCart: () => switchTab(2),
        ),
      ),
    );
  }
}
