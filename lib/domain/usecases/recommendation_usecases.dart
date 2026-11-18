import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/repositories/cart_order_repository.dart';

/// Fetches the user's per-category interaction scores from Hive / Firestore.
class GetCategoryAffinityUseCase {
  final CartOrderRepository _repository;

  const GetCategoryAffinityUseCase(this._repository);

  Future<Map<String, int>> call(String? uid) =>
      _repository.getCategoryAffinity(uid);
}

/// Records an interaction with a product category (e.g., viewing details or adding to cart).
class TrackCategoryAffinityUseCase {
  final CartOrderRepository _repository;

  const TrackCategoryAffinityUseCase(this._repository);

  Future<Map<String, int>> call({
    required String category,
    int weight = 1,
    String? uid,
  }) {
    return _repository.trackCategoryAffinity(
      category: category,
      weight: weight,
      uid: uid,
    );
  }
}

/// Computes personalized "Recommended for You" products using category affinity scores.
///
/// Products in categories with higher affinity scores are ranked first,
/// using customer rating and review volume as deterministic tiebreakers.
/// For brand-new users with no history, falls back to top-rated catalog items.
class GetRecommendedProductsUseCase {
  const GetRecommendedProductsUseCase();

  List<ProductEntity> call({
    required List<ProductEntity> allProducts,
    required Map<String, int> categoryScores,
    int maxResults = 8,
  }) {
    if (allProducts.isEmpty) return const [];

    final normalizedScores = <String, int>{
      for (final entry in categoryScores.entries)
        entry.key.trim().toLowerCase(): entry.value,
    };

    final ranked = List<ProductEntity>.from(allProducts);
    ranked.sort((a, b) {
      final scoreA = normalizedScores[a.category.trim().toLowerCase()] ?? 0;
      final scoreB = normalizedScores[b.category.trim().toLowerCase()] ?? 0;
      final affinityCmp = scoreB.compareTo(scoreA);
      if (affinityCmp != 0) return affinityCmp;

      final ratingCmp = b.ratingRate.compareTo(a.ratingRate);
      if (ratingCmp != 0) return ratingCmp;

      return b.ratingCount.compareTo(a.ratingCount);
    });

    if (ranked.length <= maxResults) return ranked;
    return ranked.sublist(0, maxResults);
  }
}
