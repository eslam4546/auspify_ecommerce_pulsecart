import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';
import 'package:e_commerce_shopping_app/data/models/product_model.dart';

/// Contract for local Hive caching of FakeStore products and categories.
abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getCachedProducts();

  Future<void> cacheProducts(List<ProductModel> products);

  Future<List<String>> getCachedCategories();

  Future<void> cacheCategories(List<String> categories);
}

/// Hive NoSQL implementation of [ProductLocalDataSource] using JSON serialization.
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final Box<String> _productsBox;
  final Box<String> _categoriesBox;

  const ProductLocalDataSourceImpl({
    required this._productsBox,
    required this._categoriesBox,
  });

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    try {
      final raw = _productsBox.get(AppConstants.cachedProductsKey);
      if (raw == null || raw.isEmpty) {
        throw const CacheException(
          message: 'No cached products available offline.',
        );
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const CacheException(
          message: 'Cached product catalog is corrupted.',
        );
      }

      return decoded
          .whereType<Map>()
          .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(message: 'Failed to read cached products: $e');
    }
  }

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      final encoded = jsonEncode(
        products.map((product) => product.toJson()).toList(),
      );
      await _productsBox.put(AppConstants.cachedProductsKey, encoded);
    } catch (e) {
      throw CacheException(message: 'Failed to cache products locally: $e');
    }
  }

  @override
  Future<List<String>> getCachedCategories() async {
    try {
      final raw = _categoriesBox.get(AppConstants.cachedCategoriesKey);
      if (raw == null || raw.isEmpty) {
        throw const CacheException(
          message: 'No cached categories available offline.',
        );
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const CacheException(
          message: 'Cached categories list is corrupted.',
        );
      }

      return decoded.map((item) => item.toString()).toList();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(message: 'Failed to read cached categories: $e');
    }
  }

  @override
  Future<void> cacheCategories(List<String> categories) async {
    try {
      await _categoriesBox.put(
        AppConstants.cachedCategoriesKey,
        jsonEncode(categories),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache categories locally: $e');
    }
  }
}
