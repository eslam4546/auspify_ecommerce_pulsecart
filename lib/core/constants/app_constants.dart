/// Centralized API, Hive, Firestore, and commerce business constants for PulseCart.
abstract final class AppConstants {
  // App Identity
  static const String appName = 'PulseCart';

  // FakeStore REST API
  static const String fakeStoreBaseUrl = 'https://fakestoreapi.com';
  static const String productsEndpoint = '/products';
  static const String categoriesEndpoint = '/products/categories';
  static const String productsByCategoryEndpoint = '/products/category';

  static const Duration apiConnectTimeout = Duration(seconds: 15);
  static const Duration apiReceiveTimeout = Duration(seconds: 15);

  // Catalog Category Defaults
  static const String allCategory = 'All';

  // Hive Box Names
  static const String cartBox = 'cart_box';
  static const String ordersBox = 'orders_box';
  static const String productsCacheBox = 'products_cache_box';
  static const String categoriesCacheBox = 'categories_cache_box';
  static const String affinityBox = 'affinity_box';
  static const String settingsBox = 'settings_box';

  // Hive Settings Keys
  static const String themeModeKey = 'theme_mode';
  static const String cachedProductsKey = 'cached_products_list';
  static const String cachedCategoriesKey = 'cached_categories_list';
  static const String categoryAffinityKey = 'category_affinity_map';

  // Cloud Firestore Collections & Fields
  static const String usersCollection = 'users';
  static const String cartSubcollection = 'cart';
  static const String ordersSubcollection = 'orders';
  static const String favoriteCategoriesField = 'favoriteCategories';

  // Checkout & Pricing Rules
  static const double standardShippingFee = 5.99;
  static const double freeShippingThreshold = 100.0;

  // Payment Methods (strictly aligned with firestore.rules)
  static const String paymentCashOnDelivery = 'Cash on Delivery';
  static const String paymentCreditDebitCard = 'Credit/Debit Card';

  // Order Statuses (strictly aligned with firestore.rules)
  static const String orderStatusProcessing = 'Processing';
  static const String orderStatusCompleted = 'Completed';

  /// Calculates shipping fee: free for empty carts or orders >= freeShippingThreshold.
  static double calculateShippingFee(double subtotal) {
    if (subtotal <= 0 || subtotal >= freeShippingThreshold) {
      return 0.0;
    }
    return standardShippingFee;
  }
}
