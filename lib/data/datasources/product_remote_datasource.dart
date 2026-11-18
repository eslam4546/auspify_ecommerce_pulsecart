import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';
import 'package:e_commerce_shopping_app/core/network/dio_client.dart';
import 'package:e_commerce_shopping_app/data/datasources/mock_catalog_data.dart';
import 'package:e_commerce_shopping_app/data/models/product_model.dart';

/// Contract for fetching product catalog data from remote REST APIs.
abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();

  Future<ProductModel> getProductById(int id);

  Future<List<String>> getCategories();

  Future<List<ProductModel>> getProductsByCategory(String category);
}

/// Concrete [Dio]-backed implementation of [ProductRemoteDataSource].
///
/// Tier 1: Primary FakeStore REST API (`https://fakestoreapi.com`).
/// Tier 2: Automatic live failover to DummyJSON REST API (`https://dummyjson.com`)
/// mapped onto the 4 PRD categories when FakeStoreAPI resets connections or is down.
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  static const String _dummyJsonBaseUrl = 'https://dummyjson.com/products';

  static const Map<String, List<String>> _dummyJsonCategoryMap = {
    'electronics': ['smartphones', 'laptops'],
    'jewelery': ['womens-jewellery'],
    "men's clothing": ['mens-shirts'],
    "women's clothing": ['womens-dresses'],
  };

  final DioClient _dioClient;

  const ProductRemoteDataSourceImpl({required this._dioClient});

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _dioClient.get(AppConstants.productsEndpoint);
      final data = response.data;
      if (data is! List || data.isEmpty) {
        throw const ServerException(
          message: 'Unexpected response format while loading products.',
        );
      }

      return data
          .whereType<Map>()
          .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      // Fail over seamlessly to live DummyJSON REST API when FakeStoreAPI is down.
      return _fetchProductsFromDummyJson();
    }
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _dioClient.get(
        '${AppConstants.productsEndpoint}/$id',
      );
      final data = response.data;
      if (data is! Map) {
        throw const ServerException(
          message: 'Product details could not be parsed from the server.',
        );
      }
      return ProductModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      final response = await _dioClient.get('$_dummyJsonBaseUrl/$id');
      final data = response.data;
      if (data is! Map) {
        throw const ServerException(
          message: 'Product details could not be loaded.',
        );
      }
      return _mapDummyJsonProduct(Map<String, dynamic>.from(data));
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await _dioClient.get(AppConstants.categoriesEndpoint);
      final data = response.data;
      if (data is! List || data.isEmpty) {
        throw const ServerException(
          message: 'Unexpected response format while loading categories.',
        );
      }

      return data
          .map((item) => item.toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (_) {
      // Exact 4 PRD categories backed by the DummyJSON failover feed.
      return List<String>.from(MockCatalogData.defaultCategories);
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final encoded = Uri.encodeComponent(category);
      final response = await _dioClient.get(
        '${AppConstants.productsByCategoryEndpoint}/$encoded',
      );
      final data = response.data;
      if (data is! List) {
        throw const ServerException(
          message:
              'Unexpected response format while loading category products.',
        );
      }

      return data
          .whereType<Map>()
          .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      final normalized = category.trim().toLowerCase();
      final remoteSlugs = _dummyJsonCategoryMap[normalized];
      if (remoteSlugs == null) {
        final all = await _fetchProductsFromDummyJson();
        return all
            .where((p) => p.category.toLowerCase() == normalized)
            .toList();
      }
      return _fetchDummyJsonSlugs(remoteSlugs, targetCategory: normalized);
    }
  }

  Future<List<ProductModel>> _fetchProductsFromDummyJson() async {
    final futures = <Future<List<ProductModel>>>[
      for (final entry in _dummyJsonCategoryMap.entries)
        _fetchDummyJsonSlugs(entry.value, targetCategory: entry.key),
    ];

    final grouped = await Future.wait(futures);
    final combined = <ProductModel>[for (final list in grouped) ...list];

    if (combined.isEmpty) {
      throw const ServerException(
        message: 'Secondary catalog API returned no products.',
      );
    }
    return combined;
  }

  Future<List<ProductModel>> _fetchDummyJsonSlugs(
    List<String> slugs, {
    required String targetCategory,
  }) async {
    final results = <ProductModel>[];
    for (final slug in slugs) {
      final response = await _dioClient.get(
        '$_dummyJsonBaseUrl/category/$slug',
        queryParameters: const {'limit': 5},
      );
      final data = response.data;
      if (data is Map && data['products'] is List) {
        final rawProducts = data['products'] as List;
        for (final raw in rawProducts.whereType<Map>()) {
          results.add(
            _mapDummyJsonProduct(
              Map<String, dynamic>.from(raw),
              overrideCategory: targetCategory,
            ),
          );
        }
      }
    }
    return results;
  }

  ProductModel _mapDummyJsonProduct(
    Map<String, dynamic> json, {
    String? overrideCategory,
  }) {
    final images = json['images'];
    final firstImage = (images is List && images.isNotEmpty)
        ? images.first.toString()
        : '';
    final thumbnail = (json['thumbnail'] ?? '').toString();
    final imageUrl = thumbnail.isNotEmpty ? thumbnail : firstImage;

    final reviews = json['reviews'];
    final stock = (json['stock'] as num?)?.toInt() ?? 45;
    final ratingCount = (reviews is List && reviews.isNotEmpty)
        ? reviews.length * 24
        : stock * 3;

    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: (json['description'] ?? '').toString(),
      category:
          overrideCategory ?? (json['category'] ?? 'electronics').toString(),
      image: ProductModel.normalizeImageUrl(imageUrl),
      ratingRate: ((json['rating'] as num?)?.toDouble() ?? 4.5).clamp(1.0, 5.0),
      ratingCount: ratingCount.clamp(12, 999),
    );
  }
}
