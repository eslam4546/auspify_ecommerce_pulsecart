import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';

/// Data model for catalog REST API products and Hive local catalog cache.
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.title,
    required super.price,
    required super.description,
    required super.category,
    required super.image,
    required super.ratingRate,
    required super.ratingCount,
  });

  /// Normalizes `cdn.dummyjson.com` `.webp` URLs (which send `no-store` headers
  /// that cause 0-byte cache corruption on Android) into cache-safe JPEG URLs.
  static String normalizeImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('cdn.dummyjson.com') &&
        !trimmed.startsWith('https://wsrv.nl/')) {
      final encoded = Uri.encodeComponent(trimmed);
      return 'https://wsrv.nl/?url=$encoded&output=jpg&w=500&bg=ffffff';
    }
    return trimmed;
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      title: entity.title,
      price: entity.price,
      description: entity.description,
      category: entity.category,
      image: normalizeImageUrl(entity.image),
      ratingRate: entity.ratingRate,
      ratingCount: entity.ratingCount,
    );
  }

  /// Parses both FakeStoreAPI nested `rating` JSON and flat cached JSON maps.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final ratingMap = json['rating'];
    double rate = 0.0;
    int count = 0;

    if (ratingMap is Map) {
      rate = (ratingMap['rate'] as num?)?.toDouble() ?? 0.0;
      count = (ratingMap['count'] as num?)?.toInt() ?? 0;
    } else {
      rate = (json['ratingRate'] as num?)?.toDouble() ?? 0.0;
      count = (json['ratingCount'] as num?)?.toInt() ?? 0;
    }

    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      image: normalizeImageUrl((json['image'] ?? '').toString()),
      ratingRate: rate,
      ratingCount: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': image,
      'rating': {'rate': ratingRate, 'count': ratingCount},
    };
  }
}
