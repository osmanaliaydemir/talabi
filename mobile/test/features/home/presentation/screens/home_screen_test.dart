import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/presentation/screens/home_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/features/home/data/models/promotional_banner.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mobile/features/search/data/models/search_dtos.dart';

import 'home_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<LoggerService>(),
  MockSpec<NotificationProvider>(),
  MockSpec<CartProvider>(),
])
class FakeBottomNavProvider extends BottomNavProvider {}

void main() {
  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;
  late FakeBottomNavProvider fakeBottomNavProvider;
  late MockNotificationProvider mockNotificationProvider;
  late MockCartProvider mockCartProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockLoggerService = MockLoggerService();
    fakeBottomNavProvider = FakeBottomNavProvider();
    mockNotificationProvider = MockNotificationProvider();
    mockCartProvider = MockCartProvider();

    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    // Default mock behaviors
    when(mockNotificationProvider.unreadCount).thenReturn(0);
  });

  final testVendors = [
    Vendor(
      id: 'v1',
      name: 'Test Restaurant',
      imageUrl: 'https://example.com/v1.jpg',
      rating: 4.5,
      address: 'Test Address',
      city: 'Istanbul',
    ),
  ];

  final testProducts = [
    Product(
      id: 'p1',
      vendorId: 'v1',
      name: 'Test Product',
      price: 50.0,
      currency: Currency.try_,
      imageUrl: 'https://example.com/p1.jpg',
      vendorName: 'Test Restaurant',
    ),
  ];

  final testCategories = [
    {'id': 'c1', 'name': 'Pizza', 'imageUrl': 'https://example.com/c1.jpg'},
  ];

  final testBanners = [
    PromotionalBanner(
      id: 'b1',
      title: 'Promo 1',
      subtitle: 'Subtitle 1',
      imageUrl: 'https://example.com/b1.jpg',
      displayOrder: 1,
      isActive: true,
    ),
  ];

  final testAddresses = [
    {
      'id': 'a1',
      'title': 'Ev',
      'city': 'Istanbul',
      'district': 'Besiktas',
      'isDefault': true,
    },
  ];

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr')],
      locale: const Locale('tr'),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<BottomNavProvider>.value(
            value: fakeBottomNavProvider,
          ),
          ChangeNotifierProvider<NotificationProvider>.value(
            value: mockNotificationProvider,
          ),
          ChangeNotifierProvider<CartProvider>.value(value: mockCartProvider),
        ],
        child: const HomeScreen(),
      ),
    );
  }

  testWidgets('çalışması için api verilerinin yüklenmesi ve render edilmesi', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    // Setup mocks for data loading
    when(
      mockApiService.getVendors(vendorType: anyNamed('vendorType')),
    ).thenAnswer((_) async => testVendors);
    when(
      mockApiService.getPopularProducts(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        vendorType: anyNamed('vendorType'),
      ),
    ).thenAnswer((_) async => testProducts);
    when(
      mockApiService.getCategories(
        language: anyNamed('language'),
        vendorType: anyNamed('vendorType'),
      ),
    ).thenAnswer((_) async => testCategories);
    when(
      mockApiService.getBanners(
        language: anyNamed('language'),
        vendorType: anyNamed('vendorType'),
      ),
    ).thenAnswer((_) async => testBanners);
    when(mockApiService.getAddresses()).thenAnswer((_) async => testAddresses);
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
    await tester.pump(); // Initial build

    // Wait for async background data loading
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(); // Final build after data

    // Verify address is displayed
    expect(find.text('Besiktas, Istanbul'), findsAtLeastNWidgets(1));

    // Verify sections are visible
    expect(find.text('Test Restaurant'), findsOneWidget);
    expect(find.text('Test Product'), findsOneWidget);
  });

  testWidgets(
    'alt navigasyondan kategori değiştiğinde verilerin yeniden yüklenmesi',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      // Initial behavior: Restaurant (default)

      // API setup
      when(
        mockApiService.getVendors(vendorType: anyNamed('vendorType')),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.getPopularProducts(
          vendorType: anyNamed('vendorType'),
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.getCategories(
          vendorType: anyNamed('vendorType'),
          language: anyNamed('language'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.getBanners(
          vendorType: anyNamed('vendorType'),
          language: anyNamed('language'),
        ),
      ).thenAnswer((_) async => []);
      when(mockApiService.getAddresses()).thenAnswer((_) async => []);
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
      await tester.pumpAndSettle();

      // Change category to Market (vendorType 2)
      fakeBottomNavProvider.setCategory(MainCategory.market);

      // _onCategoryChanged has a delay of 300ms
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Verify API was called with vendorType: 2
      verify(
        mockApiService.getVendors(vendorType: 2),
      ).called(greaterThanOrEqualTo(1));
    },
  );

  testWidgets(
    'ürün kartında favori butonuna basıldığında API çağrısı yapılması',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      when(
        mockApiService.getVendors(vendorType: anyNamed('vendorType')),
      ).thenAnswer((_) async => testVendors);
      when(
        mockApiService.getPopularProducts(
          vendorType: anyNamed('vendorType'),
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer((_) async => testProducts);
      when(
        mockApiService.getCategories(
          vendorType: anyNamed('vendorType'),
          language: anyNamed('language'),
        ),
      ).thenAnswer((_) async => testCategories);
      when(
        mockApiService.getBanners(
          vendorType: anyNamed('vendorType'),
          language: anyNamed('language'),
        ),
      ).thenAnswer((_) async => testBanners);
      when(
        mockApiService.getAddresses(),
      ).thenAnswer((_) async => testAddresses);
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
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Find favorite button (it's a GestureDetector inside ProductCard)
      // We can look for the icon heart
      final favoriteButton = find.byIcon(Icons.favorite_border);
      expect(favoriteButton, findsOneWidget);

      await tester.tap(favoriteButton);
      await tester.pump();

      // Verify API called to add to favorites
      verify(mockApiService.addToFavorites('p1')).called(1);
    },
  );
}
