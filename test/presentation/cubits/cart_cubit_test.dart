import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/usecases/cart_order_usecases.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';

class _MockGetLocalCartUseCase extends Mock implements GetLocalCartUseCase {}

class _MockSyncCartUseCase extends Mock implements SyncCartUseCase {}

class _MockAddToCartUseCase extends Mock implements AddToCartUseCase {}

class _MockUpdateCartQuantityUseCase extends Mock
    implements UpdateCartQuantityUseCase {}

class _MockRemoveFromCartUseCase extends Mock
    implements RemoveFromCartUseCase {}

class _MockClearCartUseCase extends Mock implements ClearCartUseCase {}

class _MockCheckoutOrderUseCase extends Mock implements CheckoutOrderUseCase {}

class _MockGetOrderHistoryUseCase extends Mock
    implements GetOrderHistoryUseCase {}

void main() {
  late _MockGetLocalCartUseCase getLocalCart;
  late _MockSyncCartUseCase syncCart;
  late _MockAddToCartUseCase addToCart;
  late _MockUpdateCartQuantityUseCase updateCartQuantity;
  late _MockRemoveFromCartUseCase removeFromCart;
  late _MockClearCartUseCase clearCart;
  late _MockCheckoutOrderUseCase checkoutOrder;
  late _MockGetOrderHistoryUseCase getOrderHistory;

  const productA = ProductEntity(
    id: 10,
    title: 'Slim Fit T-Shirt',
    price: 40.0,
    description: 'Cotton tee',
    category: "men's clothing",
    image: 'https://example.com/shirt.png',
    ratingRate: 4.5,
    ratingCount: 100,
  );

  const testAddress = ShippingAddressEntity(
    fullName: 'Alex Rivera',
    phone: '+15551234567',
    street: '742 Evergreen Terrace',
    city: 'Springfield',
  );

  setUpAll(() {
    registerFallbackValue(productA);
    registerFallbackValue(testAddress);
  });

  setUp(() {
    getLocalCart = _MockGetLocalCartUseCase();
    syncCart = _MockSyncCartUseCase();
    addToCart = _MockAddToCartUseCase();
    updateCartQuantity = _MockUpdateCartQuantityUseCase();
    removeFromCart = _MockRemoveFromCartUseCase();
    clearCart = _MockClearCartUseCase();
    checkoutOrder = _MockCheckoutOrderUseCase();
    getOrderHistory = _MockGetOrderHistoryUseCase();
  });

  CartCubit buildCubit() => CartCubit(
    getLocalCart: getLocalCart,
    syncCart: syncCart,
    addToCart: addToCart,
    updateCartQuantity: updateCartQuantity,
    removeFromCart: removeFromCart,
    clearCart: clearCart,
    checkoutOrder: checkoutOrder,
    getOrderHistory: getOrderHistory,
  );

  group('CartCubit', () {
    blocTest<CartCubit, CartState>(
      'calculates subtotal, shipping fee (< \$100), and grandTotal accurately on addToCart',
      build: () {
        when(
          () => addToCart(product: productA, quantity: 2, uid: 'uid-1'),
        ).thenAnswer(
          (_) async => const [CartItemEntity(product: productA, quantity: 2)],
        );
        return buildCubit();
      },
      act: (cubit) => cubit.addToCart(productA, quantity: 2, uid: 'uid-1'),
      expect: () => [
        isA<CartLoaded>()
            .having((s) => s.subtotal, 'subtotal', 80.0)
            .having(
              (s) => s.shippingFee,
              'shippingFee',
              AppConstants.standardShippingFee,
            )
            .having(
              (s) => s.grandTotal,
              'grandTotal',
              80.0 + AppConstants.standardShippingFee,
            )
            .having((s) => s.totalItemCount, 'totalItemCount', 2),
      ],
    );

    blocTest<CartCubit, CartState>(
      'unlocks free shipping when subtotal reaches >= \$100',
      build: () {
        when(
          () => updateCartQuantity(
            productId: productA.id,
            quantity: 3,
            uid: 'uid-1',
          ),
        ).thenAnswer(
          (_) async => const [CartItemEntity(product: productA, quantity: 3)],
        );
        return buildCubit();
      },
      act: (cubit) => cubit.updateQuantity(productA.id, 3, uid: 'uid-1'),
      expect: () => [
        isA<CartLoaded>()
            .having((s) => s.subtotal, 'subtotal', 120.0)
            .having((s) => s.shippingFee, 'shippingFee', 0.0)
            .having((s) => s.grandTotal, 'grandTotal', 120.0),
      ],
    );

    blocTest<CartCubit, CartState>(
      'places checkout order, clears cart, and prepends order to history',
      build: () {
        const cartItems = [CartItemEntity(product: productA, quantity: 3)];
        final createdOrder = OrderEntity(
          orderId: 'order-abc-123',
          items: cartItems,
          subtotal: 120.0,
          shippingFee: 0.0,
          totalAmount: 120.0,
          paymentMethod: AppConstants.paymentCashOnDelivery,
          shippingAddress: testAddress,
          status: AppConstants.orderStatusProcessing,
          createdAt: DateTime(2026, 11, 18),
        );

        when(() => addToCart(product: productA, quantity: 3, uid: 'uid-1'))
            .thenAnswer((_) async => cartItems);

        when(
          () => checkoutOrder(
            items: cartItems,
            shippingAddress: testAddress,
            paymentMethod: AppConstants.paymentCashOnDelivery,
            uid: 'uid-1',
          ),
        ).thenAnswer((_) async => createdOrder);

        return buildCubit();
      },
      act: (cubit) async {
        await cubit.addToCart(productA, quantity: 3, uid: 'uid-1');
        await cubit.checkoutOrder(
          shippingAddress: testAddress,
          paymentMethod: AppConstants.paymentCashOnDelivery,
          uid: 'uid-1',
        );
      },
      verify: (cubit) {
        final state = cubit.state as CartLoaded;
        expect(state.isEmpty, isTrue);
        expect(state.orders.length, 1);
        expect(state.orders.first.orderId, 'order-abc-123');
        expect(state.lastCompletedOrder?.orderId, 'order-abc-123');
      },
    );
  });
}
