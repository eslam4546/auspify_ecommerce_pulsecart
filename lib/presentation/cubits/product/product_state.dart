import 'package:equatable/equatable.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';

/// Base state for [ProductCubit].
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Initial state before the catalog has been fetched.
class ProductInitial extends ProductState {
  const ProductInitial();
}

/// Emitted while fetching catalog and categories from FakeStoreAPI / Hive cache.
class ProductLoading extends ProductState {
  const ProductLoading();
}

/// Emitted when catalog products are loaded and ready for browsing, search, and filtering.
class ProductLoaded extends ProductState {
  final List<ProductEntity> allProducts;
  final List<ProductEntity> filteredProducts;
  final List<ProductEntity> recommendedProducts;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final ProductSortOption sortOption;
  final Map<String, int> categoryScores;

  const ProductLoaded({
    required this.allProducts,
    required this.filteredProducts,
    required this.recommendedProducts,
    required this.categories,
    this.selectedCategory = AppConstants.allCategory,
    this.searchQuery = '',
    this.sortOption = ProductSortOption.relevance,
    this.categoryScores = const {},
  });

  bool get hasActiveFilters =>
      selectedCategory != AppConstants.allCategory ||
      searchQuery.trim().isNotEmpty ||
      sortOption != ProductSortOption.relevance;

  ProductLoaded copyWith({
    List<ProductEntity>? allProducts,
    List<ProductEntity>? filteredProducts,
    List<ProductEntity>? recommendedProducts,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    ProductSortOption? sortOption,
    Map<String, int>? categoryScores,
  }) {
    return ProductLoaded(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      categoryScores: categoryScores ?? this.categoryScores,
    );
  }

  @override
  List<Object?> get props => [
    allProducts,
    filteredProducts,
    recommendedProducts,
    categories,
    selectedCategory,
    searchQuery,
    sortOption,
    categoryScores,
  ];
}

/// Emitted when loading the product catalog fails with no offline cache available.
class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
