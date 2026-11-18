import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/errors/failures.dart';
import 'package:e_commerce_shopping_app/domain/entities/product_entity.dart';
import 'package:e_commerce_shopping_app/domain/usecases/product_usecases.dart';
import 'package:e_commerce_shopping_app/domain/usecases/recommendation_usecases.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_state.dart';

class _MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

class _MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class _MockGetCategoryAffinityUseCase extends Mock
    implements GetCategoryAffinityUseCase {}

class _MockTrackCategoryAffinityUseCase extends Mock
    implements TrackCategoryAffinityUseCase {}

void main() {
  late _MockGetProductsUseCase getProducts;
  late _MockGetCategoriesUseCase getCategories;
  late _MockGetCategoryAffinityUseCase getCategoryAffinity;
  late _MockTrackCategoryAffinityUseCase trackCategoryAffinity;

  const p1 = ProductEntity(
    id: 1,
    title: 'Sony Headphones',
    price: 199.99,
    description: 'Noise canceling wireless headphones',
    category: 'electronics',
    image: 'https://example.com/1.png',
    ratingRate: 4.8,
    ratingCount: 320,
  );
  const p2 = ProductEntity(
    id: 2,
    title: 'Gold Micropave Ring',
    price: 168.00,
    description: 'Solid 14K gold ring',
    category: 'jewelery',
    image: 'https://example.com/2.png',
    ratingRate: 4.9,
    ratingCount: 95,
  );
  const p3 = ProductEntity(
    id: 3,
    title: 'USB-C SSD 1TB',
    price: 89.50,
    description: 'Fast portable solid state drive',
    category: 'electronics',
    image: 'https://example.com/3.png',
    ratingRate: 4.5,
    ratingCount: 150,
  );

  final sampleProducts = [p1, p2, p3];
  final sampleCategories = [
    AppConstants.allCategory,
    'electronics',
    'jewelery',
  ];

  setUp(() {
    getProducts = _MockGetProductsUseCase();
    getCategories = _MockGetCategoriesUseCase();
    getCategoryAffinity = _MockGetCategoryAffinityUseCase();
    trackCategoryAffinity = _MockTrackCategoryAffinityUseCase();
  });

  ProductCubit buildCubit() => ProductCubit(
    getProducts: getProducts,
    getCategories: getCategories,
    filterAndSort: const FilterAndSortProductsUseCase(),
    getRecommended: const GetRecommendedProductsUseCase(),
    getCategoryAffinity: getCategoryAffinity,
    trackCategoryAffinity: trackCategoryAffinity,
  );

  group('ProductCubit', () {
    blocTest<ProductCubit, ProductState>(
      'loads catalog, categories, and ranks recommended products by category affinity',
      build: () {
        when(() => getProducts()).thenAnswer((_) async => sampleProducts);
        when(() => getCategories()).thenAnswer((_) async => sampleCategories);
        when(() => getCategoryAffinity('uid-1'))
            .thenAnswer((_) async => {'electronics': 5});
        return buildCubit();
      },
      act: (cubit) => cubit.fetchProductsAndCategories(uid: 'uid-1'),
      expect: () => [
        const ProductLoading(),
        isA<ProductLoaded>()
            .having((s) => s.allProducts.length, 'allProducts', 3)
            .having(
              (s) => s.recommendedProducts.first.category,
              'top recommended category',
              'electronics',
            )
            .having(
              (s) => s.recommendedProducts.first.id,
              'highest rated in top affinity category',
              1,
            ),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'filters by category, searches by keyword, and sorts by price low-to-high',
      build: () {
        when(() => getProducts()).thenAnswer((_) async => sampleProducts);
        when(() => getCategories()).thenAnswer((_) async => sampleCategories);
        when(() => getCategoryAffinity(null)).thenAnswer((_) async => const {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.fetchProductsAndCategories();
        cubit.filterByCategory('electronics');
        cubit.sortProducts(ProductSortOption.priceLowToHigh);
        cubit.searchProducts('ssd');
      },
      verify: (cubit) {
        final state = cubit.state as ProductLoaded;
        expect(state.selectedCategory, 'electronics');
        expect(state.sortOption, ProductSortOption.priceLowToHigh);
        expect(state.filteredProducts, [p3]);
      },
    );

    blocTest<ProductCubit, ProductState>(
      'emits ProductError when catalog fetch fails without offline cache',
      build: () {
        when(() => getProducts()).thenThrow(const NetworkFailure());
        when(() => getCategories()).thenAnswer((_) async => sampleCategories);
        when(() => getCategoryAffinity(null)).thenAnswer((_) async => const {});
        return buildCubit();
      },
      act: (cubit) => cubit.fetchProductsAndCategories(),
      expect: () => [const ProductLoading(), isA<ProductError>()],
    );

    test(
      'getSimilarProducts returns same-category items excluding self',
      () async {
        when(() => getProducts()).thenAnswer((_) async => sampleProducts);
        when(() => getCategories()).thenAnswer((_) async => sampleCategories);
        when(() => getCategoryAffinity(null)).thenAnswer((_) async => const {});

        final cubit = buildCubit();
        await cubit.fetchProductsAndCategories();

        final similar = cubit.getSimilarProducts(p1);
        expect(similar, [p3]);
        await cubit.close();
      },
    );
  });
}
