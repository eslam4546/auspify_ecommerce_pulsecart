import 'package:equatable/equatable.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';

/// Base state for [CartCubit].
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

/// Initial state before local Hive cart is loaded.
class CartInitial extends CartState {
  const CartInitial();
}

/// Emitted during initial cart hydration.
class CartLoading extends CartState {
  const CartLoading();
}

/// Active cart & order history state with computed price breakdown.
class CartLoaded extends CartState {
  final List<CartItemEntity> items;
  final List<OrderEntity> orders;
  final double subtotal;
  final double shippingFee;
  final double grandTotal;
  final bool isSyncing;
  final bool isCheckingOut;
  final OrderEntity? lastCompletedOrder;
  final String? actionError;

  const CartLoaded({
    required this.items,
    required this.orders,
    required this.subtotal,
    required this.shippingFee,
    required this.grandTotal,
    this.isSyncing = false,
    this.isCheckingOut = false,
    this.lastCompletedOrder,
    this.actionError,
  });

  /// Factory computing `subtotal`, `shippingFee`, and `grandTotal` deterministically.
  factory CartLoaded.fromItems({
    required List<CartItemEntity> items,
    List<OrderEntity> orders = const [],
    bool isSyncing = false,
    bool isCheckingOut = false,
    OrderEntity? lastCompletedOrder,
    String? actionError,
  }) {
    final rawSubtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final subtotal = double.parse(rawSubtotal.toStringAsFixed(2));
    final shippingFee = double.parse(
      AppConstants.calculateShippingFee(subtotal).toStringAsFixed(2),
    );
    final grandTotal = double.parse(
      (subtotal + shippingFee).toStringAsFixed(2),
    );

    return CartLoaded(
      items: List<CartItemEntity>.unmodifiable(items),
      orders: List<OrderEntity>.unmodifiable(orders),
      subtotal: subtotal,
      shippingFee: shippingFee,
      grandTotal: grandTotal,
      isSyncing: isSyncing,
      isCheckingOut: isCheckingOut,
      lastCompletedOrder: lastCompletedOrder,
      actionError: actionError,
    );
  }

  /// Total unit quantity across all cart line items (drives bottom bar badge).
  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  /// Remaining spend needed to unlock free shipping.
  double get amountUntilFreeShipping {
    if (subtotal <= 0 || subtotal >= AppConstants.freeShippingThreshold) {
      return 0.0;
    }
    return double.parse(
      (AppConstants.freeShippingThreshold - subtotal).toStringAsFixed(2),
    );
  }

  CartLoaded copyWith({
    List<CartItemEntity>? items,
    List<OrderEntity>? orders,
    bool? isSyncing,
    bool? isCheckingOut,
    OrderEntity? lastCompletedOrder,
    bool clearLastCompletedOrder = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return CartLoaded.fromItems(
      items: items ?? this.items,
      orders: orders ?? this.orders,
      isSyncing: isSyncing ?? this.isSyncing,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      lastCompletedOrder: clearLastCompletedOrder
          ? null
          : (lastCompletedOrder ?? this.lastCompletedOrder),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    items,
    orders,
    subtotal,
    shippingFee,
    grandTotal,
    isSyncing,
    isCheckingOut,
    lastCompletedOrder,
    actionError,
  ];
}

/// Emitted if local Hive cart hydration fails critically.
class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
