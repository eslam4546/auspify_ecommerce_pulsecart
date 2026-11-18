import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/data/datasources/mock_catalog_data.dart';
import 'package:e_commerce_shopping_app/data/datasources/product_local_datasource.dart';
import 'package:e_commerce_shopping_app/data/datasources/product_remote_datasource.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/repositories/product_repository.dart';

/// Concrete implementation of [ProductRepository] with 3-tier resilience:
/// 1. Live Remote REST API (FakeStoreAPI -> automatic DummyJSON failover)
/// 2. Local Hive offline cache (`products_cache_box` / `categories_cache_box`)
/// 3. Bundled [MockCatalogData] fallback if completely offline on first launch
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;

  const ProductRepositoryImpl({
    required this._remoteDataSource,
    required this._localDataSource,
  });

  @override
  Future<List<ProductEntity>> getProducts() async {
    try {
      final remoteProducts = await _remoteDataSource.getProducts();
      try {
        await _localDataSource.cacheProducts(remoteProducts);
      } catch (_) {
        // Ignore local cache write errors when remote fetch succeeded.
      }
      return remoteProducts;
    } on NetworkException {
      return _fallbackCachedOrBundledProducts();
    } on ServerException {
      return _fallbackCachedOrBundledProducts();
    }
  }

  @override
  Future<ProductEntity> getProductById(int id) async {
    try {
      return await _remoteDataSource.getProductById(id);
    } on NetworkException catch (e) {
      return _fallbackSingleProduct(id, NetworkFailure(e.message));
    } on ServerException catch (e) {
      return _fallbackSingleProduct(
        id,
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final remoteCategories = await _remoteDataSource.getCategories();
      try {
        await _localDataSource.cacheCategories(remoteCategories);
      } catch (_) {
        // Ignore cache write errors when remote fetch succeeded.
      }
      return remoteCategories;
    } on NetworkException {
      return _fallbackCachedOrBundledCategories();
    } on ServerException {
      return _fallbackCachedOrBundledCategories();
    }
  }

  @override
  Future<List<ProductEntity>> getProductsByCategory(String category) async {
    try {
      return await _remoteDataSource.getProductsByCategory(category);
    } on NetworkException {
      final fallback = await _fallbackCachedOrBundledProducts();
      return fallback
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
    } on ServerException {
      final fallback = await _fallbackCachedOrBundledProducts();
      return fallback
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
  }

  Future<List<ProductEntity>> _fallbackCachedOrBundledProducts() async {
    try {
      final cached = await _localDataSource.getCachedProducts();
      if (cached.isNotEmpty) return cached;
    } on CacheException {
      // Cache empty on first offline boot — fall through to bundled catalog.
    }

    try {
      await _localDataSource.cacheProducts(MockCatalogData.fallbackProducts);
    } catch (_) {
      // Ignore cache seed error.
    }
    return MockCatalogData.fallbackProducts;
  }

  Future<ProductEntity> _fallbackSingleProduct(
    int id,
    Failure originalFailure,
  ) async {
    final products = await _fallbackCachedOrBundledProducts();
    for (final product in products) {
      if (product.id == id) return product;
    }
    throw originalFailure;
  }

  Future<List<String>> _fallbackCachedOrBundledCategories() async {
    try {
      final cached = await _localDataSource.getCachedCategories();
      if (cached.isNotEmpty) return cached;
    } on CacheException {
      // Cache empty — fall through to default PRD categories.
    }

    try {
      await _localDataSource.cacheCategories(MockCatalogData.defaultCategories);
    } catch (_) {
      // Ignore cache seed error.
    }
    return MockCatalogData.defaultCategories;
  }
}
