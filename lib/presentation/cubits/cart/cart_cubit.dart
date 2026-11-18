import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/usecases/cart_order_usecases.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';

/// Cubit managing the hybrid Hive + Cloud Firestore shopping cart,
/// price breakdown calculations, order history, and simulated checkout.
class CartCubit extends Cubit<CartState> {
  final GetLocalCartUseCase _getLocalCart;
  final SyncCartUseCase _syncCart;
  final AddToCartUseCase _addToCart;
  final UpdateCartQuantityUseCase _updateCartQuantity;
  final RemoveFromCartUseCase _removeFromCart;
  final ClearCartUseCase _clearCart;
  final CheckoutOrderUseCase _checkoutOrder;
  final GetOrderHistoryUseCase _getOrderHistory;

  String? _activeUid;

  CartCubit({
    required this._getLocalCart,
    required this._syncCart,
    required this._addToCart,
    required this._updateCartQuantity,
    required this._removeFromCart,
    required this._clearCart,
    required this._checkoutOrder,
    required this._getOrderHistory,
  }) : super(const CartInitial());

  List<CartItemEntity> get _currentItems {
    final current = state;
    return current is CartLoaded ? current.items : const [];
  }

  List<OrderEntity> get _currentOrders {
    final current = state;
    return current is CartLoaded ? current.orders : const [];
  }

  /// Hydrates cart immediately from Hive, then merges with Cloud Firestore
  /// and fetches order history for [uid].
  Future<void> loadCart({String? uid}) async {
    if (uid != null) {
      _activeUid = uid;
    }

    if (state is CartInitial) {
      emit(const CartLoading());
    }

    try {
      // Step 1: Instant offline Hive read for zero perceived latency.
      final localItems = await _getLocalCart();
      emit(
        CartLoaded.fromItems(
          items: localItems,
          orders: _currentOrders,
          isSyncing: _activeUid != null,
        ),
      );

      // Step 2: Background Cloud Firestore merge + order history hydration.
      final syncedItems = await _syncCart(_activeUid);
      final orders = await _getOrderHistory(_activeUid);

      emit(
        CartLoaded.fromItems(
          items: syncedItems,
          orders: orders,
          isSyncing: false,
        ),
      );
    } on Failure catch (failure) {
      emit(CartError(failure.message));
    } catch (_) {
      emit(const CartError('Unable to load your shopping cart.'));
    }
  }

  /// Adds [product] with [quantity] to Hive & Firestore and refreshes cart totals.
  Future<void> addToCart(
    ProductEntity product, {
    int quantity = 1,
    String? uid,
  }) async {
    final effectiveUid = uid ?? _activeUid;
    try {
      final updatedItems = await _addToCart(
        product: product,
        quantity: quantity,
        uid: effectiveUid,
      );
      emit(CartLoaded.fromItems(items: updatedItems, orders: _currentOrders));
    } on Failure catch (failure) {
      _emitActionError(failure.message);
    } catch (_) {
      _emitActionError('Failed to add item to cart.');
    }
  }

  /// Updates quantity of [productId] or removes it if `quantity <= 0`.
  Future<void> updateQuantity(
    int productId,
    int quantity, {
    String? uid,
  }) async {
    final effectiveUid = uid ?? _activeUid;
    try {
      final updatedItems = await _updateCartQuantity(
        productId: productId,
        quantity: quantity,
        uid: effectiveUid,
      );
      emit(CartLoaded.fromItems(items: updatedItems, orders: _currentOrders));
    } on Failure catch (failure) {
      _emitActionError(failure.message);
    } catch (_) {
      _emitActionError('Failed to update item quantity.');
    }
  }

  /// Removes [productId] from both Hive and Cloud Firestore.
  Future<void> removeFromCart(int productId, {String? uid}) async {
    final effectiveUid = uid ?? _activeUid;
    try {
      final updatedItems = await _removeFromCart(
        productId: productId,
        uid: effectiveUid,
      );
      emit(CartLoaded.fromItems(items: updatedItems, orders: _currentOrders));
    } on Failure catch (failure) {
      _emitActionError(failure.message);
    } catch (_) {
      _emitActionError('Failed to remove item from cart.');
    }
  }

  /// Executes simulated checkout, saves the order to Hive + Firestore, clears the cart,
  /// and returns the created [OrderEntity] on success (or `null` on failure).
  Future<OrderEntity?> checkoutOrder({
    required ShippingAddressEntity shippingAddress,
    required String paymentMethod,
    String? uid,
  }) async {
    final effectiveUid = uid ?? _activeUid;
    final items = _currentItems;
    final existingOrders = _currentOrders;

    emit(
      CartLoaded.fromItems(
        items: items,
        orders: existingOrders,
        isCheckingOut: true,
      ),
    );

    try {
      final createdOrder = await _checkoutOrder(
        items: items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        uid: effectiveUid,
      );

      final updatedOrders = <OrderEntity>[
        createdOrder,
        ...existingOrders.where((o) => o.orderId != createdOrder.orderId),
      ];

      emit(
        CartLoaded.fromItems(
          items: const [],
          orders: updatedOrders,
          isCheckingOut: false,
          lastCompletedOrder: createdOrder,
        ),
      );
      return createdOrder;
    } on Failure catch (failure) {
      emit(
        CartLoaded.fromItems(
          items: items,
          orders: existingOrders,
          isCheckingOut: false,
          actionError: failure.message,
        ),
      );
      return null;
    } catch (_) {
      emit(
        CartLoaded.fromItems(
          items: items,
          orders: existingOrders,
          isCheckingOut: false,
          actionError: 'Checkout failed. Please try again.',
        ),
      );
      return null;
    }
  }

  /// Refreshes order history from Hive + Cloud Firestore.
  Future<void> loadOrderHistory({String? uid}) async {
    final effectiveUid = uid ?? _activeUid;
    try {
      final orders = await _getOrderHistory(effectiveUid);
      emit(CartLoaded.fromItems(items: _currentItems, orders: orders));
    } catch (_) {
      // Keep existing orders visible if offline refresh fails.
    }
  }

  /// Clears the one-shot [CartLoaded.lastCompletedOrder] flag after the confirmation dialog is shown.
  void clearLastCompletedOrder() {
    final current = state;
    if (current is CartLoaded && current.lastCompletedOrder != null) {
      emit(current.copyWith(clearLastCompletedOrder: true));
    }
  }

  /// Resets local session cart state on sign-out without deleting cloud cart data.
  Future<void> resetOnSignOut() async {
    _activeUid = null;
    try {
      await _clearCart(clearRemote: false);
    } catch (_) {
      // Ignore cache clear failure during sign-out.
    }
    emit(CartLoaded.fromItems(items: const [], orders: const []));
  }

  void _emitActionError(String message) {
    final current = state;
    if (current is CartLoaded) {
      emit(current.copyWith(actionError: message));
    } else {
      emit(CartError(message));
    }
  }
}
