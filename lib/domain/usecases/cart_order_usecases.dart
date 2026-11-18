import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/repositories/cart_order_repository.dart';

/// Loads cached cart items immediately from local Hive storage.
class GetLocalCartUseCase {
  final CartOrderRepository _repository;

  const GetLocalCartUseCase(this._repository);

  Future<List<CartItemEntity>> call() => _repository.getLocalCart();
}

/// Merges and synchronizes the local Hive cart with Cloud Firestore for [uid].
class SyncCartUseCase {
  final CartOrderRepository _repository;

  const SyncCartUseCase(this._repository);

  Future<List<CartItemEntity>> call(String? uid) => _repository.syncCart(uid);
}

/// Adds [product] with [quantity] to the hybrid cart and records category affinity.
class AddToCartUseCase {
  final CartOrderRepository _repository;

  const AddToCartUseCase(this._repository);

  Future<List<CartItemEntity>> call({
    required ProductEntity product,
    int quantity = 1,
    String? uid,
  }) {
    if (quantity <= 0) {
      throw const ValidationFailure('Quantity must be at least 1.');
    }
    return _repository.addToCart(
      product: product,
      quantity: quantity,
      uid: uid,
    );
  }
}

/// Updates the quantity of an existing cart item (removes if `quantity <= 0`).
class UpdateCartQuantityUseCase {
  final CartOrderRepository _repository;

  const UpdateCartQuantityUseCase(this._repository);

  Future<List<CartItemEntity>> call({
    required int productId,
    required int quantity,
    String? uid,
  }) {
    return _repository.updateQuantity(
      productId: productId,
      quantity: quantity,
      uid: uid,
    );
  }
}

/// Removes a product from both local Hive and Cloud Firestore carts.
class RemoveFromCartUseCase {
  final CartOrderRepository _repository;

  const RemoveFromCartUseCase(this._repository);

  Future<List<CartItemEntity>> call({required int productId, String? uid}) {
    return _repository.removeFromCart(productId: productId, uid: uid);
  }
}

/// Clears local cart items (e.g., on sign-out) and optionally remote Firestore items.
class ClearCartUseCase {
  final CartOrderRepository _repository;

  const ClearCartUseCase(this._repository);

  Future<void> call({String? uid, bool clearRemote = false}) {
    return _repository.clearCart(uid: uid, clearRemote: clearRemote);
  }
}

/// Validates checkout inputs and submits an order to Hive + Firestore.
class CheckoutOrderUseCase {
  final CartOrderRepository _repository;

  const CheckoutOrderUseCase(this._repository);

  Future<OrderEntity> call({
    required List<CartItemEntity> items,
    required ShippingAddressEntity shippingAddress,
    required String paymentMethod,
    String? uid,
  }) {
    if (items.isEmpty) {
      throw const ValidationFailure('Your shopping cart is empty.');
    }
    if (shippingAddress.fullName.trim().isEmpty ||
        shippingAddress.phone.trim().isEmpty ||
        shippingAddress.street.trim().isEmpty ||
        shippingAddress.city.trim().isEmpty) {
      throw const ValidationFailure(
        'Please complete all shipping address fields.',
      );
    }
    const validPaymentMethods = {
      AppConstants.paymentCashOnDelivery,
      AppConstants.paymentCreditDebitCard,
    };
    if (!validPaymentMethods.contains(paymentMethod)) {
      throw const ValidationFailure('Please select a valid payment method.');
    }

    return _repository.placeOrder(
      items: items,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      uid: uid,
    );
  }
}

/// Retrieves the user's completed order history (newest first).
class GetOrderHistoryUseCase {
  final CartOrderRepository _repository;

  const GetOrderHistoryUseCase(this._repository);

  Future<List<OrderEntity>> call(String? uid) =>
      _repository.getOrderHistory(uid);
}
