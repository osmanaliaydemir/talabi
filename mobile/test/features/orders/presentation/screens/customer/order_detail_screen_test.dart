import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/orders/presentation/screens/customer/order_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mobile/features/orders/presentation/providers/order_detail_provider.dart';

import 'order_detail_screen_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late NotificationProvider notificationProvider;
  late BottomNavProvider bottomNavProvider;
  late CartProvider cartProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    notificationProvider = NotificationProvider();
    bottomNavProvider = BottomNavProvider();
    cartProvider = CartProvider(apiService: mockApiService);
    ToastMessage.isTestMode = true; // Disable timers
  });

  Widget createWidgetUnderTest(String orderId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
        ChangeNotifierProvider<BottomNavProvider>.value(
          value: bottomNavProvider,
        ),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ChangeNotifierProvider<OrderDetailProvider>(
          create: (_) => OrderDetailProvider(apiService: mockApiService),
        ),
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
        home: OrderDetailScreen(orderId: orderId),
      ),
    );
  }

  // Corrected mock data with missing fields
  final testOrderDetail = {
    'id': 'order1',
    'customerOrderId': '1001',
    'vendorId': 'v1',
    'vendorName': 'Test Satıcı',
    'customerId': 'c1', // Added
    'customerName': 'Test Customer', // Added
    'status': 'Pending',
    'totalAmount': 250.0,
    'createdAt': DateTime.now().toIso8601String(),
    'items': [
      {
        'productId': 'p1',
        'productName': 'Test Ürün 1',
        'quantity': 2,
        'unitPrice': 100.0,
        'totalPrice': 200.0,
        'customerOrderItemId': 'item1',
        'isCancelled': false,
      },
    ],
    'statusHistory': [],
  };

  group('OrderDetailScreen Widget Tests', () {
    testWidgets('should render loading state initially', (
      WidgetTester tester,
    ) async {
      when(mockApiService.getOrderDetailFull(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return testOrderDetail;
      });

      await tester.pumpWidget(createWidgetUnderTest('order1'));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump properly to finish
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
    });

    testWidgets('should render order details correctly', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getOrderDetailFull(any),
      ).thenAnswer((_) async => testOrderDetail);

      await tester.pumpWidget(createWidgetUnderTest('order1'));
      await tester.pump();
      await tester.pump(); // Render content

      expect(find.text('Test Satıcı'), findsAtLeastNWidgets(1));
      expect(find.text('Test Ürün 1'), findsOneWidget);
    });

    testWidgets('should show status badge', (WidgetTester tester) async {
      when(
        mockApiService.getOrderDetailFull(any),
      ).thenAnswer((_) async => testOrderDetail);

      await tester.pumpWidget(createWidgetUnderTest('order1'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Bekleyen'), findsOneWidget);
    });
  });
}
