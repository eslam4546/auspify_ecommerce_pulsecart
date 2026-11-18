import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/data/models/product_model.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';

/// Data model for a hybrid cart item stored in Hive (`cart_box`) and Firestore (`users/{uid}/cart/{productId}`).
class CartItemModel extends CartItemEntity {
  final DateTime updatedAt;

  CartItemModel({
    required super.product,
    required super.quantity,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory CartItemModel.fromEntity(
    CartItemEntity entity, {
    DateTime? updatedAt,
  }) {
    return CartItemModel(
      product: ProductModel.fromEntity(entity.product),
      quantity: entity.quantity,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Parses a Hive JSON map (which preserves full product metadata including rating & description).
  factory CartItemModel.fromHiveJson(Map<String, dynamic> json) {
    final productJson = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : <String, dynamic>{
            'id': json['productId'] ?? 0,
            'title': json['title'] ?? '',
            'price': json['price'] ?? 0.0,
            'description': json['description'] ?? '',
            'category': json['category'] ?? '',
            'image': json['image'] ?? '',
            'ratingRate': json['ratingRate'] ?? 0.0,
            'ratingCount': json['ratingCount'] ?? 0,
          };

    final rawUpdatedAt = json['updatedAt'];
    final parsedUpdatedAt = rawUpdatedAt is String
        ? (DateTime.tryParse(rawUpdatedAt) ?? DateTime.now())
        : DateTime.now();

    return CartItemModel(
      product: ProductModel.fromJson(productJson),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Converts to a JSON-encodable map for Hive `cart_box`.
  Map<String, dynamic> toHiveJson() {
    return {
      'product': ProductModel.fromEntity(product).toJson(),
      'quantity': quantity,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Parses a Firestore `users/{uid}/cart/{productId}` document.
  factory CartItemModel.fromFirestore(Map<String, dynamic> map) {
    final rawUpdatedAt = map['updatedAt'];
    final parsedUpdatedAt = rawUpdatedAt is Timestamp
        ? rawUpdatedAt.toDate()
        : (rawUpdatedAt is String
              ? (DateTime.tryParse(rawUpdatedAt) ?? DateTime.now())
              : DateTime.now());

    return CartItemModel(
      product: ProductModel(
        id: (map['productId'] as num?)?.toInt() ?? 0,
        title: (map['title'] ?? '').toString(),
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        description: (map['description'] ?? '').toString(),
        category: (map['category'] ?? '').toString(),
        image: (map['image'] ?? '').toString(),
        ratingRate: (map['ratingRate'] as num?)?.toDouble() ?? 0.0,
        ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      ),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Converts to Firestore map strictly conforming to `firestore.rules` (`isValidCartItem` 7-field allowlist).
  Map<String, dynamic> toFirestoreMap() {
    return {
      'productId': product.id,
      'title': product.title,
      'price': product.price,
      'image': product.image,
      'category': product.category,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Serialized snapshot item stored inside an order's `items` array.
  Map<String, dynamic> toOrderItemMap() {
    return {
      'productId': product.id,
      'title': product.title,
      'price': product.price,
      'image': product.image,
      'category': product.category,
      'quantity': quantity,
    };
  }
}

/// Data model for placed orders stored in Hive (`orders_box`) and Firestore (`users/{uid}/orders/{orderId}`).
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.orderId,
    required super.items,
    required super.subtotal,
    required super.shippingFee,
    required super.totalAmount,
    required super.paymentMethod,
    required super.shippingAddress,
    required super.status,
    required super.createdAt,
  });

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      orderId: entity.orderId,
      items: entity.items
          .map((item) => CartItemModel.fromEntity(item))
          .toList(),
      subtotal: entity.subtotal,
      shippingFee: entity.shippingFee,
      totalAmount: entity.totalAmount,
      paymentMethod: entity.paymentMethod,
      shippingAddress: entity.shippingAddress,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }

  /// Parses an order from Hive JSON.
  factory OrderModel.fromHiveJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    final parsedItems = rawItems
        .whereType<Map>()
        .map((e) => CartItemModel.fromHiveJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawAddress = json['shippingAddress'];
    final address = rawAddress is Map
        ? ShippingAddressEntity.fromMap(Map<String, dynamic>.from(rawAddress))
        : const ShippingAddressEntity(
            fullName: '',
            phone: '',
            street: '',
            city: '',
          );

    final rawDate = json['createdAt'];
    final createdAt = rawDate is String
        ? (DateTime.tryParse(rawDate) ?? DateTime.now())
        : DateTime.now();

    return OrderModel(
      orderId: (json['orderId'] ?? '').toString(),
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount:
          (json['totalPrice'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      paymentMethod:
          (json['paymentMethod'] ?? AppConstants.paymentCashOnDelivery)
              .toString(),
      shippingAddress: address,
      status: (json['status'] ?? AppConstants.orderStatusProcessing).toString(),
      createdAt: createdAt,
    );
  }

  /// Converts to a JSON-encodable map for Hive `orders_box`.
  Map<String, dynamic> toHiveJson() {
    return {
      'orderId': orderId,
      'items': items
          .map((item) => CartItemModel.fromEntity(item).toHiveJson())
          .toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'totalPrice': totalAmount,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress.toMap(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Parses an order from Cloud Firestore `users/{uid}/orders/{orderId}`.
  factory OrderModel.fromFirestore(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List?) ?? const [];
    final parsedItems = rawItems
        .whereType<Map>()
        .map((e) => CartItemModel.fromFirestore(Map<String, dynamic>.from(e)))
        .toList();

    final rawAddress = map['shippingAddress'];
    final address = rawAddress is Map
        ? ShippingAddressEntity.fromMap(Map<String, dynamic>.from(rawAddress))
        : const ShippingAddressEntity(
            fullName: '',
            phone: '',
            street: '',
            city: '',
          );

    final rawDate = map['createdAt'];
    final createdAt = rawDate is Timestamp
        ? rawDate.toDate()
        : (rawDate is String
              ? (DateTime.tryParse(rawDate) ?? DateTime.now())
              : DateTime.now());

    return OrderModel(
      orderId: (map['orderId'] ?? '').toString(),
      items: parsedItems,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentMethod:
          (map['paymentMethod'] ?? AppConstants.paymentCashOnDelivery)
              .toString(),
      shippingAddress: address,
      status: (map['status'] ?? AppConstants.orderStatusProcessing).toString(),
      createdAt: createdAt,
    );
  }

  /// Converts to Firestore map strictly conforming to `firestore.rules` (`isValidOrder` 9-field allowlist).
  Map<String, dynamic> toFirestoreMap() {
    return {
      'orderId': orderId,
      'items': items
          .map((item) => CartItemModel.fromEntity(item).toOrderItemMap())
          .toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'totalPrice': totalAmount,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}
