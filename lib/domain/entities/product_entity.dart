import 'package:equatable/equatable.dart';

/// Sort modes supported by the PulseCart product catalog and search engine.
enum ProductSortOption {
  relevance('Featured'),
  priceLowToHigh('Price: Low to High'),
  priceHighToLow('Price: High to Low'),
  topRated('Top Rated');

  final String label;
  const ProductSortOption(this.label);
}

/// Domain entity representing a product from the catalog.
class ProductEntity extends Equatable {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final double ratingRate;
  final int ratingCount;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.ratingRate,
    required this.ratingCount,
  });

  /// Returns a formatted display label for the product's category slug.
  String get formattedCategory {
    if (category.isEmpty) return '';
    return category
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  ProductEntity copyWith({
    int? id,
    String? title,
    double? price,
    String? description,
    String? category,
    String? image,
    double? ratingRate,
    int? ratingCount,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      ratingRate: ratingRate ?? this.ratingRate,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    price,
    description,
    category,
    image,
    ratingRate,
    ratingCount,
  ];
}
