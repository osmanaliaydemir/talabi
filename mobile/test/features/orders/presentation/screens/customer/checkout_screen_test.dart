import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/orders/presentation/screens/customer/checkout_screen.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/features/orders/data/models/order.dart';

import 'package:mobile/providers/bottom_nav_provider.dart';

import 'checkout_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<CartProvider>(),
  MockSpec<LoggerService>(),
  MockSpec<BottomNavProvider>(),
])
void main() {
  late MockApiService mockApiService;
  late MockCartProvider mockCartProvider;
  late MockLoggerService mockLoggerService;
  late MockBottomNavProvider mockBottomNavProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockCartProvider = MockCartProvider();
    mockLoggerService = MockLoggerService();
    mockBottomNavProvider = MockBottomNavProvider();

    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);
  });

  final testProduct = Product(
    id: '1',
    vendorId: 'vendor1',
    name: 'Test Product',
    price: 100.0,
    currency: Currency.try_,
    vendorName: 'Test Vendor',
  );

  final testCartItems = {'1': CartItem(product: testProduct, quantity: 1)};

  final testAddresses = [
    {
      'id': 'addr1',
      'title': 'Home',
      'fullAddress': 'Test Address 123',
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
      routes: {
        '/customer/home': (context) => const Scaffold(body: Text('Home Page')),
      },
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: mockCartProvider),
          ChangeNotifierProvider<BottomNavProvider>.value(
            value: mockBottomNavProvider,
          ),
        ],
        child: CheckoutScreen(
          cartItems: testCartItems,
          vendorId: 'vendor1',
          subtotal: 100.0,
          deliveryFee: 10.0,
        ),
      ),
    );
  }

  group('CheckoutScreen Widget Tests', () {
    testWidgets('should render basic UI', (WidgetTester tester) async {
      when(mockApiService.getAddresses()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Sipariş Onayı'), findsAtLeastNWidgets(1));
    });

    testWidgets('should render addresses and summary', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getAddresses(),
      ).thenAnswer((_) async => testAddresses);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Test Address 123'), findsOneWidget);
    });

    testWidgets(
      'should show error when no address selected and confirm pressed',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() async => await tester.binding.setSurfaceSize(null));

        when(mockApiService.getAddresses()).thenAnswer((_) async => []);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        // Button is found by text "Siparişi Onayla"
        final confirmButton = find.textContaining('Siparişi Onayla');
        await tester.tap(confirmButton.first);
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets('should successfully create order and clear cart', (
      WidgetTester tester,
    ) async {
      // Set surface size to ensure bottom navigation bar is visible and tappable
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      when(
        mockApiService.getAddresses(),
      ).thenAnswer((_) async => testAddresses);
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
          customerOrderId: 'C-123',
          vendorId: 'vendor1',
          vendorName: 'Test Vendor',
          totalAmount: 110.0,
          status: 'Pending',
          createdAt: DateTime.now(),
        ),
      );

      when(mockCartProvider.clear()).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find the confirm button
      final confirmButtonFinder = find.byType(ElevatedButton);
      expect(confirmButtonFinder, findsOneWidget);

      // Tap the button
      await tester.tap(confirmButtonFinder);
      await tester.pump(); // Start _createOrder execution

      // Let all async operations complete (API call + navigation)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(); // For navigation

      verify(
        mockApiService.createOrder(
          argThat(equals('vendor1')),
          any,
          deliveryAddressId: argThat(
            equals('addr1'),
            named: 'deliveryAddressId',
          ),
          paymentMethod: argThat(equals('Cash'), named: 'paymentMethod'),
        ),
      ).called(1);

      verify(mockCartProvider.clear()).called(1);
    });
  });
}
