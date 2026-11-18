import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';
import 'package:e_commerce_shopping_app/data/models/cart_order_models.dart';

/// Contract for Cloud Firestore synchronization of cart items, orders,
/// and user category affinity telemetry.
abstract class CartOrderRemoteDataSource {
  Future<List<CartItemModel>> fetchCart(String uid);

  Future<void> upsertCartItem(String uid, CartItemModel item);

  Future<void> removeCartItem(String uid, int productId);

  Future<void> clearCart(String uid);

  Future<void> createOrder(String uid, OrderModel order);

  Future<List<OrderModel>> fetchOrders(String uid);

  Future<Map<String, int>> fetchCategoryAffinity(String uid);

  Future<void> incrementCategoryAffinity(
    String uid,
    String category, {
    int weight = 1,
  });
}

/// Cloud Firestore implementation of [CartOrderRemoteDataSource].
class CartOrderRemoteDataSourceImpl implements CartOrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  const CartOrderRemoteDataSourceImpl({required this._firestore});

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection(AppConstants.usersCollection).doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _cartCollection(String uid) {
    return _userDoc(uid).collection(AppConstants.cartSubcollection);
  }

  CollectionReference<Map<String, dynamic>> _ordersCollection(String uid) {
    return _userDoc(uid).collection(AppConstants.ordersSubcollection);
  }

  @override
  Future<List<CartItemModel>> fetchCart(String uid) async {
    try {
      final snapshot = await _cartCollection(uid).get();
      final items = snapshot.docs
          .map((doc) => CartItemModel.fromFirestore(doc.data()))
          .toList();
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch cloud cart.',
      );
    }
  }

  @override
  Future<void> upsertCartItem(String uid, CartItemModel item) async {
    try {
      await _cartCollection(uid)
          .doc(item.product.id.toString())
          .set(item.toFirestoreMap());
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to sync cart item to Firestore.',
      );
    }
  }

  @override
  Future<void> removeCartItem(String uid, int productId) async {
    try {
      await _cartCollection(uid).doc(productId.toString()).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to remove cart item from Firestore.',
      );
    }
  }

  @override
  Future<void> clearCart(String uid) async {
    try {
      final snapshot = await _cartCollection(uid).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to clear cloud cart.',
      );
    }
  }

  @override
  Future<void> createOrder(String uid, OrderModel order) async {
    try {
      await _ordersCollection(uid)
          .doc(order.orderId)
          .set(order.toFirestoreMap());
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to save order to Firestore.',
      );
    }
  }

  @override
  Future<List<OrderModel>> fetchOrders(String uid) async {
    try {
      final snapshot = await _ordersCollection(uid)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load cloud order history.',
      );
    }
  }

  @override
  Future<Map<String, int>> fetchCategoryAffinity(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      final data = doc.data();
      if (data == null) return <String, int>{};

      final rawMap = data[AppConstants.favoriteCategoriesField];
      if (rawMap is! Map) return <String, int>{};

      final scores = <String, int>{};
      rawMap.forEach((key, value) {
        final count = (value as num?)?.toInt() ?? 0;
        if (count > 0) {
          scores[key.toString().trim().toLowerCase()] = count;
        }
      });
      return scores;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load category recommendations.',
      );
    }
  }

  @override
  Future<void> incrementCategoryAffinity(
    String uid,
    String category, {
    int weight = 1,
  }) async {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty || weight <= 0) return;

    try {
      await _userDoc(uid).update({
        FieldPath([AppConstants.favoriteCategoriesField, normalized]):
            FieldValue.increment(weight),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update category affinity.',
      );
    }
  }
}
