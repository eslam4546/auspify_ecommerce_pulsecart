import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';

/// Contract for hybrid offline (Hive) + cloud (Firestore) cart, checkout,
/// order history, and category affinity tracking.
abstract class CartOrderRepository {
  /// Immediately returns locally cached Hive cart items for zero-latency UI startup.
  Future<List<CartItemEntity>> getLocalCart();

  /// Syncs local Hive cart with Cloud Firestore `users/{uid}/cart` and returns merged items.
  Future<List<CartItemEntity>> syncCart(String? uid);

  /// Adds [product] with [quantity] to Hive immediately and syncs to Firestore + category affinity.
  Future<List<CartItemEntity>> addToCart({
    required ProductEntity product,
    int quantity = 1,
    String? uid,
  });

  /// Updates the quantity of [productId] (or removes if `quantity <= 0`).
  Future<List<CartItemEntity>> updateQuantity({
    required int productId,
    required int quantity,
    String? uid,
  });

  /// Removes [productId] from both Hive and Firestore.
  Future<List<CartItemEntity>> removeFromCart({
    required int productId,
    String? uid,
  });

  /// Clears all items from the local cart (and optionally Firestore if [clearRemote] is true).
  Future<void> clearCart({String? uid, bool clearRemote = false});

  /// Creates an [OrderEntity], persists to Hive + Firestore, updates category affinity,
  /// and empties the active cart.
  Future<OrderEntity> placeOrder({
    required List<CartItemEntity> items,
    required ShippingAddressEntity shippingAddress,
    required String paymentMethod,
    String? uid,
  });

  /// Retrieves order history merged across Hive and Firestore (newest first).
  Future<List<OrderEntity>> getOrderHistory(String? uid);

  /// Retrieves per-category interaction counts powering "Recommended for You".
  Future<Map<String, int>> getCategoryAffinity(String? uid);

  /// Increments affinity score for [category] in Hive and Firestore.
  Future<Map<String, int>> trackCategoryAffinity({
    required String category,
    int weight = 1,
    String? uid,
  });
}
