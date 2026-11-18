import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/repositories/product_repository.dart';

/// Fetches the complete product catalog (network-first with Hive cache fallback).
class GetProductsUseCase {
  final ProductRepository _repository;

  const GetProductsUseCase(this._repository);

  Future<List<ProductEntity>> call() => _repository.getProducts();
}

/// Fetches all product categories and prepends the `"All"` filter tab.
class GetCategoriesUseCase {
  final ProductRepository _repository;

  const GetCategoriesUseCase(this._repository);

  Future<List<String>> call() async {
    final remoteCategories = await _repository.getCategories();
    final normalized = <String>[AppConstants.allCategory];
    for (final category in remoteCategories) {
      if (category.trim().isNotEmpty &&
          category.toLowerCase() != AppConstants.allCategory.toLowerCase()) {
        normalized.add(category);
      }
    }
    return normalized;
  }
}

/// Fetches a single product by its unique [id].
class GetProductByIdUseCase {
  final ProductRepository _repository;

  const GetProductByIdUseCase(this._repository);

  Future<ProductEntity> call(int id) => _repository.getProductById(id);
}

/// Pure domain filter & sort engine for catalog browsing and instant search.
class FilterAndSortProductsUseCase {
  const FilterAndSortProductsUseCase();

  List<ProductEntity> call({
    required List<ProductEntity> products,
    String selectedCategory = AppConstants.allCategory,
    String searchQuery = '',
    ProductSortOption sortOption = ProductSortOption.relevance,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final normalizedCategory = selectedCategory.trim().toLowerCase();
    final filterByCategory =
        normalizedCategory.isNotEmpty &&
        normalizedCategory != AppConstants.allCategory.toLowerCase();

    final filtered = products.where((product) {
      if (filterByCategory &&
          product.category.toLowerCase() != normalizedCategory) {
        return false;
      }
      if (normalizedQuery.isNotEmpty) {
        final matchesTitle = product.title.toLowerCase().contains(
          normalizedQuery,
        );
        final matchesDesc = product.description.toLowerCase().contains(
          normalizedQuery,
        );
        final matchesCategory = product.category.toLowerCase().contains(
          normalizedQuery,
        );
        return matchesTitle || matchesDesc || matchesCategory;
      }
      return true;
    }).toList();

    switch (sortOption) {
      case ProductSortOption.relevance:
        break;
      case ProductSortOption.priceLowToHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case ProductSortOption.priceHighToLow:
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case ProductSortOption.topRated:
        filtered.sort((a, b) {
          final rateCmp = b.ratingRate.compareTo(a.ratingRate);
          if (rateCmp != 0) return rateCmp;
          return b.ratingCount.compareTo(a.ratingCount);
        });
    }

    return filtered;
  }
}
