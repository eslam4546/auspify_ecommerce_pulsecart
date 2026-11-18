import 'package:uuid/uuid.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/exceptions.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/data/datasources/cart_order_local_datasource.dart';
import 'package:e_commerce_shopping_app/data/datasources/cart_order_remote_datasource.dart';
import 'package:e_commerce_shopping_app/data/models/cart_order_models.dart';
import 'package:e_commerce_shopping_app/data/models/product_model.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/repositories/cart_order_repository.dart';

/// Hybrid Offline/Cloud implementation of [CartOrderRepository].
///
/// Every cart mutation writes instantaneously to Hive for zero-latency offline UX,
/// then synchronizes with Cloud Firestore (`users/{uid}/cart`, `users/{uid}/orders`,
/// and `users/{uid}.favoriteCategories`) without blocking offline users.
class CartOrderRepositoryImpl implements CartOrderRepository {
  final CartOrderLocalDataSource _localDataSource;
  final CartOrderRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  const CartOrderRepositoryImpl({
    required this._localDataSource,
    required this._remoteDataSource,
    this._uuid = const Uuid(),
  });

  @override
  Future<List<CartItemEntity>> getLocalCart() async {
    try {
      return await _localDataSource.getCartItems();
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<List<CartItemEntity>> syncCart(String? uid) async {
    final localItems = await _safeGetLocalCart();
    if (uid == null || uid.isEmpty) {
      return localItems;
    }

    try {
      final remoteItems = await _remoteDataSource.fetchCart(uid);

      final localById = <int, CartItemModel>{
        for (final item in localItems) item.product.id: item,
      };
      final remoteById = <int, CartItemModel>{
        for (final item in remoteItems) item.product.id: item,
      };

      final merged = <int, CartItemModel>{};
      final toPushRemote = <CartItemModel>[];

      final allIds = <int>{...localById.keys, ...remoteById.keys};
      for (final id in allIds) {
        final local = localById[id];
        final remote = remoteById[id];

        if (local != null && remote == null) {
          merged[id] = local;
          toPushRemote.add(local);
        } else if (remote != null && local == null) {
          merged[id] = remote;
        } else if (local != null && remote != null) {
          // Keep the most recently updated entry while preserving richer local product metadata.
          final preferred = local.updatedAt.isAfter(remote.updatedAt)
              ? local
              : CartItemModel(
                  product: remote.product.description.isNotEmpty
                      ? remote.product
                      : local.product,
                  quantity: remote.quantity,
                  updatedAt: remote.updatedAt,
                );
          merged[id] = preferred;
          if (local.updatedAt.isAfter(remote.updatedAt) &&
              local.quantity != remote.quantity) {
            toPushRemote.add(preferred);
          }
        }
      }

      final mergedList = merged.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      await _localDataSource.saveAllCartItems(mergedList);

      for (final item in toPushRemote) {
        try {
          await _remoteDataSource.upsertCartItem(uid, item);
        } catch (_) {
          // Continue syncing remaining items if a single cloud write fails.
        }
      }

      return mergedList;
    } catch (_) {
      // Offline or Firestore unavailable: continue seamlessly with local Hive cart.
      return localItems;
    }
  }

  @override
  Future<List<CartItemEntity>> addToCart({
    required ProductEntity product,
    int quantity = 1,
    String? uid,
  }) async {
    try {
      final current = await _localDataSource.getCartItems();
      final existingIndex = current.indexWhere(
        (item) => item.product.id == product.id,
      );

      final nextQuantity = existingIndex >= 0
          ? (current[existingIndex].quantity + quantity).clamp(1, 999)
          : quantity.clamp(1, 999);

      final updatedItem = CartItemModel(
        product: ProductModel.fromEntity(product),
        quantity: nextQuantity,
        updatedAt: DateTime.now(),
      );

      await _localDataSource.upsertCartItem(updatedItem);
      await _localDataSource.incrementCategoryAffinity(
        product.category,
        weight: 1,
      );

      if (uid != null && uid.isNotEmpty) {
        try {
          await _remoteDataSource.upsertCartItem(uid, updatedItem);
          await _remoteDataSource.incrementCategoryAffinity(
            uid,
            product.category,
            weight: 1,
          );
        } catch (_) {
          // Local Hive state is already updated; cloud sync will reconcile later.
        }
      }

      return await _localDataSource.getCartItems();
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<List<CartItemEntity>> updateQuantity({
    required int productId,
    required int quantity,
    String? uid,
  }) async {
    if (quantity <= 0) {
      return removeFromCart(productId: productId, uid: uid);
    }

    try {
      final current = await _localDataSource.getCartItems();
      final existingIndex = current.indexWhere(
        (item) => item.product.id == productId,
      );
      if (existingIndex < 0) return current;

      final updatedItem = CartItemModel(
        product: ProductModel.fromEntity(current[existingIndex].product),
        quantity: quantity.clamp(1, 999),
        updatedAt: DateTime.now(),
      );

      await _localDataSource.upsertCartItem(updatedItem);

      if (uid != null && uid.isNotEmpty) {
        try {
          await _remoteDataSource.upsertCartItem(uid, updatedItem);
        } catch (_) {
          // Preserve offline resilience.
        }
      }

      return await _localDataSource.getCartItems();
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<List<CartItemEntity>> removeFromCart({
    required int productId,
    String? uid,
  }) async {
    try {
      await _localDataSource.removeCartItem(productId);

      if (uid != null && uid.isNotEmpty) {
        try {
          await _remoteDataSource.removeCartItem(uid, productId);
        } catch (_) {
          // Preserve offline resilience.
        }
      }

      return await _localDataSource.getCartItems();
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<void> clearCart({String? uid, bool clearRemote = false}) async {
    try {
      await _localDataSource.clearCart();
      if (clearRemote && uid != null && uid.isNotEmpty) {
        try {
          await _remoteDataSource.clearCart(uid);
        } catch (_) {
          // Ignore transient remote errors when clearing cart.
        }
      }
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<OrderEntity> placeOrder({
    required List<CartItemEntity> items,
    required ShippingAddressEntity shippingAddress,
    required String paymentMethod,
    String? uid,
  }) async {
    try {
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final shippingFee = AppConstants.calculateShippingFee(subtotal);
      final totalAmount = subtotal + shippingFee;

      final order = OrderModel(
        orderId: _uuid.v4(),
        items: items.map((e) => CartItemModel.fromEntity(e)).toList(),
        subtotal: double.parse(subtotal.toStringAsFixed(2)),
        shippingFee: double.parse(shippingFee.toStringAsFixed(2)),
        totalAmount: double.parse(totalAmount.toStringAsFixed(2)),
        paymentMethod: paymentMethod,
        shippingAddress: shippingAddress,
        status: AppConstants.orderStatusProcessing,
        createdAt: DateTime.now(),
      );

      // Persist locally first so the order is never lost offline.
      await _localDataSource.saveOrder(order);

      // Boost category affinity for purchased categories.
      final categoryWeights = <String, int>{};
      for (final item in items) {
        final slug = item.product.category.trim().toLowerCase();
        if (slug.isNotEmpty) {
          categoryWeights[slug] = (categoryWeights[slug] ?? 0) + 2;
        }
      }
      for (final entry in categoryWeights.entries) {
        await _localDataSource.incrementCategoryAffinity(
          entry.key,
          weight: entry.value,
        );
      }

      // Sync order & category telemetry to Cloud Firestore when authenticated.
      if (uid != null && uid.isNotEmpty) {
        try {
          await _remoteDataSource.createOrder(uid, order);
          for (final entry in categoryWeights.entries) {
            await _remoteDataSource.incrementCategoryAffinity(
              uid,
              entry.key,
              weight: entry.value,
            );
          }
          await _remoteDataSource.clearCart(uid);
        } catch (_) {
          // Order is safely stored locally in Hive even if cloud sync is offline.
        }
      }

      await _localDataSource.clearCart();
      return order;
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<List<OrderEntity>> getOrderHistory(String? uid) async {
    final localOrders = await _safeGetLocalOrders();
    if (uid == null || uid.isEmpty) {
      return localOrders;
    }

    try {
      final remoteOrders = await _remoteDataSource.fetchOrders(uid);
      final mergedById = <String, OrderModel>{
        for (final order in localOrders) order.orderId: order,
        for (final order in remoteOrders) order.orderId: order,
      };
      final mergedList = mergedById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      await _localDataSource.saveAllOrders(mergedList);
      return mergedList;
    } catch (_) {
      return localOrders;
    }
  }

  @override
  Future<Map<String, int>> getCategoryAffinity(String? uid) async {
    final localScores = await _safeGetLocalAffinity();
    if (uid == null || uid.isEmpty) {
      return localScores;
    }

    try {
      final remoteScores = await _remoteDataSource.fetchCategoryAffinity(uid);
      final merged = Map<String, int>.from(localScores);
      remoteScores.forEach((category, score) {
        final current = merged[category] ?? 0;
        merged[category] = score > current ? score : current;
      });
      await _localDataSource.saveCategoryAffinity(merged);
      return merged;
    } catch (_) {
      return localScores;
    }
  }

  @override
  Future<Map<String, int>> trackCategoryAffinity({
    required String category,
    int weight = 1,
    String? uid,
  }) async {
    final updated = await _localDataSource.incrementCategoryAffinity(
      category,
      weight: weight,
    );
    if (uid != null && uid.isNotEmpty) {
      try {
        await _remoteDataSource.incrementCategoryAffinity(
          uid,
          category,
          weight: weight,
        );
      } catch (_) {
        // Ignore offline errors when tracking recommendation telemetry.
      }
    }
    return updated;
  }

  Future<List<CartItemModel>> _safeGetLocalCart() async {
    try {
      return await _localDataSource.getCartItems();
    } catch (_) {
      return <CartItemModel>[];
    }
  }

  Future<List<OrderModel>> _safeGetLocalOrders() async {
    try {
      return await _localDataSource.getOrders();
    } catch (_) {
      return <OrderModel>[];
    }
  }

  Future<Map<String, int>> _safeGetLocalAffinity() async {
    try {
      return await _localDataSource.getCategoryAffinity();
    } catch (_) {
      return <String, int>{};
    }
  }
}
