import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/onboarding/presentation/screens/main_navigation_screen.dart';
import 'package:mobile/features/home/presentation/screens/home_screen.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/features/search/presentation/screens/search_screen.dart';
import 'package:mobile/features/products/presentation/screens/customer/product_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/orders/data/models/order.dart';
import 'package:mobile/features/reviews/data/models/review.dart';
import 'package:mobile/features/orders/presentation/screens/customer/order_success_screen.dart';

// Create a new mock file for this test
import 'order_flow_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ApiService>(), MockSpec<LoggerService>()])
void main() {
  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;

  // Real Providers
  late CartProvider cartProvider;
  late AuthProvider authProvider;
  late BottomNavProvider bottomNavProvider;
  late ThemeProvider themeProvider;
  late NotificationProvider notificationProvider;
  late LocalizationProvider localizationProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockLoggerService = MockLoggerService();

    // Register mocks
    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    // Initialize Providers with Mock ApiService
    // We need to be careful if AuthProvider uses SecureStorage.
    // Ideally we mock SecureStorage too, or just mock the ApiService calls it makes.
    // For this E2E, let's assume valid token is somehow "Simulated" or we just Mock `getProfile` to return success
    // and rely on the fact that we can manually set state in Providers if needed,
    // OR we just use `ChangeNotifierProvider.value` with real instances that are hydrated.

    // Actually, constructing AuthProvider might try to read SecureStorage.
    // Let's assume we can constructor inject or it uses a singleton instance we can't easily swap without GetIt.
    // Looking at AuthProvider code earlier:
    // AuthProvider({ApiService? apiService, SecureStorageService? secureStorage})
    // So we can inject mocks! Excellent.

    // We will just use the real providers but with the Mock API.
    authProvider = AuthProvider(apiService: mockApiService);
    // We might need to mock SecureStorage if AuthProvider reads it in constructor/init.
    // But let's try without first or minimal mock if needed.

    cartProvider = CartProvider(apiService: mockApiService);
    bottomNavProvider = BottomNavProvider();

    // ThemeProvider might read SharedPreferences.
    // We should probably mock SharedPreferences.getInstance() globally if possible or inject.
    // ThemeProvider() constructor calls _loadSettings().

    // Global SharedPreferences Mock
    // SharedPreferences.setMockInitialValues({});
    // (We'll do this in the test body or setup)

    themeProvider = ThemeProvider();
    notificationProvider = NotificationProvider();
    localizationProvider = LocalizationProvider();

    ToastMessage.isTestMode = true;
    AnalyticsService.isTestMode = true;
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ChangeNotifierProvider<BottomNavProvider>.value(
          value: bottomNavProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(FakeConnectivityService()),
        ),
        ChangeNotifierProvider<LocalizationProvider>.value(
          value: localizationProvider,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Talabi',
            debugShowCheckedModeBanner: false,
            // Theme setup not critical for logic, but helpful for finding widgets
            theme: ThemeData.light(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('tr')],
            locale: const Locale('tr'),
            // Let's assume user is "Authenticated".
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }

  group('E2E Order Flow', () {
    testWidgets('Full User Journey: Search -> Detail -> Cart -> Checkout', (
      WidgetTester tester,
    ) async {
      // --- SET UP MOCKS ---

      // 1. Initial Home Data
      SharedPreferences.setMockInitialValues({});
      when(mockApiService.getCities()).thenAnswer((_) async => []);

      when(
        mockApiService.getCategories(
          language: anyNamed('language'),
          vendorType: anyNamed('vendorType'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.getPopularProducts(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          vendorType: anyNamed('vendorType'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.getVendors(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
          vendorType: anyNamed('vendorType'),
        ),
      ).thenAnswer((_) async => []);
      when(
        mockApiService.getBanners(
          language: anyNamed('language'),
          vendorType: anyNamed('vendorType'),
        ),
      ).thenAnswer((_) async => []);

      // 2. Search "Lahmacun"
      when(mockApiService.autocomplete(any)).thenAnswer(
        (_) async => [
          AutocompleteResultDto(id: '1', name: 'Lahmacun', type: 'product'),
        ],
      );

      final product = Product(
        id: 'p1',
        name: 'Lahmacun',
        description: 'Acılı',
        price: 50.0,
        vendorId: 'v1',
        category: 'Food',
        imageUrl: 'url',
      );

      final productDto = ProductDto(
        id: 'p1',
        name: 'Lahmacun',
        description: 'Acılı',
        price: 50.0,
        vendorId: 'v1',
        category: 'Food',
        imageUrl: 'url',
      );

      when(mockApiService.searchProducts(any)).thenAnswer(
        (_) async => PagedResultDto<ProductDto>(
          items: [productDto],
          totalCount: 1,
          page: 1,
          pageSize: 20,
          totalPages: 1,
        ),
      );

      when(mockApiService.searchVendors(any)).thenAnswer(
        (_) async => PagedResultDto<VendorDto>(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          totalPages: 0,
        ),
      );

      // Product Detail Mocks
      when(mockApiService.getProduct('p1')).thenAnswer((_) async => product);
      when(mockApiService.getProductReviews('p1')).thenAnswer(
        (_) async => ProductReviewsSummary(
          averageRating: 5,
          totalRatings: 1,
          totalComments: 0,
          reviews: [],
        ),
      );
      when(
        mockApiService.getSimilarProducts(
          'p1',
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer((_) async => []); // Correct signature?
      // Wait, api_service.dart line 226: getSimilarProducts(productId, {page, pageSize})
      // But Step 4277 used when(mockApiService.getSimilarProducts('p1')).thenAnswer((_) async => []);
      // If page/pageSize default, 'p1' works.
      when(mockApiService.getSimilarProducts('p1')).thenAnswer((_) async => []);

      when(
        mockApiService.getFavorites(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer(
        (_) async => PagedResultDto<ProductDto>(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          totalPages: 0,
        ),
      );

      // 3. Search Results & Product Detail
      // searchProducts already mocked above.

      // 4. Cart Operations
      // Initial Cart
      when(
        mockApiService.getCart(),
      ).thenAnswer((_) async => {'items': [], 'totalAmount': 0.0});

      // Add to Cart
      when(mockApiService.addToCart(any, any)).thenAnswer((_) async => true);

      // Clear Cart
      when(mockApiService.clearCart()).thenAnswer((_) async {});

      // Addresses
      when(mockApiService.getAddresses()).thenAnswer(
        (_) async => [
          {
            'id': 'addr1',
            'title': 'Ev',
            'fullAddress': 'Atatürk Mah. No:1',
            'city': 'İstanbul',
            'district': 'Ataşehir',
            'isDefault': true,
          },
        ],
      );

      // Create Order
      when(
        mockApiService.createOrder(
          any,
          any,
          deliveryAddressId: anyNamed('deliveryAddressId'),
          paymentMethod: anyNamed('paymentMethod'),
          note: anyNamed('note'),
        ),
      ).thenAnswer(
        (_) async => Order(
          id: 'order1',
          customerOrderId: 'ORD-123',
          status: 'Pending',
          totalAmount: 100.0,
          createdAt: DateTime.now(),
          vendorId: 'v1',
          vendorName: 'Vendor 1',
        ),
      );
      when(mockApiService.getCart()).thenAnswer(
        (_) async => {
          'items': [
            {
              'id': 'ci1',
              'productId': 'p1',
              'productName': 'Lahmacun',
              'productPrice': 50.0,
              'quantity': 1,
              'vendorId': 'v1',
              'vendorName': 'Kebapçı Abi',
              'currency': 1,
            },
          ],
        },
      );

      // 5. Checkout
      when(mockApiService.getProfile()).thenAnswer(
        (_) async => {'fullName': 'Test User', 'email': 'test@test.com'},
      );

      // Addresses
      when(mockApiService.getAddresses()).thenAnswer(
        (_) async => [
          {
            'id': 'addr1',
            'title': 'Ev',
            'address': 'Test Cad. No:1',
            'city': 'İstanbul',
            'district': 'Kadıköy',
          },
        ],
      );

      // Create Order
      when(
        mockApiService.createOrder(
          any,
          any,
          deliveryAddressId: anyNamed('deliveryAddressId'),
          paymentMethod: anyNamed('paymentMethod'),
          note: anyNamed('note'),
        ),
      ).thenAnswer(
        (_) async => Order(
          id: 'order123',
          customerOrderId: 'ORD-123',
          vendorId: 'v1',
          vendorName: 'Kebapçı Abi',
          status: 'Pending',
          totalAmount: 50.0,
          createdAt: DateTime.now(),
        ),
      );

      // --- EXECUTION ---

      await tester.binding.setSurfaceSize(const Size(400, 900)); // Mobile size

      // Start App
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(seconds: 1));

      // 1. Force Navigation to Search to Debug
      final homeFinder = find.byType(HomeScreen);
      expect(
        homeFinder,
        findsOneWidget,
        reason: 'HomeScreen should be present',
      );

      final BuildContext homeContext = tester.element(homeFinder);

      Navigator.of(
        homeContext,
      ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));

      await tester.pump(const Duration(seconds: 2)); // Wait for nav to complete
      await tester.pump();

      // 2. Perform Search
      final searchField = find.byType(TextField);
      expect(
        searchField,
        findsOneWidget,
        reason: 'SearchScreen should be pushed',
      );

      await tester.enterText(searchField, 'Lahmacun');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(seconds: 2)); // Wait for search results

      // Verify results
      expect(find.text('Lahmacun'), findsWidgets);

      // 3. Tap first product
      // Keyboard might obscure it?
      // Close keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Use ProductCard finder
      final productCardFinder = find.byType(ProductCard);
      expect(
        productCardFinder,
        findsWidgets,
        reason: 'ProductCard should be visible',
      );

      final ProductCard cardWidget = tester.widget(productCardFinder.first);
      cardWidget.onTap?.call();

      await tester.pump(const Duration(seconds: 2));

      when(
        mockApiService.getFavorites(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer(
        (_) async => PagedResultDto<ProductDto>(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          totalPages: 0,
        ),
      );

      // 4. Product Detail
      // It seems ProductDetailScreen might be considered "dirty" or "offstage" during test pump?
      // Verify existence first
      expect(
        find.byType(ProductDetailScreen, skipOffstage: false),
        findsOneWidget,
        reason: 'ProductDetailScreen should be present (maybe offstage)',
      );

      // Allow it to settle
      await tester.pump(const Duration(seconds: 2));

      // Check if item is already in cart or needs adding
      final addToCartButton = find.text('Sepete Ekle', skipOffstage: false);
      if (addToCartButton.evaluate().isNotEmpty) {
        await tester.tap(addToCartButton);
        await tester.pumpAndSettle();
      } else {
        // Assume item is already in cart (quantity controls visible)
        expect(find.byIcon(Icons.add), findsOneWidget);
      }

      // 5. Go to Cart
      // Navigate using the top right cart icon in ProductDetailScreen
      // Use Semantics label "Sepet" (from app_tr.arb cart)
      final cartBtn = find.bySemanticsLabel('Sepet');
      await tester.tap(cartBtn);
      await tester.pumpAndSettle();

      // Verify We are on Cart Screen
      expect(
        find.text('Sepetim'),
        findsOneWidget,
        reason: 'Should be on Cart Screen',
      );
      expect(find.text('Lahmacun'), findsOneWidget);

      // 6. Checkout
      final checkoutBtn = find.text('Sipariş Ver');
      if (checkoutBtn.evaluate().isNotEmpty) {
        await tester.tap(checkoutBtn);
      } else {
        final textBtns = find.byType(TextButton);
        if (textBtns.evaluate().isNotEmpty) {
          await tester.tap(textBtns.last);
        }
      }
      await tester.pumpAndSettle();

      // 7. On Checkout Screen
      // Wait for addresses to load if needed
      await tester.pumpAndSettle();

      // Tap 'Siparişi Onayla' (confirmOrder)
      final confirmOrderBtn = find.text('Siparişi Onayla');
      expect(
        confirmOrderBtn,
        findsOneWidget,
        reason: 'Confirm Order button should be visible',
      );

      await tester.ensureVisible(confirmOrderBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmOrderBtn);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify createOrder was called
      verify(
        mockApiService.createOrder(
          any,
          any,
          deliveryAddressId: anyNamed('deliveryAddressId'),
          paymentMethod: anyNamed('paymentMethod'),
          note: anyNamed('note'),
        ),
      ).called(1);

      // 8. Verify Success
      if (find.byType(OrderSuccessScreen).evaluate().isEmpty) {
        debugPrint('DEBUG: Not on OrderSuccessScreen!');
        // Print all visible text to help identify current screen
        debugDumpApp();
      }
      // app_tr.arb: "orderCreatedSuccessfully": "Siparişiniz Başarıyla Oluşturuldu!"
      expect(
        find.textContaining('Siparişiniz Başarıyla Oluşturuldu'),
        findsOneWidget,
      );
    });
  });
}

class FakeConnectivityService implements ConnectivityService {
  @override
  Stream<bool> get connectivityStream => Stream.value(true);

  @override
  bool get isOnline => true;

  @override
  Future<bool> checkConnectivity() async => true;

  @override
  void dispose() {}
}
