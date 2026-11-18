import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';
import 'package:e_commerce_shopping_app/data/models/cart_order_models.dart';

/// Contract for instant offline Hive persistence of cart, orders, and category affinity.
abstract class CartOrderLocalDataSource {
  Future<List<CartItemModel>> getCartItems();

  Future<void> upsertCartItem(CartItemModel item);

  Future<void> saveAllCartItems(List<CartItemModel> items);

  Future<void> removeCartItem(int productId);

  Future<void> clearCart();

  Future<List<OrderModel>> getOrders();

  Future<void> saveOrder(OrderModel order);

  Future<void> saveAllOrders(List<OrderModel> orders);

  Future<Map<String, int>> getCategoryAffinity();

  Future<void> saveCategoryAffinity(Map<String, int> scores);

  Future<Map<String, int>> incrementCategoryAffinity(
    String category, {
    int weight = 1,
  });
}

/// Hive NoSQL implementation of [CartOrderLocalDataSource] using JSON serialization.
class CartOrderLocalDataSourceImpl implements CartOrderLocalDataSource {
  final Box<String> _cartBox;
  final Box<String> _ordersBox;
  final Box<String> _affinityBox;

  const CartOrderLocalDataSourceImpl({
    required this._cartBox,
    required this._ordersBox,
    required this._affinityBox,
  });

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      final items = <CartItemModel>[];
      for (final raw in _cartBox.values) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          items.add(
            CartItemModel.fromHiveJson(Map<String, dynamic>.from(decoded)),
          );
        }
      }
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } catch (e) {
      throw CacheException(message: 'Failed to read local cart: $e');
    }
  }

  @override
  Future<void> upsertCartItem(CartItemModel item) async {
    try {
      await _cartBox.put(
        item.product.id.toString(),
        jsonEncode(item.toHiveJson()),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save cart item locally: $e');
    }
  }

  @override
  Future<void> saveAllCartItems(List<CartItemModel> items) async {
    try {
      await _cartBox.clear();
      final entries = <String, String>{
        for (final item in items)
          item.product.id.toString(): jsonEncode(item.toHiveJson()),
      };
      await _cartBox.putAll(entries);
    } catch (e) {
      throw CacheException(message: 'Failed to sync local cart box: $e');
    }
  }

  @override
  Future<void> removeCartItem(int productId) async {
    try {
      await _cartBox.delete(productId.toString());
    } catch (e) {
      throw CacheException(message: 'Failed to remove local cart item: $e');
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await _cartBox.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear local cart: $e');
    }
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final orders = <OrderModel>[];
      for (final raw in _ordersBox.values) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          orders.add(
            OrderModel.fromHiveJson(Map<String, dynamic>.from(decoded)),
          );
        }
      }
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw CacheException(message: 'Failed to read local order history: $e');
    }
  }

  @override
  Future<void> saveOrder(OrderModel order) async {
    try {
      await _ordersBox.put(order.orderId, jsonEncode(order.toHiveJson()));
    } catch (e) {
      throw CacheException(message: 'Failed to save order locally: $e');
    }
  }

  @override
  Future<void> saveAllOrders(List<OrderModel> orders) async {
    try {
      final entries = <String, String>{
        for (final order in orders)
          order.orderId: jsonEncode(order.toHiveJson()),
      };
      await _ordersBox.putAll(entries);
    } catch (e) {
      throw CacheException(message: 'Failed to cache order history: $e');
    }
  }

  @override
  Future<Map<String, int>> getCategoryAffinity() async {
    try {
      final raw = _affinityBox.get(AppConstants.categoryAffinityKey);
      if (raw == null || raw.isEmpty) return <String, int>{};

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};

      final result = <String, int>{};
      decoded.forEach((key, value) {
        final count = (value as num?)?.toInt() ?? 0;
        if (count > 0) {
          result[key.toString()] = count;
        }
      });
      return result;
    } catch (e) {
      throw CacheException(message: 'Failed to read category affinity: $e');
    }
  }

  @override
  Future<void> saveCategoryAffinity(Map<String, int> scores) async {
    try {
      await _affinityBox.put(
        AppConstants.categoryAffinityKey,
        jsonEncode(scores),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to save category affinity: $e');
    }
  }

  @override
  Future<Map<String, int>> incrementCategoryAffinity(
    String category, {
    int weight = 1,
  }) async {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty || weight <= 0) {
      return getCategoryAffinity();
    }

    final current = await getCategoryAffinity();
    current[normalized] = (current[normalized] ?? 0) + weight;
    await saveCategoryAffinity(current);
    return current;
  }
}
