import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';

/// Data model for FakeStore REST API products and Hive local catalog cache.
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

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      title: entity.title,
      price: entity.price,
      description: entity.description,
      category: entity.category,
      image: entity.image,
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
      image: (json['image'] ?? '').toString(),
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
