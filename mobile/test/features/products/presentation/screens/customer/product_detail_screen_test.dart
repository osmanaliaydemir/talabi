import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/products/presentation/screens/customer/product_detail_screen.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/reviews/data/models/review.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';

import 'product_detail_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<LoggerService>(),
  MockSpec<CartProvider>(),
])
void main() {
  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;
  late CartProvider cartProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockLoggerService = MockLoggerService();

    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    cartProvider = CartProvider(apiService: mockApiService);
  });

  final testProduct = Product(
    id: 'p1',
    vendorId: 'v1',
    name: 'Test Ürün',
    description: 'Bu bir test ürünü açıklamasıdır.',
    price: 150.0,
    currency: Currency.try_,
    imageUrl: 'https://example.com/p1.jpg',
    vendorName: 'Test Satıcı',
  );

  final testReviewsSummary = ProductReviewsSummary(
    averageRating: 4.5,
    totalRatings: 10,
    totalComments: 5,
    reviews: [],
  );

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr')],
        locale: const Locale('tr'),
        home: ProductDetailScreen(productId: 'p1', product: testProduct),
      ),
    );
  }

  group('ProductDetailScreen Widget Tests', () {
    testWidgets('should render product details correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      when(mockApiService.getFavorites()).thenAnswer(
        (_) async => PagedResultDto<ProductDto>(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          totalPages: 0,
        ),
      );

      when(
        mockApiService.getProductReviews('p1'),
      ).thenAnswer((_) async => testReviewsSummary);

      when(mockApiService.getSimilarProducts('p1')).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Start building
      await tester.pump(); // Handle async loads

      expect(find.text('Test Ürün'), findsAtLeastNWidgets(1));
      expect(find.text('Bu bir test ürünü açıklamasıdır.'), findsOneWidget);
      expect(find.textContaining('150,00'), findsAtLeastNWidgets(1));
      expect(find.text('Test Satıcı'), findsOneWidget);
    });

    testWidgets('should handle quantity changes', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      when(mockApiService.getFavorites()).thenAnswer(
        (_) async => PagedResultDto<ProductDto>(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          totalPages: 0,
        ),
      );

      when(
        mockApiService.getProductReviews('p1'),
      ).thenAnswer((_) async => testReviewsSummary);

      when(mockApiService.getSimilarProducts('p1')).thenAnswer((_) async => []);

      // Mock for addItem
      when(mockApiService.addToCart(any, any)).thenAnswer((_) async => {});
      // Mock for loadCart (initially empty)
      when(mockApiService.getCart()).thenAnswer((_) async => {'items': []});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      // Tap 'Sepete ekle'
      final addToCartFinder = find.textContaining(
        RegExp('sepete ekle', caseSensitive: false),
      );
      expect(addToCartFinder, findsAtLeastNWidgets(1));

      // Update getCart mock for the call inside addItem
      when(mockApiService.getCart()).thenAnswer(
        (_) async => {
          'items': [
            {
              'id': 'ci1',
              'productId': 'p1',
              'productName': 'Test Ürün',
              'productPrice': 150.0,
              'quantity': 1,
              'currency': 1, // TRY
              'vendorId': 'v1',
              'vendorName': 'Test Satıcı',
            },
          ],
        },
      );

      await tester.tap(addToCartFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final incrementButton = find.byIcon(Icons.add);
      expect(incrementButton, findsOneWidget);

      // Mock for increaseQuantity
      when(mockApiService.updateCartItem(any, any)).thenAnswer((_) async => {});
      // Mock for reload after increase
      when(mockApiService.getCart()).thenAnswer(
        (_) async => {
          'items': [
            {
              'id': 'ci1',
              'productId': 'p1',
              'productName': 'Test Ürün',
              'productPrice': 150.0,
              'quantity': 2,
              'currency': 1,
              'vendorId': 'v1',
              'vendorName': 'Test Satıcı',
            },
          ],
        },
      );

      await tester.tap(incrementButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final quantityRow = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: quantityRow, matching: find.text('2')),
        findsOneWidget,
      );

      final decrementButton = find.byIcon(Icons.remove);

      // Mock for reload after decrease
      when(mockApiService.getCart()).thenAnswer(
        (_) async => {
          'items': [
            {
              'id': 'ci1',
              'productId': 'p1',
              'productName': 'Test Ürün',
              'productPrice': 150.0,
              'quantity': 1,
              'currency': 1,
              'vendorId': 'v1',
              'vendorName': 'Test Satıcı',
            },
          ],
        },
      );

      await tester.tap(decrementButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.descendant(of: quantityRow, matching: find.text('1')),
        findsOneWidget,
      );
    });
  });
}
