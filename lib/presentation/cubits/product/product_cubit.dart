import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/usecases/product_usecases.dart';
import 'package:e_commerce_shopping_app/domain/usecases/recommendation_usecases.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_state.dart';

/// Cubit managing catalog loading, category filtering, live search,
/// sorting, similar product lookups, and category-affinity recommendations.
class ProductCubit extends Cubit<ProductState> {
  final GetProductsUseCase _getProducts;
  final GetCategoriesUseCase _getCategories;
  final FilterAndSortProductsUseCase _filterAndSort;
  final GetRecommendedProductsUseCase _getRecommended;
  final GetCategoryAffinityUseCase _getCategoryAffinity;
  final TrackCategoryAffinityUseCase _trackCategoryAffinity;

  ProductCubit({
    required this._getProducts,
    required this._getCategories,
    required this._filterAndSort,
    required this._getRecommended,
    required this._getCategoryAffinity,
    required this._trackCategoryAffinity,
  }) : super(const ProductInitial());

  /// Loads products, categories, and user affinity recommendations.
  Future<void> fetchProductsAndCategories({String? uid}) async {
    final previousState = state;
    final preservedCategory = previousState is ProductLoaded
        ? previousState.selectedCategory
        : AppConstants.allCategory;
    final preservedQuery = previousState is ProductLoaded
        ? previousState.searchQuery
        : '';
    final preservedSort = previousState is ProductLoaded
        ? previousState.sortOption
        : ProductSortOption.relevance;

    emit(const ProductLoading());

    try {
      final results = await Future.wait<dynamic>([
        _getProducts(),
        _getCategories(),
        _safeGetAffinity(uid),
      ]);

      final products = results[0] as List<ProductEntity>;
      final categories = results[1] as List<String>;
      final affinityScores = results[2] as Map<String, int>;

      final filtered = _filterAndSort(
        products: products,
        selectedCategory: preservedCategory,
        searchQuery: preservedQuery,
        sortOption: preservedSort,
      );
      final recommended = _getRecommended(
        allProducts: products,
        categoryScores: affinityScores,
      );

      emit(
        ProductLoaded(
          allProducts: products,
          filteredProducts: filtered,
          recommendedProducts: recommended,
          categories: categories,
          selectedCategory: preservedCategory,
          searchQuery: preservedQuery,
          sortOption: preservedSort,
          categoryScores: affinityScores,
        ),
      );
    } on Failure catch (failure) {
      emit(ProductError(failure.message));
    } catch (_) {
      emit(
        const ProductError(
          'Unable to load the product catalog. Please try again.',
        ),
      );
    }
  }

  /// Filters the loaded catalog in real time by [query].
  void searchProducts(String query) {
    final current = state;
    if (current is! ProductLoaded) return;

    final filtered = _filterAndSort(
      products: current.allProducts,
      selectedCategory: current.selectedCategory,
      searchQuery: query,
      sortOption: current.sortOption,
    );

    emit(current.copyWith(searchQuery: query, filteredProducts: filtered));
  }

  /// Filters the loaded catalog by [category] (or `"All"`).
  void filterByCategory(String category) {
    final current = state;
    if (current is! ProductLoaded) return;

    final filtered = _filterAndSort(
      products: current.allProducts,
      selectedCategory: category,
      searchQuery: current.searchQuery,
      sortOption: current.sortOption,
    );

    emit(
      current.copyWith(selectedCategory: category, filteredProducts: filtered),
    );
  }

  /// Sorts the filtered catalog using [option].
  void sortProducts(ProductSortOption option) {
    final current = state;
    if (current is! ProductLoaded) return;

    final filtered = _filterAndSort(
      products: current.allProducts,
      selectedCategory: current.selectedCategory,
      searchQuery: current.searchQuery,
      sortOption: option,
    );

    emit(current.copyWith(sortOption: option, filteredProducts: filtered));
  }

  /// Resets search query, selected category, and sort order back to defaults.
  void resetFilters() {
    final current = state;
    if (current is! ProductLoaded) return;

    final filtered = _filterAndSort(
      products: current.allProducts,
      selectedCategory: AppConstants.allCategory,
      searchQuery: '',
      sortOption: ProductSortOption.relevance,
    );

    emit(
      current.copyWith(
        selectedCategory: AppConstants.allCategory,
        searchQuery: '',
        sortOption: ProductSortOption.relevance,
        filteredProducts: filtered,
      ),
    );
  }

  /// Recomputes "Recommended for You" using updated [categoryScores].
  void refreshRecommendations(Map<String, int> categoryScores) {
    final current = state;
    if (current is! ProductLoaded) return;

    final recommended = _getRecommended(
      allProducts: current.allProducts,
      categoryScores: categoryScores,
    );

    emit(
      current.copyWith(
        categoryScores: Map<String, int>.unmodifiable(categoryScores),
        recommendedProducts: recommended,
      ),
    );
  }

  /// Reloads affinity scores from Hive / Firestore and refreshes recommendations.
  Future<void> loadAndRefreshRecommendations(String? uid) async {
    final scores = await _safeGetAffinity(uid);
    refreshRecommendations(scores);
  }

  /// Records a category view/interaction and updates recommendations live.
  Future<void> trackCategoryInteraction(String category, {String? uid}) async {
    try {
      final updatedScores = await _trackCategoryAffinity(
        category: category,
        weight: 1,
        uid: uid,
      );
      refreshRecommendations(updatedScores);
    } catch (_) {
      // Non-fatal recommendation telemetry error.
    }
  }

  /// Returns products from the same category as [product], excluding [product] itself.
  List<ProductEntity> getSimilarProducts(
    ProductEntity product, {
    int limit = 6,
  }) {
    final current = state;
    if (current is! ProductLoaded) return const [];

    final similar =
        current.allProducts
            .where(
              (item) =>
                  item.id != product.id &&
                  item.category.toLowerCase() == product.category.toLowerCase(),
            )
            .toList()
          ..sort((a, b) => b.ratingRate.compareTo(a.ratingRate));

    if (similar.length <= limit) return similar;
    return similar.sublist(0, limit);
  }

  Future<Map<String, int>> _safeGetAffinity(String? uid) async {
    try {
      return await _getCategoryAffinity(uid);
    } catch (_) {
      return const {};
    }
  }
}
