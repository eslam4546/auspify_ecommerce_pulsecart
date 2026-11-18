import 'package:equatable/equatable.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';

/// Domain entity representing a single line item in the user's shopping cart.
class CartItemEntity extends Equatable {
  final ProductEntity product;
  final int quantity;

  const CartItemEntity({required this.product, required this.quantity});

  double get totalPrice => product.price * quantity;

  CartItemEntity copyWith({ProductEntity? product, int? quantity}) {
    return CartItemEntity(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

/// Value object capturing structured shipping details matching Firestore ERD.
class ShippingAddressEntity extends Equatable {
  final String fullName;
  final String phone;
  final String street;
  final String city;

  const ShippingAddressEntity({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
  });

  /// Human-readable single-line shipping summary for order history display.
  String get formatted => '$fullName, $street, $city ($phone)';

  Map<String, String> toMap() {
    return {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'street': street.trim(),
      'city': city.trim(),
    };
  }

  factory ShippingAddressEntity.fromMap(Map<String, dynamic> map) {
    return ShippingAddressEntity(
      fullName: (map['fullName'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      street: (map['street'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [fullName, phone, street, city];
}

/// Domain entity representing a placed checkout order.
class OrderEntity extends Equatable {
  final String orderId;
  final List<CartItemEntity> items;
  final double subtotal;
  final double shippingFee;
  final double totalAmount;
  final String paymentMethod;
  final ShippingAddressEntity shippingAddress;
  final String status;
  final DateTime createdAt;

  const OrderEntity({
    required this.orderId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.status,
    required this.createdAt,
  });

  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [
    orderId,
    items,
    subtotal,
    shippingFee,
    totalAmount,
    paymentMethod,
    shippingAddress,
    status,
    createdAt,
  ];
}
