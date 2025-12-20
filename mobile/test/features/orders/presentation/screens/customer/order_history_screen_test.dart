import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/orders/presentation/screens/customer/order_history_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'order_history_screen_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late BottomNavProvider bottomNavProvider;
  late NotificationProvider notificationProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    bottomNavProvider = BottomNavProvider();
    notificationProvider = NotificationProvider();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BottomNavProvider>.value(
          value: bottomNavProvider,
        ),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
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
        home: OrderHistoryScreen(apiService: mockApiService),
      ),
    );
  }

  final testOrders = [
    {
      'id': 'o1',
      'customerOrderId': '1001',
      'vendorName': 'Mağaza 1',
      'createdAt': '2023-10-27T10:00:00Z',
      'status': 'Pending',
      'totalAmount': 250.0,
    },
    {
      'id': 'o2',
      'customerOrderId': '1002',
      'vendorName': 'Mağaza 2',
      'createdAt': '2023-10-27T11:00:00Z',
      'status': 'Delivered',
      'totalAmount': 100.0,
    },
  ];

  group('OrderHistoryScreen Widget Tests', () {
    testWidgets('should render loading state initially', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getOrders(vendorType: anyNamed('vendorType')),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should render empty state when no orders found', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getOrders(vendorType: anyNamed('vendorType')),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      expect(find.text('Henüz siparişiniz yok'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });

    testWidgets('should render orders list correctly', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getOrders(vendorType: anyNamed('vendorType')),
      ).thenAnswer((_) async => testOrders);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump();

      expect(find.text('Mağaza 1'), findsOneWidget);
      expect(find.text('Mağaza 2'), findsOneWidget);
      expect(find.textContaining('1001'), findsOneWidget);
      expect(find.textContaining('1002'), findsOneWidget);
      expect(find.text('₺250.00'), findsOneWidget);
      expect(find.text('₺100.00'), findsOneWidget);
    });
  });
}
