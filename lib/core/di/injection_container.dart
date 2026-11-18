import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/network/dio_client.dart';
import 'package:e_commerce_shopping_app/data/datasources/auth_remote_datasource.dart';
import 'package:e_commerce_shopping_app/data/datasources/cart_order_local_datasource.dart';
import 'package:e_commerce_shopping_app/data/datasources/cart_order_remote_datasource.dart';
import 'package:e_commerce_shopping_app/data/datasources/product_local_datasource.dart';
import 'package:e_commerce_shopping_app/data/datasources/product_remote_datasource.dart';
import 'package:e_commerce_shopping_app/data/repositories/auth_repository_impl.dart';
import 'package:e_commerce_shopping_app/data/repositories/cart_order_repository_impl.dart';
import 'package:e_commerce_shopping_app/data/repositories/product_repository_impl.dart';
import 'package:e_commerce_shopping_app/domain/repositories/auth_repository.dart';
import 'package:e_commerce_shopping_app/domain/repositories/cart_order_repository.dart';
import 'package:e_commerce_shopping_app/domain/repositories/product_repository.dart';
import 'package:e_commerce_shopping_app/domain/usecases/auth_usecases.dart';
import 'package:e_commerce_shopping_app/domain/usecases/cart_order_usecases.dart';
import 'package:e_commerce_shopping_app/domain/usecases/product_usecases.dart';
import 'package:e_commerce_shopping_app/domain/usecases/recommendation_usecases.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/theme/theme_cubit.dart';

/// Zero-dependency, compile-time type-safe Dependency Injection container for PulseCart.
class AppDependencies {
  final Box<String> settingsBox;
  final AuthRepository authRepository;
  final ProductRepository productRepository;
  final CartOrderRepository cartOrderRepository;

  // Auth UseCases
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final SignInWithEmailUseCase signInWithEmailUseCase;
  final SignUpWithEmailUseCase signUpWithEmailUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignOutUseCase signOutUseCase;

  // Product UseCases
  final GetProductsUseCase getProductsUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final FilterAndSortProductsUseCase filterAndSortProductsUseCase;

  // Cart, Order & Recommendation UseCases
  final GetLocalCartUseCase getLocalCartUseCase;
  final SyncCartUseCase syncCartUseCase;
  final AddToCartUseCase addToCartUseCase;
  final UpdateCartQuantityUseCase updateCartQuantityUseCase;
  final RemoveFromCartUseCase removeFromCartUseCase;
  final ClearCartUseCase clearCartUseCase;
  final CheckoutOrderUseCase checkoutOrderUseCase;
  final GetOrderHistoryUseCase getOrderHistoryUseCase;
  final GetRecommendedProductsUseCase getRecommendedProductsUseCase;
  final GetCategoryAffinityUseCase getCategoryAffinityUseCase;
  final TrackCategoryAffinityUseCase trackCategoryAffinityUseCase;

  const AppDependencies._({
    required this.settingsBox,
    required this.authRepository,
    required this.productRepository,
    required this.cartOrderRepository,
    required this.checkAuthStatusUseCase,
    required this.signInWithEmailUseCase,
    required this.signUpWithEmailUseCase,
    required this.signInWithGoogleUseCase,
    required this.signOutUseCase,
    required this.getProductsUseCase,
    required this.getCategoriesUseCase,
    required this.filterAndSortProductsUseCase,
    required this.getLocalCartUseCase,
    required this.syncCartUseCase,
    required this.addToCartUseCase,
    required this.updateCartQuantityUseCase,
    required this.removeFromCartUseCase,
    required this.clearCartUseCase,
    required this.checkoutOrderUseCase,
    required this.getOrderHistoryUseCase,
    required this.getRecommendedProductsUseCase,
    required this.getCategoryAffinityUseCase,
    required this.trackCategoryAffinityUseCase,
  });

  /// Initializes Hive boxes and assembles the full Clean Architecture object graph.
  static Future<AppDependencies> init() async {
    await Hive.initFlutter();

    final boxes = await Future.wait<Box<String>>([
      Hive.openBox<String>(AppConstants.cartBox),
      Hive.openBox<String>(AppConstants.ordersBox),
      Hive.openBox<String>(AppConstants.productsCacheBox),
      Hive.openBox<String>(AppConstants.categoriesCacheBox),
      Hive.openBox<String>(AppConstants.affinityBox),
      Hive.openBox<String>(AppConstants.settingsBox),
    ]);

    final cartBox = boxes[0];
    final ordersBox = boxes[1];
    final productsCacheBox = boxes[2];
    final categoriesCacheBox = boxes[3];
    final affinityBox = boxes[4];
    final settingsBox = boxes[5];

    // External services & HTTP client
    final firebaseAuth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final googleSignIn = GoogleSignIn();
    final dioClient = DioClient();

    // DataSources
    final authRemoteDataSource = AuthRemoteDataSourceImpl(
      firebaseAuth: firebaseAuth,
      googleSignIn: googleSignIn,
      firestore: firestore,
    );

    final productRemoteDataSource = ProductRemoteDataSourceImpl(
      dioClient: dioClient,
    );
    final productLocalDataSource = ProductLocalDataSourceImpl(
      productsBox: productsCacheBox,
      categoriesBox: categoriesCacheBox,
    );

    final cartOrderLocalDataSource = CartOrderLocalDataSourceImpl(
      cartBox: cartBox,
      ordersBox: ordersBox,
      affinityBox: affinityBox,
    );
    final cartOrderRemoteDataSource = CartOrderRemoteDataSourceImpl(
      firestore: firestore,
    );

    // Repositories
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
    );
    final productRepository = ProductRepositoryImpl(
      remoteDataSource: productRemoteDataSource,
      localDataSource: productLocalDataSource,
    );
    final cartOrderRepository = CartOrderRepositoryImpl(
      localDataSource: cartOrderLocalDataSource,
      remoteDataSource: cartOrderRemoteDataSource,
    );

    return AppDependencies._(
      settingsBox: settingsBox,
      authRepository: authRepository,
      productRepository: productRepository,
      cartOrderRepository: cartOrderRepository,
      checkAuthStatusUseCase: CheckAuthStatusUseCase(authRepository),
      signInWithEmailUseCase: SignInWithEmailUseCase(authRepository),
      signUpWithEmailUseCase: SignUpWithEmailUseCase(authRepository),
      signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
      signOutUseCase: SignOutUseCase(authRepository),
      getProductsUseCase: GetProductsUseCase(productRepository),
      getCategoriesUseCase: GetCategoriesUseCase(productRepository),
      filterAndSortProductsUseCase: const FilterAndSortProductsUseCase(),
      getLocalCartUseCase: GetLocalCartUseCase(cartOrderRepository),
      syncCartUseCase: SyncCartUseCase(cartOrderRepository),
      addToCartUseCase: AddToCartUseCase(cartOrderRepository),
      updateCartQuantityUseCase: UpdateCartQuantityUseCase(cartOrderRepository),
      removeFromCartUseCase: RemoveFromCartUseCase(cartOrderRepository),
      clearCartUseCase: ClearCartUseCase(cartOrderRepository),
      checkoutOrderUseCase: CheckoutOrderUseCase(cartOrderRepository),
      getOrderHistoryUseCase: GetOrderHistoryUseCase(cartOrderRepository),
      getRecommendedProductsUseCase: const GetRecommendedProductsUseCase(),
      getCategoryAffinityUseCase: GetCategoryAffinityUseCase(
        cartOrderRepository,
      ),
      trackCategoryAffinityUseCase: TrackCategoryAffinityUseCase(
        cartOrderRepository,
      ),
    );
  }

  ThemeCubit createThemeCubit() => ThemeCubit(settingsBox: settingsBox);

  AuthCubit createAuthCubit() => AuthCubit(
    checkAuthStatus: checkAuthStatusUseCase,
    signInWithEmail: signInWithEmailUseCase,
    signUpWithEmail: signUpWithEmailUseCase,
    signInWithGoogle: signInWithGoogleUseCase,
    signOut: signOutUseCase,
  );

  ProductCubit createProductCubit() => ProductCubit(
    getProducts: getProductsUseCase,
    getCategories: getCategoriesUseCase,
    filterAndSort: filterAndSortProductsUseCase,
    getRecommended: getRecommendedProductsUseCase,
    getCategoryAffinity: getCategoryAffinityUseCase,
    trackCategoryAffinity: trackCategoryAffinityUseCase,
  );

  CartCubit createCartCubit() => CartCubit(
    getLocalCart: getLocalCartUseCase,
    syncCart: syncCartUseCase,
    addToCart: addToCartUseCase,
    updateCartQuantity: updateCartQuantityUseCase,
    removeFromCart: removeFromCartUseCase,
    clearCart: clearCartUseCase,
    checkoutOrder: checkoutOrderUseCase,
    getOrderHistory: getOrderHistoryUseCase,
  );
}
