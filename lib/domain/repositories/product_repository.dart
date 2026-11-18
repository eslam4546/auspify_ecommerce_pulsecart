import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';

/// Contract for fetching product catalog data with offline cache fallback.
///
/// Implementations throw [ServerFailure], [NetworkFailure], or [CacheFailure].
abstract class ProductRepository {
  /// Retrieves the full catalog of products (remote-first with Hive cache fallback).
  Future<List<ProductEntity>> getProducts();

  /// Retrieves a single product by its numeric identifier.
  Future<ProductEntity> getProductById(int id);

  /// Retrieves all available product categories.
  Future<List<String>> getCategories();

  /// Retrieves products belonging to a specific [category] slug.
  Future<List<ProductEntity>> getProductsByCategory(String category);
}
