import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vendors/presentation/screens/vendor_detail_screen.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'vendor_detail_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<LoggerService>(),
  MockSpec<CartProvider>(),
])
void main() {
  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;
  late MockCartProvider mockCartProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockLoggerService = MockLoggerService();
    mockCartProvider = MockCartProvider();

    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    when(mockCartProvider.items).thenReturn({});
  });

  final testVendor = Vendor(
    id: 'v1',
    name: 'Test Mağaza',
    imageUrl: 'https://example.com/vendor.jpg',
    address: 'Test Adres',
    rating: 4.8,
  );

  final testProducts = [
    Product(
      id: 'p1',
      vendorId: 'v1',
      name: 'Test Ürün 1',
      price: 50.0,
      imageUrl: 'https://example.com/p1.jpg',
    ),
    Product(
      id: 'p2',
      vendorId: 'v1',
      name: 'Test Ürün 2',
      price: 75.0,
      imageUrl: 'https://example.com/p2.jpg',
    ),
  ];

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>.value(value: mockCartProvider),
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
        home: VendorDetailScreen(vendor: testVendor),
      ),
    );
  }

  group('VendorDetailScreen Widget Tests', () {
    testWidgets('should render vendor details correctly', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getProducts(
          any,
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer((_) async => testProducts);

      when(mockApiService.getFavorites()).thenAnswer(
        (_) async => PagedResultDto<ProductDto>(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          totalPages: 0,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Start building
      await tester.pump(); // Handle futures and first setState

      expect(find.text('Test Mağaza'), findsOneWidget);
      expect(find.textContaining('4.8'), findsOneWidget);
      expect(find.text('Test Adres'), findsOneWidget);

      expect(find.text('Test Ürün 1'), findsOneWidget);
      expect(find.text('Test Ürün 2'), findsOneWidget);
    });

    testWidgets('should show empty state when no products found', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getProducts(
          any,
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer((_) async => []);

      when(mockApiService.getFavorites()).thenAnswer(
        (_) async => PagedResultDto<ProductDto>(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          totalPages: 0,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      expect(find.text('Test Ürün 1'), findsNothing);
      expect(
        find.text('Henüz ürün yok.'),
        findsOneWidget,
      ); // localizations.noProductsYet
    });
  });
}
