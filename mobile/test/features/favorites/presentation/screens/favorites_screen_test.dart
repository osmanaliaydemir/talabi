import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';

import '../../../orders/presentation/screens/customer/order_detail_screen_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late BottomNavProvider bottomNavProvider;
  late CartProvider cartProvider;
  late NotificationProvider notificationProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    GetIt.instance.registerSingleton<ApiService>(mockApiService);

    bottomNavProvider = BottomNavProvider();
    notificationProvider = NotificationProvider();
    cartProvider = CartProvider(apiService: mockApiService);

    ToastMessage.isTestMode = true;
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
        home: FavoritesScreen(),
      ),
    );
  }

  group('FavoritesScreen Widget Tests', () {
    testWidgets('should render empty state when no favorites found', (
      WidgetTester tester,
    ) async {
      // Mock empty response
      final emptyResult = PagedResultDto<ProductDto>(
        items: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        totalPages: 0,
      );

      when(
        mockApiService.getFavorites(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer((_) async => emptyResult);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Start InitState loadFavorites
      await tester.pump(const Duration(milliseconds: 100)); // Wait for future
      await tester.pump(); // Rebuild

      // Verify empty state text from app_tr.arb
      expect(find.text('Henüz favori ürününüz yok'), findsOneWidget);
    });

    testWidgets('should render favorite items', (WidgetTester tester) async {
      final product1 = ProductDto(
        id: '1',
        vendorId: 'v1',
        name: 'Favori Ürün 1',
        price: 50.0,
        currency: Currency.try_,
        vendorName: 'Test Vendor',
      );

      final result = PagedResultDto<ProductDto>(
        items: [product1],
        totalCount: 1,
        page: 1,
        pageSize: 20,
        totalPages: 1,
      );

      when(
        mockApiService.getFavorites(
          page: anyNamed('page'),
          pageSize: anyNamed('pageSize'),
        ),
      ).thenAnswer((_) async => result);

      // Mock getCart for ProductCard
      when(mockApiService.getCart()).thenAnswer((_) async => {'items': []});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Favori Ürün 1'), findsOneWidget);
    });
  });
}
