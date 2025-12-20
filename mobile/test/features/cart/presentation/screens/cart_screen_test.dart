import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';

import '../../../orders/presentation/screens/customer/order_detail_screen_test.mocks.dart';

@GenerateMocks([]) // We reuse existing mocks
void main() {
  late MockApiService mockApiService;
  late NotificationProvider notificationProvider;
  late BottomNavProvider bottomNavProvider;
  late CartProvider cartProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    // GetIt registration is still good practice even if we inject manually
    GetIt.instance.registerSingleton<ApiService>(mockApiService);

    notificationProvider = NotificationProvider();
    bottomNavProvider = BottomNavProvider();

    // Inject mock api service
    cartProvider = CartProvider(apiService: mockApiService);

    ToastMessage.isTestMode = true;
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
        ChangeNotifierProvider<BottomNavProvider>.value(
          value: bottomNavProvider,
        ),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('tr')],
        locale: Locale('tr'),
        home: CartScreen(),
      ),
    );
  }

  group('CartScreen Widget Tests', () {
    testWidgets('should render empty state when cart is empty', (
      WidgetTester tester,
    ) async {
      // Mock empty cart response
      when(mockApiService.getCart()).thenAnswer((_) async => {'items': []});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Start loadCart
      await tester.pump(const Duration(milliseconds: 100)); // Wait for future
      await tester.pump(); // Rebuild

      // Verify empty state message
      expect(find.text('Sepetiniz boş'), findsOneWidget);
    });

    testWidgets('should render cart items when cart returns data', (
      WidgetTester tester,
    ) async {
      final cartItems = [
        {
          'productId': 'p1',
          'productName': 'Test Ürün',
          'productPrice': 100.0,
          'currencyCode': 'TRY',
          'productImageUrl': 'http://test.com/img.jpg',
          'vendorType': 1,
          'quantity': 2,
          'id': 'item1',
          'vendorId': 'v1',
          'vendorName': 'Test Market',
        },
      ];

      when(
        mockApiService.getCart(),
      ).thenAnswer((_) async => {'items': cartItems});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Test Ürün'), findsOneWidget);
      expect(find.textContaining('Test Market'), findsWidgets);
      // Total price: 100 * 2 = 200 . Expected "₺200,00" or similar depending on currency
      // Just check for 200 appearing somewhere
      expect(find.textContaining('200'), findsWidgets);
    });
  });
}
